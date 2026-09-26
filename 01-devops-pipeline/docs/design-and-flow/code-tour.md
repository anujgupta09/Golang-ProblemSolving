# Code Tour

Start here to understand the code quickly. Diagrams: [pipeline-flow.md](pipeline-flow.md), [networking-overview.md](networking-overview.md). Files under `docs/pre-req/` are one-time account and tool setup and are only referenced here.

## The system in ten lines

1. **Setup** (`scripts/one-touch.sh`, Windows Git Bash) copies this folder into the Podman VM and drives `scripts/jenkins-env.sh` there.
2. Inside the VM, three containers run on one network, `vdx-ci`: **`vdx-jenkins`** (controller, 0 executors), **`vdx-worker`** (the only build agent) and **`vdx-ngrok`** (public tunnel, demo windows only).
3. The controller configures itself from `docker/controller/casc/jenkins.yaml` (JCasC): admin user, three credentials, and the `vdx-release` job, which reads the `Jenkinsfile` from Git.
4. The worker has no Maven or build toolchain (only git, curl, jq and the agent). It has a Podman **remote client** and the host's rootless Podman socket, so it starts **sibling containers** (Maven, image build, smoke test) on the host engine.
5. Maven and the workspace share two named volumes, `vdx-workspace` and `vdx-maven-cache`, so files written by the worker are visible in sibling containers.
6. A `release-X.Y.Z` tag on `java-maven-sample-app` fires a GitHub webhook to ngrok, then Jenkins. The webhook only wakes the job.
7. The `Jenkinsfile` finds the highest `release-*` tag itself, skips it if the image already exists on Docker Hub, and checks the tagged commit is on `main` and matches the POM version.
8. It runs `mvn clean verify`, builds a Debian 13 image, smoke-tests it, then pushes it to Docker Hub as `release-X.Y.Z`.
9. The four base images are pinned by digest and the Podman client is checksum-verified; each run cleans up its own containers.
10. `scripts/one-touch-destroy.sh` removes all of it, including the webhook.

## One release, traced

| # | What happens | Where |
| --- | --- | --- |
| 1 | You bump `<version>` in `pom.xml`, push `main`, push tag `release-X.Y.Z` (`scripts/version-bump.sh` does this) | app repo |
| 2 | GitHub sends a `create` event to `https://<ngrok-domain>/generic-webhook-trigger/invoke?token=...` | webhook created by `one-touch.sh` stage 8 |
| 3 | ngrok forwards it to `vdx-jenkins:8080` over `vdx-ci` | `jenkins-env.sh tunnel-up` |
| 4 | Generic Webhook Trigger checks the token and that `ref_type` is `tag`, then starts the job | `Jenkinsfile` `triggers` |
| 5 | Job runs on the node labelled `vdx-podman` (`vdx-worker`) | `Jenkinsfile` `agent`; node made by `vdx-worker-node.groovy` |
| 6 | Load Release Config reads registry names and credential IDs | `config/release.properties` |
| 7 | Discover Release Tag: `git ls-remote` for `release-*`, highest semver wins; skip if already on Docker Hub | `Jenkinsfile` |
| 8 | Checkout Exact Tag: clone at the tag, also fetching `main` | `Jenkinsfile` |
| 9 | Validate: tagged SHA is an ancestor of `origin/main`; POM version (via `mvn help:evaluate`) equals the tag | `Jenkinsfile` |
| 10 | Compile and Test: `mvn clean verify` in a sibling Maven container; JUnit results published | `Jenkinsfile` |
| 11 | Build Debian Image: copy the jar, build from `docker/app/Dockerfile` with the pinned base | `Jenkinsfile`, `docker/app/Dockerfile` |
| 12 | Smoke Test: run the image on `vdx-ci`; check Debian 13, non-root, `/greeting` returns `Hello, World!` | `Jenkinsfile` |
| 13 | Publish: `--password-stdin` login, push, logout on exit | `Jenkinsfile` |
| 14 | Post: description set, artifacts archived, per-run containers removed, workspace deleted | `Jenkinsfile` `post` |

## Reading order

1. `README.md`: what it is, `.env` values, quick start.
2. `scripts/one-touch.sh`: read `main` at the bottom, then each `stage_N` function. It is the setup story in eight steps.
3. `scripts/jenkins-env.sh`: the VM-side actions (`prepare`, `controller`, `agent`, `probe`, `tunnel-up`, and so on).
4. `docker/controller/casc/jenkins.yaml` and `docker/jenkins/init.groovy.d/vdx-worker-node.groovy`: how Jenkins configures itself with no clicks.
5. `Jenkinsfile`: the release pipeline, top to bottom.
6. `docker/jenkins/Dockerfile.worker` and `docker/app/Dockerfile`: the two images that matter.
7. `scripts/lib/*.sh` and `scripts/one-touch-destroy.sh`: plumbing and teardown; skim.

## Ideas that repeat everywhere

- **Idempotent:** every setup step can be rerun. Resources carry the label `vdx.owner=vdx-local-jenkins`; the scripts refuse to touch same-named things without it.
- **Siblings, not nested:** the worker asks the host engine to start containers next to it. No Docker-in-Docker.
- **Trust git and the registry, not the webhook:** the payload is never used for the version, tag or SHA.
- **Secrets never in git:** they live in an env file, are sent over SSH stdin, and end up only as Jenkins credentials.
- **Pinned:** the four base images (by digest) and the Podman client (checksum-verified) are fixed at `prepare`. The `ngrok/ngrok` image is not pinned.


## File reference

Two phases: **setup** (once, or after a reset) and **release** (every release, unattended).

### `scripts/one-touch.sh` (Windows Git Bash)
Reads `.env`, copies the folder into the Podman VM, drives `jenkins-env.sh`, triggers the first build, then creates the webhook and starts the tunnel. Steps and `.env` values: [README](../../README.md). Undo: `scripts/one-touch-destroy.sh`. Plumbing: `scripts/lib/` (`ui.sh` console and log, `jenkins.sh` VM and Jenkins helpers, `report.sh` header and summary).

### `scripts/jenkins-env.sh` (inside the VM; every action idempotent)

| Action | Does |
| --- | --- |
| `prepare` | Pin 4 images by digest; download and checksum-verify the Podman remote client; build worker and controller images; create `vdx-ci` and 3 volumes; enable the rootless socket |
| `controller` | Start `vdx-jenkins` with the secrets from `.env`; mount `vdx-worker-node.groovy` |
| `agent` | Read the node secret from the controller; start `vdx-worker` with the socket and shared volumes |
| `probe` | Self-test: remote engine works, sibling Maven shares the volumes |
| `tunnel-up` / `tunnel-down` | Start / stop `vdx-ngrok` |
| `stop` / `reset` | Stop containers / remove everything |

### What it builds and calls
- **`docker/controller/`**: `plugins.txt` (baked in with `jenkins-plugin-cli`) and `casc/jenkins.yaml` (JCasC: admin user, security, 3 credentials, the `vdx-release` job), so there is no setup wizard.
- **`docker/jenkins/Dockerfile.worker`**: the inbound-agent image plus `git`, `curl`, `jq` and the Podman **remote client** (no second engine); `podman --remote` starts sibling containers on the host engine.
- **`docker/jenkins/init.groovy.d/vdx-worker-node.groovy`**: runs as SYSTEM on every controller boot; creates the `vdx-worker` node if missing and writes its secret into the data volume for `jenkins-env.sh agent`.
- **`docker/app/Dockerfile`**: Debian 13 slim, headless JRE, non-root `appuser`, one release jar as `ENTRYPOINT`. No Maven or JDK.
- **`config/release.properties`**: non-secret settings read at the start of each run: app repo URL, 2 credential IDs (app checkout, registry), registry namespace, repo and image, ancestry branch.
- **`docs/pre-req/`**: Podman and WSL, Docker Hub token, GitHub tokens, ngrok.

### `Jenkinsfile`
Trigger: `GenericTrigger`, token `vdx-release-trigger`; runs on the `vdx-podman` worker.

| # | Stage | Does |
| --- | --- | --- |
| 1 | Load Release Config | Read `config/release.properties`; fail fast on a missing file or blank key |
| 2 | Discover Release Tag | `git ls-remote` (token via `GIT_ASKPASS`) for the highest `release-*`; `NOT_BUILT` if none or already on Docker Hub |
| 3 | Checkout Exact Tag | Tagged commit and `main` tip in one clone |
| 4 | Validate Ancestry and Version | Tag reachable from `origin/main`; `X.Y.Z` equals the effective POM version (sibling Maven) |
| 5 | Compile and Test | `mvn clean verify` in a sibling Maven container; JUnit results |
| 6 | Build Debian Image | Jar into `docker/app/Dockerfile` with the pinned base |
| 7 | Smoke Test | Run on `vdx-ci`; check OS, non-root, `/greeting` by container name |
| 8 | Publish to Registry | Login with `--password-stdin`, push, `EXIT` trap logout |
| post | Cleanup | Set description and result, archive, force-remove this run's containers |

## How do I change...?

| Change | Touch | Then |
| --- | --- | --- |
| Registry, image name, credential IDs | `config/release.properties` (and the matching `*_CRED_ID` values in `.env`) | Rerun `one-touch.sh` only if a credential ID changed |
| Add or change a pipeline stage | `Jenkinsfile` | Full cycle: setup, tag, verify |
| Add a Jenkins plugin | `docker/controller/plugins.txt` | Rerun `one-touch.sh` (rebuilds the controller image; data volume kept) |
| Change admin user, credentials or job definition | `docker/controller/casc/jenkins.yaml` and `.env` | Rerun `one-touch.sh` |
| Change Maven, Jenkins or Debian versions | the `podman pull` lines in `jenkins-env.sh` `prepare` | Delete `~/vdx-jenkins-pipeline-state/images.env` in the VM, or run teardown, then set up again |
| Change the ports | `JENKINS_PORT` in `.env` is fixed at first setup; the ngrok inspector port is in `jenkins-env.sh` `tunnel-up` | Teardown then setup again; update the docs that name the port |
| Change the webhook token | `token:` in the `Jenkinsfile` (keep the `token: '...'` format) | Delete the old GitHub webhook, rerun `one-touch.sh` |

Names, ports and paths are referenced in many files; see the "Fixed facts" list in [AGENTS.md](../../AGENTS.md) before renaming anything.
