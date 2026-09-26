# Docker Hub Access Token Setup

Quick reference to (re)create the Docker Hub credential Jenkins uses to push the release image. Registry: `anujdocker9799` (https://hub.docker.com/repositories/anujdocker9799). Images publish as `docker.io/anujdocker9799/<image-name>:release-X.Y.Z`.

## Create the token

1. Log in to [hub.docker.com](https://hub.docker.com) as `anujdocker9799`.
2. **Account Settings → Security → Personal Access Tokens → Generate new token**.
3. Description: e.g. `jenkins-vdx-release`.
4. Permissions: **Read & Write** (needed to push images).
5. Copy the token immediately — Docker Hub shows it only once.
