# How to Cut a Release

**Precondition:** webhook on `java-maven-sample-app` shows `200` in Recent Deliveries and `vdx-ngrok` is running (demo windows only). Setup: [../README.md](../README.md).

The manual git commands run in **`java-maven-sample-app`** (not `compvalidator-anuj`); the shortcut script runs from this folder and changes into the app checkout itself.

## Steps

**Shortcut:** `bash scripts/version-bump.sh [X.Y.Z]` does steps 1–3 (no argument = patch +1, each part rolling over at 9: 2.0.9 → 2.1.0). Set `APP_DIR="/path/to/java-maven-sample-app"` in your `.env` (same file as setup, or `ENV_FILE`) first; it requires a clean `main` that matches `origin/main`. The manual steps follow.

1. **Bump version** — edit only `<version>` in `pom.xml`, e.g. `1.0.9`.
   - Don't find-and-replace elsewhere; the Jenkinsfile reads the POM version.
2. **Push to `main` first** — ancestry gate needs the tagged commit reachable from `origin/main`:
   ```bash
   git add pom.xml
   git commit -m "Bump version to 1.0.9"
   git push origin main
   ```
3. **Tag that exact commit** — `X.Y.Z` must equal the POM version; the push fires the webhook:
   ```bash
   git tag release-1.0.9
   git push origin release-1.0.9
   ```
4. **Verify** (below).

Tag pushed to the wrong repo (`compvalidator-anuj`)? Nothing triggers — delete it:
```bash
git push origin --delete release-1.0.9
git tag -d release-1.0.9
```

## Verify

| Where | Expect |
| --- | --- |
| GitHub → Settings → Webhooks → Recent Deliveries | newest is `200` |
| Jenkins → `vdx-release` | new build in seconds; cause "GitHub tag-creation webhook" |
| Stages | Load Release Config → Discover Release Tag → Checkout Exact Tag → Validate Ancestry and Version → Compile and Test → Build Debian Image → Smoke Test → Publish to Registry |
| Result | `SUCCESS` through Publish to Registry; image `release-X.Y.Z` visible on Docker Hub |
| `podman ps -a` | only `vdx-jenkins` / `vdx-worker` (+ `vdx-ngrok`); per-run `-app` `-maven` `-version` containers removed even on failure |

## Re-running a version

Same tag pushed again → **Discover Release Tag** skips it if already on Docker Hub (registry is the source of truth) → build ends `NOT_BUILT`, not a failure.
