# Security Notes

Accepted posture and trade-offs for this pipeline (local demo / assessment).

## Credentials

- PATs (`github-java-maven-sample-app-pat`, `github-compvalidator-anuj-pat`) and Docker Hub token (`dockerhub-anujdocker9799`) live **only** in Jenkins credentials — never in the repo. Seeded by `scripts/one-touch.sh` via JCasC ([README](../../README.md)).
- Jenkinsfile uses credential **IDs** only (`withCredentials`, `credentialsId`).
- App checkout: `GIT_ASKPASS` → PAT never in argv or URL (`Discover Release Tag`).
- Docker Hub: `--password-stdin` + `EXIT` trap `podman --remote logout` → session cleared even if push fails (`Publish to Registry`).

## Tunnel exposure

- Jenkins is public **only while `vdx-ngrok` runs**. `one-touch.sh` starts it and leaves it running, so stop it when not demoing: `podman rm -f vdx-ngrok`.
- ngrok inspection API bound to `127.0.0.1` (host `4041`); the authtoken reaches the container as `-e NGROK_AUTHTOKEN=...` (visible to `podman inspect`, like the other secrets; see next steps).
- Outside a window: no inbound trigger path exists.

## Webhook trust

- Webhook only **wakes** the job; `Discover Release Tag` re-derives tag, version and "already published" from GitHub / Docker Hub via `git ls-remote`.
- Static token `vdx-release-trigger` is committed in the Jenkinsfile. Leak → unwanted build attempt only (gates still apply). Not production-grade auth.

## Rootless Podman socket

- Only `vdx-worker` mounts the socket (controller does not) → builds sibling containers.
- Accepted CI trust boundary for a local demo; production → dedicated runner / engine / account.

## Other accepted trade-offs

- Docker Hub image `anujdocker9799/compvalidator` is **public** by design — must contain only the compiled app.
- `compvalidator-anuj` checkout uses a classic PAT (`repo` scope): fine-grained PATs can't reach a repo where the owner is an outside collaborator. Bounded by expiry.
- One Touch: secrets visible to `podman inspect`; `curl -u` and `curl -H "Authorization: token ..."` expose the admin password and the GitHub token in local argv — see [README](../../README.md#known-limits-local-demo).

## Hardening log

Completed security work. Scope: this task only; JCasC hardening was out of scope.

| Item | Change | Where |
| --- | --- | --- |
| Registry logout | `EXIT` trap runs `podman --remote logout docker.io` before login, so the session is cleared even if push fails | `Jenkinsfile`, Publish to Registry |
| ngrok inspection API | Bound to `127.0.0.1` only | `scripts/jenkins-env.sh` `tunnel-up` |
| Config split | Non-secret settings in `config/release.properties` (`Load Release Config` stage); secrets stay in Jenkins credentials | `config/`, `Jenkinsfile` |
| Reviewer notes | This document | `docs/design-and-flow/` |

## Known limitations and next steps

Open items, highest priority first. Demo-vs-production differences: [design-decisions.md](design-decisions.md#production-gaps).

1. Move the webhook secret out of the `Jenkinsfile` into a Jenkins credential; add signature verification.
2. Stop passing secrets via `--env-file` / `-e` (use Podman secrets), including the ngrok authtoken, which is currently `-e`, so `podman inspect` cannot reveal them.
3. Replace `curl -u` and `curl -H "Authorization: token ..."` in the local scripts (netrc, or a header read from a file) so no token appears in argv.
4. Use a separate token for webhook creation instead of reusing `APP_REPO_GIT_TOKEN`.
5. Put TLS in front of Jenkins; today it is HTTP on `localhost`.
6. Protect `release-*` tags on the app repo; retain source SHA and image digest per release.
7. Replace the shared rootless socket with per-build ephemeral agents on a dedicated engine.
8. Pin the `ngrok/ngrok` image by digest (the four Jenkins/agent/Maven/Debian bases already are).
9. Pin Jenkins plugin versions: `plugins.txt` lists names only, so a rebuild pulls the latest of each.
10. Distinguish "not found" from a network error in the Docker Hub already-published check (today an unreachable Docker Hub counts as "not published").

## Secret inventory and flow

No secret is committed; `.env` is git-ignored (only `.env.example` is tracked). Five real secrets exist at runtime:

| Secret | Set in | Where it travels | Where it ends up |
| --- | --- | --- | --- |
| `JENKINS_ADMIN_PASSWORD` | `.env` | stdin to the VM → mode-600 file → `--env-file` | Jenkins user store (hashed); controller env while it runs |
| `PIPELINE_REPO_GIT_TOKEN` (classic PAT) | `.env` | same | Jenkins credential; used by the job's own checkout |
| `APP_REPO_GIT_TOKEN` (fine-grained PAT) | `.env` | same | Jenkins credential; `GIT_ASKPASS` / SCM checkout; also used by `one-touch.sh` for GitHub API calls |
| `DOCKERHUB_TOKEN` | `.env` | same | Jenkins credential; `--password-stdin` at publish |
| `NGROK_AUTHTOKEN` | `.env` | stdin to the VM → mode-600 file | `-e` on the `vdx-ngrok` container |

Not secret but sensitive: the webhook trigger token `vdx-release-trigger` (committed in the `Jenkinsfile`; also appears in the payload URL that setup prints and logs). The agent connection secret is generated by Jenkins, stored mode 600, and mounted read-only into the worker.

Hops, in order: `.env` (outside git) → `one-touch.sh` environment → SSH **stdin** to the VM (never an argument) → `~/vdx-jenkins-pipeline-state/onetouch-secrets.env` (dir 700, file 600, deleted after the container starts) → controller environment → JCasC → Jenkins credential store (encrypted with the controller's own key in `vdx-jenkins-home`) → `withCredentials` in a build step (masked in the console).

Caveats:
- A default `config/.env` lives inside the folder that is copied into the VM, so it is copied too. A file passed by path or `ENV_FILE` from outside the repo is not. Keeping the `.env` outside the repo is the safer choice.
- The GitHub API calls in `one-touch.sh` and the admin login pass credentials in `curl` arguments on the Windows host (`-H "Authorization: token ..."`, `-u`), visible to other local processes for the length of the call.
- The setup log keeps raw tool output. It is written to the temp directory; delete it if the machine is shared.
