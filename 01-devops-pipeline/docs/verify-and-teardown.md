# Verify and Teardown

## Verify a healthy setup

`one-touch.sh` ends with a summary of `[ OK ]` / `[WARN]` / `[FAIL]` lines. Confirm independently:

| Check | Expect |
| --- | --- |
| `http://localhost:8081` | Login page; admin user from `.env` works |
| Manage Jenkins → Nodes | `vdx-worker` **Connected**; built-in node has 0 executors |
| Job `vdx-release` | One build from the first trigger; `NOT_BUILT` is healthy (no unpublished tag yet) |
| `podman ps` | `vdx-jenkins`, `vdx-worker`, `vdx-ngrok` running |
| `http://localhost:4041/api/tunnels` | One tunnel forwarding to `vdx-jenkins:8080` |
| GitHub → app repo → Settings → Webhooks | Webhook to `https://<NGROK_DOMAIN>/generic-webhook-trigger/invoke?...`; Recent Deliveries shows `200` after a tag push |

End-to-end proof is a release: follow [how-to-cut-a-release.md](how-to-cut-a-release.md) and check the image tag on Docker Hub.

## Tear down

```bash
bash scripts/one-touch-destroy.sh [path/to/.env]
```

Use the same `.env` as setup. Removal order: webhook → containers, volumes, network → images → VM pipeline directory. Each item is then checked as gone.

| Final line | Meaning | Exit |
| --- | --- | --- |
| `CLEAN` | Everything removed and verified | 0 |
| `DONE WITH WARNINGS` | Cleanup finished but at least one step warned (for example the VM or a webhook call was unreachable) | 1 |
| `INCOMPLETE` | At least one item is still present or a check failed; see the log | 1 |

- Best-effort: a missing resource is reported and skipped, so rerunning is safe.
- Removes by name: anything called `vdx-*` with the `vdx.owner` label goes, including from a manual setup. The manual flow's own VM dirs (`~/vdx-jenkins-kit`, `~/vdx-jenkins-state`) are not touched.
- Not removed: the Podman machine, Podman Desktop, your `.env`, images already pushed to Docker Hub.
- Podman side only (no GitHub call): run `jenkins-env.sh reset` in the VM.
- `one-touch.sh` leaves the tunnel running. Stop only the public exposure, keep the setup: `podman rm -f vdx-ngrok` (or `jenkins-env.sh tunnel-down` in the VM). Bringing it back means rerunning `one-touch.sh`.
