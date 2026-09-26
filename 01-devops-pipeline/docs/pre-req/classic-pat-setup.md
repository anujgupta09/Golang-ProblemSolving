# GitHub Classic PAT Setup (compvalidator-anuj)

Quick reference to create the token Jenkins uses to check out this pipeline repo (`compvalidator-anuj`) for the job's own Jenkinsfile. It must be a **classic** PAT: fine-grained PATs cannot reach a repo where the owner is an outside collaborator. Goes in `.env` as `PIPELINE_REPO_GIT_TOKEN`.

## Create the token

1. Go to <https://github.com/settings/tokens> (Settings → Developer settings →
   Personal access tokens → **Tokens (classic)**).
2. **Generate new token** → **Generate new token (classic)**.
3. **Note**: something identifiable, e.g. `jenkins-compvalidator-anuj-checkout`.
4. **Expiration**: pick a real expiry (e.g. 90 days), not "No expiration" — this
   token has account-wide reach, so keep its lifetime bounded and rotate it.
5. **Scopes**: check **`repo`** (full control of private repositories). Classic
   tokens have no narrower read-only option for private repos — this is the
   documented tradeoff vs. fine-grained tokens.
6. **Generate token**, then copy it immediately — GitHub only shows it once.


