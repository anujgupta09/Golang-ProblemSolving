# Pipeline Design

Implemented in [../../Jenkinsfile](../../Jenkinsfile). Diagram exports: [png](pipeline-flow.png) · [svg](pipeline-flow.svg).

**Trigger:** creating a `release-X.Y.Z` **tag** on GitHub. No GitHub Release needed; a local-only tag doesn't trigger.

## Flow

```mermaid
%%{init: {"flowchart": {"rankSpacing": 34, "nodeSpacing": 28, "htmlLabels": false}}}%%
flowchart TD
    subgraph GITHUB["GitHub - java-maven-sample-app"]
        SOURCE["Java source and pom.xml<br/>Release commit on main"]
        TAG["Push tag release-X.Y.Z<br/>Example: release-1.2.3"]
        SOURCE --> TAG
    end

    subgraph VM["Podman machine - WSL2 VM, rootless engine"]
        NGROK["vdx-ngrok<br/>public tunnel to Jenkins<br/>(demo windows only)"]

        subgraph CONTROLLER["vdx-jenkins - controller, 0 executors"]
            TRIGGER["Generic Webhook Trigger<br/>token OK and ref_type = tag<br/>Start job vdx-release"]
        end

        subgraph WORKER["vdx-worker - Jenkins agent: git, curl, jq, podman client"]
            CONFIG["Load Release Config<br/>config/release.properties"]
            DISCOVER["Discover Release Tag<br/>git ls-remote: highest release-X.Y.Z<br/>check Docker Hub for that tag"]
            SKIP{"No tag, or already<br/>published?"}
            NOTBUILT["NOT_BUILT<br/>nothing to release"]
            CHECKOUT["Checkout Exact Tag<br/>tagged commit + main history"]
            VERIFY["Validate Ancestry and Version<br/>tag is an ancestor of origin/main<br/>POM version = X.Y.Z"]
            VALID{"Release valid?"}
            IMAGE["Build Debian Image<br/>podman --remote build<br/>Debian 13 + JRE 21 + built jar<br/>(built by the host engine)"]
            PUSH["Publish to Registry<br/>login via stdin, push, logout<br/>registry/namespace/app:release-1.2.3"]
            CONFIG --> DISCOVER --> SKIP
            SKIP -->|Yes| NOTBUILT
            SKIP -->|No| CHECKOUT --> VERIFY --> VALID
        end

        subgraph SIBLINGS["Sibling containers - started by the worker on the host engine"]
            COMPILE["Maven container<br/>mvn -B clean verify<br/>compile, test, package"]
            BUILT{"Build passed?"}
            SMOKE["Smoke-test container from the new image<br/>Debian 13, non-root user,<br/>GET /greeting = Hello, World!"]
            READY{"Smoke test passed?"}
            COMPILE --> BUILT
            SMOKE --> READY
        end

        FAIL["FAIL the pipeline<br/>stop downstream stages"]
    end

    TAG -->|"Tag-creation webhook, HTTPS"| NGROK
    NGROK -->|"vdx-ci network"| TRIGGER
    TRIGGER --> CONFIG
    VALID -->|Yes| COMPILE
    BUILT -->|"Yes - jar in shared volume"| IMAGE
    IMAGE --> SMOKE
    READY -->|Yes| PUSH
    VALID -->|No| FAIL
    BUILT -->|No| FAIL
    READY -->|No| FAIL
    PUSH -->|"Push fails"| FAIL
    PUSH -->|"Push succeeds"| REGISTRY[("Docker Hub<br/>anujdocker9799/compvalidator:release-1.2.3")]
    REGISTRY --> DONE["SUCCESS<br/>Release image published"]

    classDef source fill:#eaf3ff,stroke:#2563a6,color:#132d48,stroke-width:1.5px;
    classDef execution fill:#eaf7f4,stroke:#247c70,color:#143e38,stroke-width:1.5px;
    classDef gate fill:#fff5d6,stroke:#a47516,color:#4c3912,stroke-width:1.5px;
    classDef skipped fill:#f1f1f1,stroke:#777,color:#333,stroke-width:1.5px;
    classDef failure fill:#fceced,stroke:#b63c47,color:#6a1820,stroke-width:1.5px;
    classDef success fill:#eaf5e9,stroke:#437d3b,color:#23431f,stroke-width:1.5px;
    class SOURCE,TAG,REGISTRY source;
    class NGROK,TRIGGER,CONFIG,DISCOVER,CHECKOUT,VERIFY,COMPILE,IMAGE,SMOKE,PUSH execution;
    class SKIP,VALID,BUILT,READY gate;
    class NOTBUILT skipped;
    class FAIL failure;
    class DONE success;
    style GITHUB fill:#f7faff,stroke:#9cb6d3
    style VM fill:#fafbfc,stroke:#8a96a3
    style CONTROLLER fill:#ffffff,stroke:#9cb6d3
    style WORKER fill:#ffffff,stroke:#8cb9b2
    style SIBLINGS fill:#ffffff,stroke:#8cb9b2
```

- Grey box = skipped run (`NOT_BUILT`): no unpublished `release-*` tag, or that version is already on Docker Hub. It is a clean outcome, not a failure.
- The worker (`vdx-worker`) runs every pipeline step. Maven and the smoke test run in **sibling containers** it starts on the host engine through the mounted Podman socket; the image build is executed by the host engine itself.
- "Smoke test passed?" = the image is Debian 13, runs as a non-root user and `/greeting` returns `Hello, World!`. All checks are implemented, not optional.
- Any checkout / validation / Maven / build / smoke-test / push error fails the run and skips every later stage.
- Setup and teardown (`one-touch.sh`) are not part of this diagram; see [code-tour.md](code-tour.md).
- Out of scope: production deployment; the endpoint is a published image.

## Requirements → design

| Requirement | Decision |
| --- | --- |
| Code in GitHub | Fetch from the release tag |
| Release from `master` triggers Jenkins | Tag-creation event; tagged commit must be reachable from `origin/main` (the repo's default branch; the brief says `master`) |
| Compile, package only on success | Check out tagged commit → build → gate packaging |
| Binaries in a container | Git, curl, jq in the worker container; JDK and Maven in a disposable sibling container (`maven:3.9.9-eclipse-temurin-17`) |
| Jenkins as container | Controller container (`vdx-jenkins`) and worker container (`vdx-worker`); sibling containers for tooling |
| Debian 13 image | Debian 13 + compatible Java runtime + built artifact |
| Push with same release tag | `registry/namespace/app:release-1.2.3` — keep `release-` prefix |
| Tag `release-1.2.3` = POM version | Validate against effective Maven version before building |

## Design assumptions

- **"From master":** tag must be reachable from the main branch (not necessarily its tip). Always build the tagged SHA, never the latest branch head. The brief says `master`; the app repo's default branch is `main`, so the implementation checks `origin/main` (`ANCESTRY_REF` in `config/release.properties`). The diagram uses `main`.
- **Empty host:** no host-installed Jenkins, Git, JDK, Maven or image client. OS, container runtime, storage, networking are unavoidable.
- **Maven:** read the *effective* POM version (inherited / property-based). `1.2.3` must match `release-1.2.3`; `1.2.3-SNAPSHOT` must **not** become `1.2.3`. Reject mismatches; never edit the POM in a release build.
- **Container boundary:** explicit workspace/artifact handoff. Final image needs the runtime, not Maven or the compile JDK; runtime must support the build's Java target.
- **Tooling:** Java / Maven / Jenkins versions, image builder, registry are implementation choices. No privileged containers and no Docker socket; the one exception is that the worker mounts the host's **rootless Podman socket** to start sibling containers (see [security-notes.md](security-notes.md#rootless-podman-socket)).

## Safeguards

Implemented:
- Webhook supports tag creation; a static token authenticates it; events that are not tags are filtered out. The job never uses the payload's repo or tag: it always reads `APP_REPO_URL` and re-derives the tag itself. No separate GitHub Release trigger.
- `mvn -B clean verify`; image OS, non-root user and `/greeting` are checked before publish; any failing check fails the run.
- Registry credentials in Jenkins credentials only — never committed or baked in. Publish only after all stages pass.
- Base images (Jenkins, agent, Maven, Debian) pinned by digest at setup; duplicate publication prevented by the registry check and `disableConcurrentBuilds`.
- Archived per run: POM version, image ID, smoke-test response, test reports.

Recommended, not implemented (see [security-notes.md](security-notes.md#known-limitations-and-next-steps)): HMAC webhook verification, protected release tags, recording the source SHA and image digest per release.
