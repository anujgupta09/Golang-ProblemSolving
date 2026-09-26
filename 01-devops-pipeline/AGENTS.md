# 01-devops-pipeline — AI agent guide

Tag `release-X.Y.Z` on `java-maven-sample-app` → Jenkins (container) builds + tests → Debian 13 image → Docker Hub. Human docs: [README.md](README.md).

## Commands (Windows Git Bash)

| Do | Command |
| --- | --- |
| Set up everything | Fill an env file (template `config/.env.example`), then `bash scripts/one-touch.sh [env-file]` |
| Tear down + verify | `bash scripts/one-touch-destroy.sh [env-file]` |
| VM-side action | `jenkins-env.sh {prepare\|controller\|agent\|probe\|tunnel-up\|tunnel-down\|stop\|reset}` (runs in the Podman VM, driven by `one-touch.sh`) |
| Syntax check | `bash -n scripts/*.sh` |

No unit tests. Real verification = full cycle: `one-touch.sh` → push a `release-*` tag → `one-touch-destroy.sh`.

## Layout

| Path | Role |
| --- | --- |
| `Jenkinsfile` | Pipeline (8 stages) |
| `config/` | `release.properties` (non-secret, read by `Load Release Config`), `.env.example` → `.env` (setup values, git-ignored) |
| `scripts/` | `one-touch.sh`, `one-touch-destroy.sh`, `jenkins-env.sh`; `lib/` = plumbing (`ui.sh`, `jenkins.sh`, `report.sh`) |
| `docker/controller/` | Controller image: `plugins.txt`, `casc/jenkins.yaml` (JCasC) |
| `docker/jenkins/` | Worker `Dockerfile.worker`, `init.groovy.d/vdx-worker-node.groovy` |
| `docker/app/` | Release image |
| `docs/` | `README.md` (index), `how-to-cut-a-release.md`, `verify-and-teardown.md`, `troubleshooting.md`, `pre-req/`, `design-and-flow/` |

## Fixed facts — don't change without checking every reference

- **Names:** `vdx-jenkins`, `vdx-worker`, `vdx-ngrok`, `vdx-ci`, `vdx-jenkins-home`, `vdx-workspace`, `vdx-maven-cache`. Ownership label `vdx.owner=vdx-local-jenkins`.
- **Ports:** Jenkins `127.0.0.1:8081`; ngrok inspection host `4041` → container `4040`.
- **VM dirs:** `~/vdx-jenkins-pipeline-ws`, `~/vdx-jenkins-pipeline-state`.
- **Credential IDs** (`.env` `*_CRED_ID`, JCasC, `release.properties`) must match each other.
- **Webhook token:** `one-touch.sh` / `one-touch-destroy.sh` parse `token: '…'` out of `Jenkinsfile` with grep — keep that format.
- **Script depth:** scripts resolve the task root as `scripts/..`; the whole folder is copied to the VM as-is (`~/vdx-jenkins-pipeline-ws`). Moving folders breaks paths.
- **Shared files:** `docker/jenkins/*` and `config/release.properties` are used by setup and by the pipeline; edit with both in mind.

## Gotchas

- Console output and the log file live in `scripts/lib/ui.sh` (read its header). `jenkins-env.sh` reports results as `@@ OK|WARN|INFO <text>` lines (`note` helper) that `ui.sh` renders — keep that prefix format.
- Podman CLI from Git Bash needs `MSYS_NO_PATHCONV=1` on path arguments.
- Pipeline needs the **Pipeline Utility Steps** plugin (`readProperties`) — in `docker/controller/plugins.txt`.
- The env file (arg → `ENV_FILE` → `config/.env`) is git-ignored or external, and holds real tokens. Never read, print or commit it.
- Manual step-by-step flow was removed here; it lives on branch `feat/task-1-java-packaging-pipeline` (frozen, don't edit).

## Change checklist

- Touched a script → `bash -n`; grep for every name/path you changed.
- Touched `Jenkinsfile` / JCasC / plugins → say it needs a full cycle to verify.
- Touched behavior → update `README.md` and the matching `docs/` file.

## Repo-wide rules (repo has several tasks; this is task 01)

- **Scope:** work only inside `01-devops-pipeline/`. Don't create or edit files elsewhere in the repo (root `README.md` is managed by someone else).
- **Branches:** `feat/task-N-…`. Frozen/tested branches are never edited; work on the branch you're given.
- **Secrets:** never commit or print env files, tokens, PATs.
- **Line endings:** `*.sh`, `*.groovy`, `Dockerfile*`, `Jenkinsfile` stay LF (root `.gitattributes`).
- **Docs style:** bullets and tables with pointers, not paragraphs; update docs in the same change as the code.
- **Regression:** change only what's required, no drive-by renames; verify before claiming done and say what wasn't run.
- **Commits:** only when asked.

## Task folder template (`NN-name/` = two-digit task number + short name)

```
NN-name/
  README.md  AGENTS.md  CLAUDE.md (@AGENTS.md)
  config/   settings + env template     scripts/   entry points (setup + teardown)
  docker/   image definitions           docs/      index, how-to, verify, troubleshooting, pre-req/, design-and-flow/
```
