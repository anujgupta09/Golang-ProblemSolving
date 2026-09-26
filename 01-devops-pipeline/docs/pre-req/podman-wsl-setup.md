# Podman Desktop + WSL Setup (Windows)

Standalone setup/troubleshooting notes for running Podman on Windows via WSL. Written to be usable on its own, on another person's machine, in a fresh chat with no prior context. Verified on 2026-09-21 against `podman-machine-default` (WSL provider, Fedora 44 `podman-machine-os`, Podman `6.0.2`).

## Setup Steps

1. Confirm WSL 2 is installed: `wsl.exe --version` (or `wsl --status`). If missing, follow https://aka.ms/wslinstall.
2. Install and open **Podman Desktop**. On first launch it offers onboarding: choose **Start Onboarding**, install the Podman CLI if prompted, select the **WSL** provider (not Hyper-V), and create/start the default Podman machine. Optional Kubernetes/kubectl/Compose setup can be skipped initially.
3. Verify from a terminal:
   ```bash
   podman --version
   podman machine list
   podman info
   podman run --rm hello-world   # or any small Linux image
   ```
4. No host-level Java/Maven/other build toolchain is required — those run inside containers built from the Podman machine.

## Known Issue: netavark nftables error

**Symptom:**
```
Error: (HTTP code 500) server error - netavark (exit code 1): nftables error: "nft" did not return successfully while applying ruleset:
```

**Distinguishing detail:** this can fail *only* from the Podman Desktop UI (Images → Run → Start Container) while plain `podman run ...` from the CLI works fine. That is because:
- CLI rootless runs default to the `pasta` network backend, which does not need nftables.
- The Podman Desktop UI's "Run" flow attaches the container to the netavark-managed `podman` bridge network, which does require a working nftables setup inside the WSL VM.

**Root cause:** Podman 6.x dropped iptables support for netavark and relies on nftables. This requires **WSL version 2.7.5 or newer**. Older WSL (observed failing at `2.5.9.0`) has incomplete/broken nftables support in its kernel, so netavark's `nft` ruleset application fails. This matches upstream reports: [containers/podman#29112](https://github.com/containers/podman/issues/29112) and [containers/podman#29666](https://github.com/containers/podman/issues/29666).

**Fix:**
1. Check current version: `wsl.exe --version`.
2. Update WSL (requires admin/UAC approval — run it yourself in an elevated terminal, an agent/automation cannot click the UAC prompt):
   ```powershell
   wsl --update
   ```
   If a stray "requires elevation" prompt appears in a second/unrelated terminal during the same update, it's a harmless leftover from the update process — check the version instead of trusting that prompt.
3. Confirm the new version is 2.7.5+: `wsl.exe --version`.
4. Restart WSL and the Podman machine so it picks up the new kernel:
   ```bash
   wsl.exe --shutdown
   podman machine start
   ```
5. Retry the failing action (e.g. Run from Podman Desktop UI). It should now succeed.

**Diagnostic tip:** to reproduce the UI's failure mode from the CLI (useful for confirming a fix without opening the UI), explicitly attach to the bridge network:
```bash
podman run --network podman -d --name test <image>
```
If this succeeds but was previously failing with the nftables error, the fix worked.

## References

- https://github.com/containers/podman/issues/29112 — "Podman v6.0.0 default machine does not support rootful" (same nftables error; fixed by WSL 2.7.5+).
- https://github.com/containers/podman/issues/29666 — "Podman on wsl not able to run any container" (same error; root-caused to an outdated pinned WSL kernel).

## Known Issue: build-context overlay mount fails on Windows-mounted paths

**Symptom:**
```
Error: mounting an overlay over build context directory: creating overlay
scaffolding for build context directory: mount overlay:...userxattr: no such
file or directory
```

**Distinguishing detail:** this only affects `podman build` (Buildah overlay-mounts
the *build context* itself). Plain bind-mounts (`-v`) used for `podman run`
work fine on the same path — it is specifically the read-only overlay Buildah
puts over the context directory that fails.

**Root cause:** the Windows checkout is shared into the Podman WSL machine as
a 9p/DrvFs mount (e.g. `/mnt/e/...`). Buildah's context overlay needs
xattr/`d_type` support that 9p/DrvFs does not provide.

**Fix:** don't build with a context path under `/mnt/<drive>/...`. Copy just
the Dockerfile (and whatever it `COPY`s) into the Podman machine's own native
filesystem first, then build from there:
```bash
podman machine ssh podman-machine-default -- "mkdir -p ~/vdx-build/<subpath>"
podman machine ssh podman-machine-default -- \
  "cp '/mnt/e/.../Dockerfile' ~/vdx-build/<subpath>/Dockerfile"
podman machine ssh podman-machine-default -- \
  "cd ~/vdx-build && podman build -t <tag> -f <subpath>/Dockerfile ."
```
Run/exec/curl against the resulting container as usual (either via
`podman machine ssh` or a mapped host port).

