# Documentation Index

Suggested reading order. Everything here supports the [top-level README](../README.md), which has the quick start.

## 1. Set up (once)

| Doc | Use it to |
| --- | --- |
| [Podman + WSL](pre-req/podman-wsl-setup.md) | Install the container engine; fixes for known WSL / netavark / build-context errors |
| [Docker Hub token](pre-req/dockerhub-token-setup.md) | Create the registry push token |
| [GitHub PAT (fine-grained)](pre-req/github-pat-setup.md) | Token for the app repo + webhook |
| [GitHub PAT (classic)](pre-req/classic-pat-setup.md) | Token for the pipeline repo checkout |
| [ngrok account](pre-req/ngrok-account-setup.md) | Auth token + dev domain for the webhook tunnel |

Then run `bash scripts/one-touch.sh` (see the [README](../README.md#quick-start)).

## 2. Operate

| Doc | Use it to |
| --- | --- |
| [How to cut a release](how-to-cut-a-release.md) | Bump the version, tag, push |
| [Verify and teardown](verify-and-teardown.md) | Confirm a healthy setup; remove everything cleanly |
| [Test the image](test-the-image.md) | Pull the published image, run it with a forwarded port, open it in a browser |
| [Troubleshooting](troubleshooting.md) | Symptom -> cause -> fix |

## 3. Understand (design and review)

| Doc | Covers |
| --- | --- |
| [Code tour](design-and-flow/code-tour.md) | Start here: the system in ten lines, one release traced, reading order, file reference, how to change things |
| [Pipeline design](design-and-flow/pipeline-flow.md) | Requirements -> design, flow diagram, safeguards |
| [Design decisions](design-and-flow/design-decisions.md) | Why each tool / approach, alternatives, trade-offs, production gaps |
| [Networking overview](design-and-flow/networking-overview.md) | Every network path, ports, exposure |
| [Security notes](design-and-flow/security-notes.md) | Credentials, trust boundaries, hardening log, known limitations, next steps |
