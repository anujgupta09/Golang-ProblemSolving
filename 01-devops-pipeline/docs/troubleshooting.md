# Troubleshooting

Symptom → cause → fix. The setup log path is printed in the `one-touch.sh` header and footer; rerun with `VERBOSE=1` to stream raw output. Every setup step is idempotent: fix the cause and rerun.

## Setup (`one-touch.sh`)

| Symptom | Cause | Fix |
| --- | --- | --- |
| `Missing <file> ...` | No env file found | Pass its path, set `ENV_FILE`, or copy `config/.env.example` to `config/.env` |
| `<VAR> is not set in .env` / `JENKINS_ADMIN_PASSWORD must be at least 8 characters` | Required value missing or too short | Fill the row in [README](../README.md#env-values) |
| `podman is required` / `curl is required` | Shell lacks them | Use Git Bash with the Podman CLI on `PATH` |
| `Podman machine '...' is not running or not reachable` | VM stopped | `podman machine start <name>` |
| `Could not read the GenericTrigger token from Jenkinsfile` | `token: '...'` format changed | Restore the exact `token: '...'` form |
| `APP_REPO_URL must look like https://github.com/<owner>/<repo>.git` | Wrong URL shape | Use the HTTPS clone URL |
| `Cannot list webhooks on <owner>/<repo>` | Bad URL, no route to `api.github.com`, or token lacks webhook rights | Check URL and token scopes ([GitHub PAT](pre-req/github-pat-setup.md)) |
| `Could not create the webhook ... HTTP 403/404` | `APP_REPO_GIT_TOKEN` lacks webhook write | Classic: `admin:repo_hook` or `repo`; fine-grained: Webhooks read+write |
| `Could not create the webhook ... HTTP 422` | Webhook for this URL already exists, or GitHub rejected the URL | Delete the old webhook; check `NGROK_DOMAIN` |
| `[FAIL] ... Jenkins could not load the Jenkinsfile` | Bad `PIPELINE_REPO_*` values, branch missing, or PAT cannot read it | Check `PIPELINE_REPO_URL`, `_BRANCH`, `JOB_SCRIPT_PATH`; use a **classic** PAT with `repo` scope ([why](design-and-flow/security-notes.md#other-accepted-trade-offs)) |
| `... is not owned by this One Touch setup` / `... without our ownership label` | A same-named resource exists that this setup did not create | Rename or remove it yourself; the script refuses to modify what it does not own |
| A container never becomes ready | Slow pull, port in use, bad config | Its state and last 30 log lines are printed; check `JENKINS_PORT` is free |
| Changed `JENKINS_PORT` but Jenkins still uses the old port | The port is stored in the VM at the first `prepare` (`images.env`) | Run `one-touch-destroy.sh`, then set up again with the new port |

## Podman / WSL (details: [podman-wsl-setup.md](pre-req/podman-wsl-setup.md))

| Symptom | Cause | Fix |
| --- | --- | --- |
| `netavark ... nftables error` on container start | WSL older than 2.7.5 with Podman 6.x | `wsl --update` (elevated), `wsl --shutdown`, `podman machine start` |
| `mounting an overlay over build context directory ... userxattr` | Build context under `/mnt/<drive>/` (9p/DrvFs) | Build from the VM's native filesystem; `one-touch.sh` already copies the folder there |
| Path arguments mangled in Git Bash | MSYS path conversion | Prefix with `MSYS_NO_PATHCONV=1` |

## Release runs

| Symptom | Cause | Fix |
| --- | --- | --- |
| Tag pushed, nothing happens | Tag went to the wrong repo, or is local only | Delete it; push to `java-maven-sample-app` ([steps](how-to-cut-a-release.md)) |
| Webhook delivery is not `200` | `vdx-ngrok` stopped, or domain/token mismatch | Rerun `one-touch.sh` (it recreates the tunnel; `tunnel-up` needs the secrets that script sends); confirm `NGROK_DOMAIN`; redeliver from GitHub |
| Build ends `NOT_BUILT` | No unpublished `release-*` tag, or the version is already on Docker Hub | Expected; bump and tag again ([re-running](how-to-cut-a-release.md#re-running-a-version)) |
| Validate Ancestry and Version: `expects POM version X, found Y` | Tag does not equal the POM `<version>` | Fix the POM, push `main`, cut a new tag |
| Validate Ancestry and Version: tag not reachable from `origin/main` | Tagged commit was not pushed to `main` first | Push the commit to `main`, then tag it |
| `Release config missing required key` / `Missing release config file` | `config/release.properties` incomplete on the pipeline branch | Restore the file or key; push the pipeline branch |
| Publish to Registry fails | Docker Hub token wrong, expired, or read-only | Recreate per [Docker Hub token](pre-req/dockerhub-token-setup.md), update `.env`, rerun `one-touch.sh` |
| Builds never start | `vdx-worker` disconnected | Manage Jenkins → Nodes; rerun `one-touch.sh` (starts the existing worker container) |

## Still stuck

1. Read the last 25 lines printed on `[FAIL]` and the full log path.
2. Rerun with `VERBOSE=1`.
3. `bash scripts/one-touch-destroy.sh`, then set up again: setup reseeds everything from `.env`.
