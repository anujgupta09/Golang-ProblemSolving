# Test the Published Image Locally

Pull the released image from Docker Hub, run it with a port forwarded to Windows, and open it in a browser. This proves the image the pipeline published is the one that works.

**Needs:** the Podman machine running, Git Bash with `podman` and `curl`. No Docker Hub login: the repo is public. You do not need Jenkins running.

## 1. Pick the tag

The image is `docker.io/anujdocker9799/compvalidator:release-X.Y.Z`. The tag is the same as the git tag. List what exists:

```bash
curl -s "https://hub.docker.com/v2/repositories/anujdocker9799/compvalidator/tags?page_size=10" | grep -o '"name":"[^"]*"'
```

Set the one you want (example):

```bash
TAG=release-1.0.9
IMAGE=docker.io/anujdocker9799/compvalidator:$TAG
```

## 2. Pull and run

```bash
podman machine list                     # the machine must show "Currently running"
podman pull "$IMAGE"
podman run -d --name vdx-image-test -p 127.0.0.1:8080:8080 "$IMAGE"
```

- `-p 127.0.0.1:8080:8080` publishes container port `8080` (the app's port) on `127.0.0.1:8080` of this machine only, so nothing on your LAN can reach it. The Podman machine forwards the published port to Windows.
- Port `8080` is free while Jenkins is up (Jenkins uses `8081`). If `8080` is taken, use another host port, for example `-p 127.0.0.1:9090:8080`, and use `9090` below.
- The Spring Boot app takes a few seconds to start.

## 3. Test it

**Browser:** open <http://localhost:8080/greeting>

Expected:

```json
{"id":1,"content":"Hello, World!"}
```

Try a parameter: <http://localhost:8080/greeting?name=VDX> returns `"content":"Hello, VDX!"`. Refresh and `id` increases (a request counter).

**Command line:**

```bash
curl -s http://localhost:8080/greeting
curl -s "http://localhost:8080/greeting?name=VDX"
```

## 4. Check what the pipeline promised

```bash
podman exec vdx-image-test sh -c '. /etc/os-release; echo "$PRETTY_NAME"'   # Debian GNU/Linux 13 (trixie)
podman exec vdx-image-test id -u                                            # not 0 (non-root)
podman logs vdx-image-test | tail -n 5                                      # Spring Boot startup lines
podman ps --filter name=vdx-image-test                                      # shows 127.0.0.1:8080->8080/tcp
```

## 5. Clean up

```bash
podman rm -f vdx-image-test
podman rmi "$IMAGE"          # optional: remove the pulled image
```

## If something goes wrong

| Symptom | Cause | Fix |
| --- | --- | --- |
| `Cannot connect to Podman` | Machine stopped | `podman machine start` |
| `manifest unknown` / `not found` on pull | Tag does not exist (note the `release-` prefix) | List tags (step 1) |
| `address already in use` | Host port `8080` is taken | Use another host port, e.g. `-p 127.0.0.1:9090:8080` |
| Browser says connection refused right after run | App still starting | Wait a few seconds; check `podman logs vdx-image-test` |
| Container exits at once | Startup error | `podman logs vdx-image-test` |
| Name `vdx-image-test` already in use | Left over from an earlier test | `podman rm -f vdx-image-test` |

See also: [Verify and teardown](verify-and-teardown.md), [How to cut a release](how-to-cut-a-release.md).
