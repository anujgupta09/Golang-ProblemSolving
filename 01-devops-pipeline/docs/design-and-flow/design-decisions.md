# Design Decisions

Why the pipeline looks the way it does. Requirements and flow: [pipeline-flow.md](pipeline-flow.md). Security posture: [security-notes.md](security-notes.md).

## Decisions

| # | Decision | Why | Alternative considered | Trade-off accepted |
| --- | --- | --- | --- | --- |
| 1 | Jenkins **controller and worker are containers**; controller has 0 executors | Brief: nothing installed on the provision server; builds stay off the controller | Jenkins on the host; builds on the built-in node | Extra images to build and maintain |
| 2 | **Podman rootless**; worker uses the **remote client** against the host socket | No root daemon, no Docker-in-Docker, no privileged container | Docker Desktop; DinD; privileged worker | The socket is a CI trust boundary ([security notes](security-notes.md#rootless-podman-socket)) |
| 3 | Maven, image build and smoke test run as **sibling containers** | Tooling lives in containers, not the worker image; each run is disposable | Maven inside the worker image | Shared volumes for workspace and cache |
| 4 | **Tag-triggered** (`release-X.Y.Z`) via Generic Webhook Trigger; the job re-derives everything from git | Webhook payload is not trusted; matches "release from main" | Polling SCM; GitHub Release event; trusting the payload | Needs a public path to Jenkins |
| 5 | **ngrok tunnel**, run only in demo windows | Jenkins is on localhost; GitHub must reach it | Public VM with TLS; SCM polling | Free-tier domain; tunnel not always up |
| 6 | **Registry is the source of truth** for "already published" | Idempotent: a repeated tag ends `NOT_BUILT`, not a duplicate or a failure | Job-side state; overwriting tags | One extra registry call per run |
| 7 | **Ancestry gate:** tagged commit must be reachable from `origin/main` | Enforces "release from main" without building `main`'s tip | Building the branch head | Push to `main` before tagging |
| 8 | Effective **POM version must equal the tag** | Tag and artifact cannot disagree; CI never edits the POM | Deriving the version from the tag | Version bump is a separate manual commit |
| 9 | **JCasC + baked plugins**, no setup wizard | Reproducible, reviewable as code | Manual UI setup | Config changes need a rerun (controller recreated, data volume kept) |
| 10 | **One Touch scripts**: idempotent, one line per check, log file | Setup and teardown are repeatable and self-verifying | Manual step-by-step guide (kept on branch `feat/task-1-java-packaging-pipeline`) | More script code to maintain |
| 11 | **Pinned image versions**; runtime image is JRE only, non-root | Reproducible builds; smaller attack surface | `latest` tags; JDK in the runtime image | Pins need occasional bumps |
| 12 | Non-secret settings in `config/release.properties`; secrets only in Jenkins credentials | Reviewable config; nothing sensitive in git | Everything in the Jenkinsfile or `.env` | Two places to look |

## Production gaps

What changes beyond a local demo. Open items are listed in [security-notes.md](security-notes.md#known-limitations-and-next-steps).

| Area | Demo | Production |
| --- | --- | --- |
| Ingress | ngrok tunnel; HTTP on localhost | Managed hostname + TLS in front of Jenkins; webhook IP allowlist |
| Webhook auth | Static token in `Jenkinsfile` | Secret from a credential store; HMAC signature check |
| Build isolation | Worker mounts the rootless socket | Ephemeral per-build agents on a dedicated engine or account |
| Secrets | Env file + `--env-file` (visible to `podman inspect`) | Secret manager; short-lived tokens |
| Registry | Public repo; one token | Private repo; scoped robot account; image signing; retained digest |
| Tags | Any writer can push `release-*` | Protected tags |
| Operations | Single controller; local logs | Backups or restore runbook; central logging |
