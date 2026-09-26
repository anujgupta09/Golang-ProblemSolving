# 01 — DevOps release pipeline

Tag `release-X.Y.Z` on `java-maven-sample-app` → Jenkins (containerized) builds,
tests, packages a Debian 13 image → pushes it to Docker Hub with the same tag `release-X.Y.Z`.

- Setup: **one command** — `bash scripts/one-touch.sh [path/to/.env]`
- Teardown: `bash scripts/one-touch-destroy.sh [path/to/.env]`
- Docs: [docs/README.md](docs/README.md) (index, troubleshooting, design decisions)
- Manual step-by-step version: branch `feat/task-1-java-packaging-pipeline`

## Quick start

1. Prereqs (once): [Podman + WSL](docs/pre-req/podman-wsl-setup.md), Podman machine **running**, Git Bash with `podman` + `curl`.
2. Create tokens: [Docker Hub](docs/pre-req/dockerhub-token-setup.md) · [GitHub PAT](docs/pre-req/github-pat-setup.md) · [classic PAT](docs/pre-req/classic-pat-setup.md) · [ngrok](docs/pre-req/ngrok-account-setup.md) (**required** — GitHub reaches Jenkins only through the ngrok tunnel).
3. Create your `.env` from [config/.env.example](config/.env.example) → fill **required** rows below. Keep it anywhere (outside the repo is safest).
4. From Git Bash: `bash scripts/one-touch.sh [path/to/.env]`
5. Open `http://localhost:8081` → log in with `JENKINS_ADMIN_USER`.
6. Cut a release → [docs/how-to-cut-a-release.md](docs/how-to-cut-a-release.md)

## `.env` values

Path is chosen in this order: **1st argument** → `ENV_FILE` variable → `config/.env` (git-ignored default).

```bash
bash scripts/one-touch.sh /c/secrets/vdx.env
ENV_FILE=/c/secrets/vdx.env bash scripts/one-touch-destroy.sh
```

Use the same file for setup and teardown. A file outside the repo is never copied into the VM.

| Variable | Req | Notes |
| --- | --- | --- |
| `JENKINS_ADMIN_USER` / `_PASSWORD` | yes | You choose; password ≥ 8 chars |
| `PIPELINE_REPO_URL` / `_BRANCH` | yes | This repo + branch holding the `Jenkinsfile` |
| `PIPELINE_REPO_GIT_USERNAME` / `_TOKEN` | yes | **Classic** PAT, `repo` scope |
| `APP_REPO_URL` | yes | `java-maven-sample-app` |
| `APP_REPO_GIT_USERNAME` / `_TOKEN` | yes | PAT; needs **Webhooks: read/write** if using webhook |
| `DOCKERHUB_USERNAME` / `_TOKEN` | yes | Access token, not password |
| `NGROK_AUTHTOKEN` | yes | From your ngrok account; the tunnel is how GitHub reaches Jenkins |
| `NGROK_DOMAIN` | yes | Your ngrok Dev Domain, e.g. `your-name.ngrok-free.dev` |
| `PODMAN_MACHINE` | no | Default `podman-machine-default` |
| `JENKINS_PORT` | no | Default `8081`; fixed at the first setup (changing it later needs teardown + setup) |
| `JOB_NAME` | no | Default `vdx-release` |
| `JOB_SCRIPT_PATH` | no | Default `01-devops-pipeline/Jenkinsfile` |
| `APP_DIR` | release helper only | Local `java-maven-sample-app` checkout for `scripts/version-bump.sh`; keep the value quoted |
| `*_CRED_ID` (3) | no | `APP_REPO_CRED_ID` and `REGISTRY_CRED_ID` must match `APP_CREDENTIALS_ID` / `REGISTRY_CREDENTIALS_ID` in [config/release.properties](config/release.properties); `PIPELINE_REPO_CRED_ID` is used only by the job's own checkout |

Not in `.env`: registry destination (→ `config/release.properties`), webhook token (read from `Jenkinsfile`).

## What `one-touch.sh` does

| # | Step | Replaces |
| --- | --- | --- |
| 1 | Copy pipeline folder into Podman VM | manual copy |
| 2 | `prepare` — pin images, build worker + controller images | plugin install, image builds |
| 3 | Send secrets to VM over SSH stdin | pasting tokens |
| 4 | `controller` — JCasC seeds admin, security, executors=0, credentials, job | setup wizard, UI clicks |
| 5 | `agent` — start `vdx-worker`, wait until connected | node check |
| 6 | `probe` — rootless engine, sibling Maven, shared volumes | manual self-test |
| 7 | Trigger first build (registers webhook trigger) | manual first run |
| 8 | GitHub webhook + ngrok tunnel | webhook + tunnel by hand |

Every step is idempotent — on `[FAIL]`, fix the cause and rerun.
Changed `.env` / JCasC / plugins → rerun; controller is recreated, data volume kept.

**Output:** one `[ OK ]` / `[WARN]` / `[FAIL]` line per check; raw tool output goes to a log file.

| Setting | Effect |
| --- | --- |
| Log path | printed in the header and footer; default `${TMPDIR:-/tmp}/vdx-one-touch-<timestamp>.log`, override with `ONETOUCH_LOG` |
| `VERBOSE=1` | also stream the raw output live |
| `NO_COLOR=1` | disable colours (auto-off when not a terminal) |
| On failure | last 25 log lines + the log path are printed |
| Preflight | before anything is created: Podman machine reachable, `Jenkinsfile` trigger token readable, `APP_REPO_URL` well-formed, GitHub token can list webhooks |
| Timeouts | when a container never becomes ready, its state and last 30 log lines are shown; all `curl` calls have connect/total timeouts |
| Safety net | an unexpected error or Ctrl-C still ends with a clear message and the log path |

## Layout

| Path | Purpose |
| --- | --- |
| `Jenkinsfile` | The pipeline |
| `config/` | `release.properties` (non-secret pipeline settings), `.env.example` → `.env` (setup values) |
| `scripts/one-touch.sh` | Windows-side driver: config → helpers → preflight → stages 1–8 → `main` |
| `scripts/one-touch-destroy.sh` | Full teardown + verification |
| `scripts/version-bump.sh` | Release helper: bump POM version in the app repo, push `main`, push the tag (needs `APP_DIR` in `.env`) |
| `scripts/lib/` | Plumbing for the Windows-side scripts: `ui.sh` (console lines, log, `@@` protocol), `jenkins.sh` (VM + Jenkins helpers, `wait_for`), `report.sh` (header + summary) |
| `scripts/jenkins-env.sh` | VM-side actions: `prepare controller agent probe tunnel-up tunnel-down stop reset` |
| `docker/controller/` | Controller image: `plugins.txt`, `casc/jenkins.yaml` |
| `docker/jenkins/` | Worker image + `init.groovy.d/vdx-worker-node.groovy` |
| `docker/app/` | Release image (Debian 13) |
| `docs/` | Index, how-to, verify/teardown, troubleshooting, pre-reqs, design ([docs/README.md](docs/README.md)) |
| `AGENTS.md` / `CLAUDE.md` | AI-assistant context |

## Teardown

`bash scripts/one-touch-destroy.sh [path/to/.env]` removes: webhook → containers/volumes/network → images → VM pipeline dir, then verifies each is gone.
Same output style, log file, `VERBOSE=1` and `NO_COLOR=1` as setup. Best-effort: a missing or unreachable resource is reported and skipped. Ends `CLEAN` (exit 0), `DONE WITH WARNINGS` or `INCOMPLETE` (exit 1).
Podman-side only: run `jenkins-env.sh reset` in the VM.

**Destroy removes by name** — containers, volumes and network named `vdx-*` are deleted even if a manual setup created them (same names, same `vdx.owner` label). The manual flow's own VM dirs (`~/vdx-jenkins-kit`, `~/vdx-jenkins-state`) are not touched.

## Verify a run

- Nodes: `vdx-worker` **Connected**
- Job `vdx-release`: one build; `NOT_BUILT` is healthy (no unpublished tag yet)
- Tunnel (if enabled): `http://localhost:4041/api/tunnels`

## Known limits (local demo)

- Secrets pass via `--env-file` / `-e` → visible to `podman inspect` on this host
- `curl -u` and `curl -H "Authorization: token ..."` briefly expose the admin password and the GitHub token in local argv
- HTTP only, `localhost`
- Webhook API call reuses `APP_REPO_GIT_TOKEN`

Docs index: [docs/README.md](docs/README.md) · [troubleshooting](docs/troubleshooting.md) · [verify and teardown](docs/verify-and-teardown.md) · [design decisions](docs/design-and-flow/design-decisions.md)

More: [security notes](docs/design-and-flow/security-notes.md) · [networking](docs/design-and-flow/networking-overview.md) · [code tour](docs/design-and-flow/code-tour.md) · [pipeline design](docs/design-and-flow/pipeline-flow.md)
