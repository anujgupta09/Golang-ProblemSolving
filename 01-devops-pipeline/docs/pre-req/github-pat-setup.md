# GitHub Fine-Grained PAT Setup (java-maven-sample-app)

Quick reference to (re)create the read-only GitHub credential Jenkins uses to check out `java-maven-sample-app`. Chosen approach: **fine-grained PAT** (not a deploy key).

## Create the token

1. GitHub → **Settings → Developer settings → Personal access tokens → Fine-grained tokens → Generate new token**.
2. **Resource owner**: your account (`anujgupta09`).
3. **Repository access**: Only select repositories → `java-maven-sample-app`.
4. **Permissions**: click **Add permission**, choose **Contents** from the list, then set its own dropdown to **Read-only**. Don't add any other permission categories.
5. Set an expiry (fine-grained tokens require one) and copy the token immediately — GitHub shows it only once.

**One Touch automation only:** the manual flow needs just the read-only Contents permission above. The One Touch setup additionally needs **Webhooks → Read and write** on this token, so it can create the GitHub webhook automatically.
