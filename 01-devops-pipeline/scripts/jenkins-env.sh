#!/usr/bin/env bash
# Bootstraps the containerized Jenkins controller/worker environment inside the
# Podman machine's Linux VM (not Windows Git Bash). Driven by scripts/one-touch.sh;
# see ../README.md for the full flow.
set -euo pipefail

pipeline_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
state_dir="$HOME/vdx-jenkins-pipeline-state"
owner=vdx-local-jenkins
worker_image=localhost/vdx-jenkins-worker:local
controller_image_tag=localhost/vdx-jenkins-controller:local
action=${1:-help}

# Print "ERROR: ..." and exit 1.
fail() {
    printf 'ERROR: %s\n' "$*" >&2
    exit 1
}

# Result lines ("@@ OK|WARN|INFO <text>") that scripts/one-touch.sh renders as status lines.
note() { printf '@@ %s\n' "$*"; }

# Checks we are in the Linux VM as a non-root user with rootless Podman; creates the private state dir.
preflight() {
    [[ $(uname -s) == Linux ]] || fail 'Run inside the Podman Linux VM, not Windows Git Bash.'
    [[ $(id -u) != 0 ]] || fail 'Use the rootless Podman machine user, not root.'
    command -v podman >/dev/null || fail 'Podman is missing from this VM.'
    [[ $(podman info --format '{{.Host.Security.Rootless}}') == true ]] || fail 'A rootless engine is required.'
    [[ $pipeline_dir != /mnt/* ]] || fail 'Copy this pipeline folder to the VM native filesystem before running it.'
    # Scoped to state_dir only — a global umask 077 would make files later
    # copied into the controller build context unreadable by the image's
    # non-root jenkins user, breaking jenkins-plugin-cli.
    ( umask 077 && mkdir -p "$state_dir" && chmod 700 "$state_dir" )
}

# Loads the saved image digests from images.env and checks the Podman version has not changed.
load_config() {
    [[ -f "$state_dir/images.env" ]] || fail 'Run prepare first.'
    source "$state_dir/images.env"
    [[ $(podman version --format '{{.Client.Version}}') == "$ENGINE_VERSION" ]] || fail 'Engine version changed. Rerun prepare.'
}

# Fails unless the container has our vdx.owner label, so we never touch someone else's.
check_container_owner() {
    [[ $(podman inspect --format '{{index .Config.Labels "vdx.owner"}}' "$1") == "$owner" ]] || fail "Container $1 is not owned by this One Touch setup. It was not modified."
}

# Creates the vdx-ci network if missing, or checks the existing one is ours.
ensure_network() {
    if podman network exists vdx-ci; then
        [[ $(podman network inspect --format '{{index .Labels "vdx.owner"}}' vdx-ci) == "$owner" ]] || fail 'Network vdx-ci already exists without our ownership label.'
    else
        podman network create --label "vdx.owner=$owner" vdx-ci
    fi
}

# Creates a named volume if missing, or checks the existing one is ours.
ensure_volume() {
    if podman volume exists "$1"; then
        [[ $(podman volume inspect --format '{{index .Labels "vdx.owner"}}' "$1") == "$owner" ]] || fail "Volume $1 already exists without our ownership label."
    else
        podman volume create --label "vdx.owner=$owner" "$1"
    fi
}

# Enables the rootless Podman socket and checks this user owns it.
socket_setup() {
    systemctl --user is-active --quiet podman.socket || systemctl --user enable --now podman.socket
    socket_path=$(podman info --format '{{.Host.RemoteSocket.Path}}')
    [[ -S "$socket_path" && -O "$socket_path" ]] || fail 'The current user must own a live Podman Unix socket.'
}

# Action: pins the 4 base images, verifies the Podman client, builds worker + controller images, creates network and volumes.
prepare() {
    command -v curl >/dev/null || fail 'curl is required in the Podman VM to download the public client archive.'
    if [[ ! -f "$state_dir/images.env" ]]; then
        JENKINS_PORT=${JENKINS_PORT:-8081}
        [[ $JENKINS_PORT =~ ^[0-9]+$ ]] || fail 'JENKINS_PORT must be numeric.'
        (( JENKINS_PORT >= 1024 && JENKINS_PORT <= 65535 )) || fail 'Use a port from 1024 to 65535.'
        ENGINE_VERSION=$(podman version --format '{{.Client.Version}}')
        [[ $ENGINE_VERSION =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || fail 'This pipeline expects a stable Podman release version.'
        podman pull docker.io/jenkins/jenkins:lts-jdk21
        podman pull docker.io/jenkins/inbound-agent:jdk21
        podman pull docker.io/library/maven:3.9.9-eclipse-temurin-17
        podman pull docker.io/library/debian:13-slim
        CONTROLLER_IMAGE=$(podman image inspect docker.io/jenkins/jenkins:lts-jdk21 --format '{{index .RepoDigests 0}}')
        AGENT_IMAGE=$(podman image inspect docker.io/jenkins/inbound-agent:jdk21 --format '{{index .RepoDigests 0}}')
        MAVEN_IMAGE=$(podman image inspect docker.io/library/maven:3.9.9-eclipse-temurin-17 --format '{{index .RepoDigests 0}}')
        DEBIAN_IMAGE=$(podman image inspect docker.io/library/debian:13-slim --format '{{index .RepoDigests 0}}')
        for image in "$CONTROLLER_IMAGE" "$AGENT_IMAGE" "$MAVEN_IMAGE" "$DEBIAN_IMAGE"; do
            [[ $image == *@sha256:* ]] || fail "No digest was resolved for $image"
        done
        printf 'ENGINE_VERSION=%q\nCONTROLLER_IMAGE=%q\nAGENT_IMAGE=%q\nMAVEN_IMAGE=%q\nDEBIAN_IMAGE=%q\nJENKINS_PORT=%q\n' \
            "$ENGINE_VERSION" "$CONTROLLER_IMAGE" "$AGENT_IMAGE" "$MAVEN_IMAGE" "$DEBIAN_IMAGE" "$JENKINS_PORT" \
            > "$state_dir/images.env"
        note 'OK Pulled 4 base images (pinned by digest)'
        note 'INFO jenkins/jenkins:lts-jdk21'
        note 'INFO jenkins/inbound-agent:jdk21'
        note 'INFO maven:3.9.9-eclipse-temurin-17'
        note 'INFO debian:13-slim'
    else
        note 'OK Reusing the 4 pinned base images from the previous prepare'
    fi
    load_config
    case $(uname -m) in
        x86_64) client_arch=amd64 ;;
        aarch64) client_arch=arm64 ;;
        *) fail 'Only x86_64 and aarch64 machines are supported by this pipeline.' ;;
    esac

    worker_context="$state_dir/worker-context"
    mkdir -p "$worker_context"
    cp "$pipeline_dir/docker/jenkins/Dockerfile.worker" "$worker_context/Dockerfile"
    if [[ ! -f "$worker_context/podman-remote.tar.gz" ]]; then
        curl --fail --location --retry 3 \
            "https://github.com/containers/podman/releases/download/v${ENGINE_VERSION}/podman-remote-static-linux_${client_arch}.tar.gz" \
            --output "$worker_context/podman-remote.tar.gz.part"
        mv "$worker_context/podman-remote.tar.gz.part" "$worker_context/podman-remote.tar.gz"
    fi
    curl --fail --location --retry 3 \
        "https://github.com/containers/podman/releases/download/v${ENGINE_VERSION}/shasums" \
        --output "$state_dir/client-release-shasums"
    archive_name="podman-remote-static-linux_${client_arch}.tar.gz"
    expected_sha=$(awk -v name="$archive_name" '$2 == name || $2 == "*" name {print $1}' "$state_dir/client-release-shasums")
    [[ $expected_sha =~ ^[a-fA-F0-9]{64}$ ]] || fail 'No unique SHA256 checksum found for the client archive.'
    printf '%s  %s\n' "$expected_sha" "$worker_context/podman-remote.tar.gz" | sha256sum --check -
    note "OK Podman client $ENGINE_VERSION checksum verified (SHA-256)"
    podman build --build-arg "AGENT_IMAGE=$AGENT_IMAGE" -t "$worker_image" "$worker_context"
    note "OK Built $worker_image"
    podman run --rm --entrypoint sh "$worker_image" -ec \
        'test "$(id -u)" = 1000; test "$(id -g)" = 1000; git --version; java -version; curl --version; jq --version; podman --version'
    note 'OK Worker toolchain check (git, java, curl, jq, podman)'

    controller_context="$state_dir/controller-context"
    # Recreated from scratch every run: `cp` onto an existing file keeps that
    # file's old permissions (a leftover 600 from a prior umask-077 run would
    # otherwise persist and make plugins.txt unreadable to the image's jenkins user).
    rm -rf "$controller_context"
    mkdir -p "$controller_context/casc"
    cp "$pipeline_dir/docker/controller/Dockerfile" "$controller_context/Dockerfile"
    cp "$pipeline_dir/docker/controller/plugins.txt" "$controller_context/plugins.txt"
    cp "$pipeline_dir/docker/controller/casc/jenkins.yaml" "$controller_context/casc/jenkins.yaml"
    chmod 644 "$controller_context/Dockerfile" "$controller_context/plugins.txt" "$controller_context/casc/jenkins.yaml"
    podman build --build-arg "CONTROLLER_IMAGE=$CONTROLLER_IMAGE" -t "$controller_image_tag" "$controller_context"
    note "OK Built $controller_image_tag"

    ensure_network
    ensure_volume vdx-jenkins-home
    ensure_volume vdx-workspace
    ensure_volume vdx-maven-cache
    podman run --rm --userns=keep-id:uid=1000,gid=1000 --user 0:0 \
        --security-opt label=disable \
        -v vdx-workspace:/workspace -v vdx-maven-cache:/maven-cache \
        --entrypoint sh "$worker_image" -ec \
        'chown 1000:1000 /workspace /maven-cache'
    note 'OK Network vdx-ci'
    note 'OK Volumes vdx-jenkins-home  vdx-workspace  vdx-maven-cache'
    socket_setup
    printf '\nPrepared. Next: bash jenkins-env.sh controller\n'
}

# Action: starts (or recreates, if config changed) vdx-jenkins with the secrets and JCasC config.
controller() {
    load_config
    ensure_network
    ensure_volume vdx-jenkins-home
    # A previously-created container is bound to the image it was created from;
    # rebuilding the controller image (e.g. jenkins.yaml changed) needs a recreate
    # to pick it up, not just `podman start`.
    if podman container exists vdx-jenkins; then
        check_container_owner vdx-jenkins
        recreate=0
        if podman image exists "$controller_image_tag"; then
            running_image=$(podman inspect --format '{{.Image}}' vdx-jenkins)
            current_image=$(podman image inspect --format '{{.Id}}' "$controller_image_tag")
            if [[ $running_image != "$current_image" ]]; then
                recreate=1
            fi
        fi
        # one-touch.sh supplies a fresh env file when .env changes; recreate
        # so JCasC receives the new branch, credentials and job settings.
        [[ -s "$state_dir/onetouch-secrets.env" ]] && recreate=1
        if (( recreate )); then
            printf 'Controller configuration changed — recreating it (vdx-jenkins-home volume is kept).\n'
            note 'INFO Controller configuration changed: recreating vdx-jenkins (vdx-jenkins-home volume is kept)'
            podman rm -f vdx-jenkins
        fi
    fi
    if podman container exists vdx-jenkins; then
        podman start vdx-jenkins
    else
        [[ -s "$state_dir/onetouch-secrets.env" ]] || fail 'Missing onetouch-secrets.env — run scripts/one-touch.sh, which pipes the required credentials in before calling this.'
        podman run -d --name vdx-jenkins --label "vdx.owner=$owner" \
            --network vdx-ci -p "127.0.0.1:${JENKINS_PORT}:8080" \
            --env-file "$state_dir/onetouch-secrets.env" \
            -v vdx-jenkins-home:/var/jenkins_home \
            -v "$pipeline_dir/docker/jenkins/init.groovy.d/vdx-worker-node.groovy:/var/jenkins_home/init.groovy.d/vdx-worker-node.groovy:ro" \
            "$controller_image_tag"
    fi
    rm -f "$state_dir/onetouch-secrets.env"
    note "OK Container vdx-jenkins started on :${JENKINS_PORT} (JCasC applied, setup wizard skipped)"
    printf '\nvdx-jenkins starting on port %s. JCasC applies automatically — no wizard, no manual clicks.\n' "$JENKINS_PORT"
}

# Action: waits for the controller's node secret, then starts vdx-worker with the socket and shared volumes.
agent() {
    load_config
    socket_setup
    if podman container exists vdx-worker; then
        check_container_owner vdx-worker
        podman start vdx-worker
        note 'OK Container vdx-worker started (existing container)'
        return
    fi
    if [[ ! -s "$state_dir/agent-secret" ]]; then
        check_container_owner vdx-jenkins
        # The controller's init script writes the secret; it may land a few seconds after the job exists.
        agent_secret=''
        for _ in $(seq 1 30); do
            agent_secret=$(podman exec vdx-jenkins cat /var/jenkins_home/vdx-worker-secret 2>/dev/null || true)
            [[ $agent_secret =~ ^[a-fA-F0-9]{64}$ ]] && break
            sleep 2
        done
        [[ $agent_secret =~ ^[a-fA-F0-9]{64}$ ]] || fail 'Could not read the auto-provisioned vdx-worker secret from vdx-jenkins after 60s — check the vdx-jenkins logs (init.groovy.d/vdx-worker-node.groovy).'
        printf '%s' "$agent_secret" > "$state_dir/agent-secret"
        unset agent_secret
        chmod 600 "$state_dir/agent-secret"
    fi
    podman run -d --name vdx-worker --label "vdx.owner=$owner" \
        --network vdx-ci --userns=keep-id:uid=1000,gid=1000 --user 1000:1000 \
        --security-opt label=disable \
        -e CONTAINER_HOST=unix:///run/podman/podman.sock \
        -e "MAVEN_IMAGE=$MAVEN_IMAGE" -e "DEBIAN_IMAGE=$DEBIAN_IMAGE" \
        -e "ENGINE_VERSION=$ENGINE_VERSION" \
        -v "$socket_path:/run/podman/podman.sock" \
        -v "$state_dir/agent-secret:/run/secrets/jenkins-agent:ro" \
        -v vdx-workspace:/workspace -v vdx-maven-cache:/maven-cache \
        "$worker_image" \
        -url http://vdx-jenkins:8080/ -name vdx-worker \
        -secret @/run/secrets/jenkins-agent -webSocket -workDir /workspace/agent
    note 'OK Container vdx-worker started'
    printf '\nvdx-worker starting. Next: bash jenkins-env.sh probe\n'
}

# Action: runs a tiny fake build (worker + sibling Maven) to prove engine access and shared volumes work.
probe() {
    load_config
    check_container_owner vdx-worker
    podman exec vdx-worker sh -ec '
        test "$(id -u)" = 1000
        podman --remote version
        test "$(podman --remote version --format "{{.Client.Version}}")" = "$ENGINE_VERSION"
        test "$(podman --remote version --format "{{.Server.Version}}")" = "$ENGINE_VERSION"
        test "$(podman --remote info --format "{{.Host.Security.Rootless}}")" = true
        mkdir -p /workspace/probe /maven-cache/home
        printf "worker\n" > /workspace/probe/worker.txt
        podman --remote run --rm --name vdx-storage-probe \
            --userns=keep-id:uid=1000,gid=1000 --user 1000:1000 \
            --security-opt label=disable \
            -e MAVEN_CONFIG=/maven-cache/home -e HOME=/maven-cache/home \
            -v vdx-workspace:/workspace -v vdx-maven-cache:/maven-cache \
            --entrypoint sh "$MAVEN_IMAGE" -ec '\''
                test "$(cat /workspace/probe/worker.txt)" = worker
                printf "maven\n" > /workspace/probe/maven.txt
                printf "cache\n" > /maven-cache/probe.txt
                mvn --version
            '\''
        test "$(cat /workspace/probe/maven.txt)" = maven
        printf "worker-again\n" >> /workspace/probe/maven.txt
        printf "worker-cache\n" >> /maven-cache/probe.txt
        rm -f /workspace/probe/worker.txt /workspace/probe/maven.txt /maven-cache/probe.txt
    '
    note 'OK Podman engine: client and server versions match'
    note 'OK Rootless socket reachable from the worker'
    note 'OK Sibling Maven container'
    note 'OK Shared workspace and Maven cache ownership'
    printf '\nPASS: client/server versions, rootless socket, sibling Maven, shared workspace/cache ownership.\n'
}

# Action: (re)creates vdx-ngrok, forwarding the public URL to vdx-jenkins:8080.
tunnel_up() {
    load_config
    check_container_owner vdx-jenkins
    [[ -s "$state_dir/onetouch-secrets.env" ]] || fail 'Missing onetouch-secrets.env — run scripts/one-touch.sh, which pipes NGROK_AUTHTOKEN/NGROK_DOMAIN in before calling this.'
    source "$state_dir/onetouch-secrets.env"
    [[ -n "${NGROK_AUTHTOKEN:-}" && -n "${NGROK_DOMAIN:-}" ]] || fail 'NGROK_AUTHTOKEN/NGROK_DOMAIN missing from onetouch-secrets.env.'
    # The token and domain are baked into the container when it is created, so an existing one
    # must be recreated or a changed NGROK_AUTHTOKEN/NGROK_DOMAIN would be silently ignored.
    # (Safe: the container holds no state, and the secrets file is always supplied fresh.)
    if podman container exists vdx-ngrok; then
        check_container_owner vdx-ngrok
        podman rm -f vdx-ngrok
    fi
    podman run -d --name vdx-ngrok --label "vdx.owner=$owner" \
        --network vdx-ci -p 127.0.0.1:4041:4040 \
        -e "NGROK_AUTHTOKEN=$NGROK_AUTHTOKEN" \
        ngrok/ngrok http --url="https://${NGROK_DOMAIN}" vdx-jenkins:8080
    rm -f "$state_dir/onetouch-secrets.env"
    note 'OK Container vdx-ngrok started'
    printf '\nvdx-ngrok starting, tunneling https://%s -> vdx-jenkins:8080. Inspect at http://localhost:4041.\n' "$NGROK_DOMAIN"
}

# Action: removes the vdx-ngrok container.
tunnel_down() {
    if podman container exists vdx-ngrok; then
        check_container_owner vdx-ngrok
        podman rm -f vdx-ngrok
    fi
}

# Action: stops the three containers without deleting them.
stop() {
    for container in vdx-ngrok vdx-worker vdx-jenkins; do
        if podman container exists "$container"; then
            check_container_owner "$container"
            podman stop "$container"
        fi
    done
}

# Action: deletes containers, volumes, network and the state dir.
reset() {
    local removed
    removed=''
    for container in vdx-ngrok vdx-worker vdx-jenkins; do
        if podman container exists "$container"; then
            check_container_owner "$container"
            podman rm -f "$container"
            removed+=" $container"
        fi
    done
    note "OK Containers: ${removed:-none to remove}"
    removed=''
    for volume in vdx-jenkins-home vdx-workspace vdx-maven-cache; do
        if podman volume exists "$volume"; then
            podman volume rm "$volume"
            removed+=" $volume"
        fi
    done
    note "OK Volumes: ${removed:-none to remove}"
    if podman network exists vdx-ci; then
        podman network rm vdx-ci
        note 'OK Network vdx-ci removed'
    else
        note 'OK Network vdx-ci: none to remove'
    fi
    rm -rf "$state_dir"
    printf '\nOne Touch resources removed.\n'
}

case "$action" in
    prepare|controller|agent|probe|stop|reset|tunnel-up|tunnel-down)
        preflight
        case "$action" in
            prepare) prepare ;;
            controller) controller ;;
            agent) agent ;;
            probe) probe ;;
            stop) stop ;;
            reset) reset ;;
            tunnel-up) tunnel_up ;;
            tunnel-down) tunnel_down ;;
        esac
        ;;
    help|--help|-h)
        printf 'Run inside the rootless Podman VM: bash jenkins-env.sh {prepare|controller|agent|probe|stop|reset|tunnel-up|tunnel-down}\n'
        ;;
    *) fail "Unknown action: $action" ;;
esac
