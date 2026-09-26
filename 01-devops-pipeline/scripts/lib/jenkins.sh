#!/usr/bin/env bash
# Helpers for driving the Podman VM and the local Jenkins from one-touch.sh.
# Source it (`source "$here/lib/jenkins.sh"`); do not run it.
#
# Needs from the caller (set before any function here is CALLED, not before sourcing):
#   machine  port  job_name  vm_pipeline  vm_state  JENKINS_ADMIN_USER  JENKINS_ADMIN_PASSWORD
# and lib/ui.sh already sourced (run_vm, render_notes, step_failed, curlj, fail).
#
#   vm / jenv / vm_send_state   run things in the VM (fatal on failure, results rendered)
#   jenkins_api                 authenticated GET against the local Jenkins
#   wait_for + *_ok checks      poll until something is ready, with container logs on timeout

# vm <what> <command> [<<< stdin]: run <command> in the VM. Fatal on failure; VM-side results are rendered.
vm() {
    local mark rc=0
    mark=$(log_mark)
    run_vm "$2" || rc=$?
    (( rc == 0 )) || step_failed "$1" "$rc"
    render_notes "$mark"
}

# jenv <action> [<env assignment>]: run one action of jenkins-env.sh in the VM.
jenv() { vm "$1" "${2:-} bash $vm_pipeline/scripts/jenkins-env.sh $1"; }

# vm_send_state <what> <content>: hand secrets to the VM through stdin (never as a command argument).
vm_send_state() {
    vm "$1" "umask 077; mkdir -p \"$vm_state\"; cat > \"$vm_state/onetouch-secrets.env\"; chmod 600 \"$vm_state/onetouch-secrets.env\"" <<< "$2"
}

# jenkins_api <path>: authenticated GET against the local Jenkins.
jenkins_api() { curlj -sf -u "${JENKINS_ADMIN_USER}:${JENKINS_ADMIN_PASSWORD}" "http://127.0.0.1:${port}/$1"; }

# Show what a container last said — used when something it runs never becomes ready.
container_diag() {
    local mark
    mark=$(log_mark)
    {
        printf '
--- state and last logs of %s ---
' "$1"
        # ngrok echoes the (rejected) authtoken in its errors; never let it reach the screen or the log.
        MSYS_NO_PATHCONV=1 podman machine ssh "$machine" -- "podman ps -a --filter name=$1 --format '{{.Names}} {{.Status}}'; podman logs --tail 30 $1" 2>&1             | sed -E 's/([Aa]uthtoken: *)[^ ]+/\1****/'
    } >> "$log_file" || true
    printf '
  Last lines from %s:
' "$1" >&2
    log_since "$mark" | tail -n 15 | sed 's/^/    | /' >&2
}

# container_exited <name>: true if the container has stopped (crashed or exited), so waiting is pointless.
container_exited() {
    local state
    state=$(MSYS_NO_PATHCONV=1 podman machine ssh "$machine" -- "podman inspect --format '{{.State.Status}}' $1" 2> /dev/null | tr -d '\r') || return 1
    [[ $state == exited || $state == stopped ]]
}

# wait_for <description> <max tries> <check function> [<container to watch>]  (2 s per try)
# With a container name: fails at once if that container stops, and shows its logs on failure.
wait_for() {
    local desc=$1 tries=$2 check=$3 container=${4:-}
    local n=0
    until "$check"; do
        if [[ -n $container ]] && container_exited "$container"; then
            container_diag "$container"
            fail "$container stopped while waiting for: $desc"
        fi
        n=$((n + 1))
        if (( n >= tries )); then
            [[ -z $container ]] || container_diag "$container"
            fail "Timed out after $((tries * 2))s waiting for: $desc"
        fi
        sleep 2
    done
}

controller_http_ok() { curlj -sf -o /dev/null "http://127.0.0.1:${port}/login"; }
admin_login_ok() { jenkins_api whoAmI/api/json > /dev/null; }
job_exists() { jenkins_api "job/${job_name}/api/json" > /dev/null; }
tunnel_ok() { curlj -sf -o /dev/null "http://127.0.0.1:4041/api/tunnels"; }
worker_online() {
    local json
    json=$(jenkins_api computer/vdx-worker/api/json 2> /dev/null) || return 1
    [[ $json == *'"offline":false'* ]]
}
