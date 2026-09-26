# Runtime image for Task 1. Build tools (Maven/JDK) run only in the separate
# Maven container; this image never compiles source (brief: TASK-1.md in java-maven-sample-app).
# Base pinning: the Jenkinsfile (Build Debian Image) replaces the FROM line below with the
# debian:13-slim digest recorded by jenkins-env.sh prepare. Keep that line exactly as is.
FROM docker.io/library/debian:13-slim

RUN apt-get update \
    && apt-get install --no-install-recommends -y openjdk-21-jre-headless ca-certificates \
    && rm -rf /var/lib/apt/lists/* \
    && useradd --system --create-home --home-dir /app --shell /usr/sbin/nologin appuser

WORKDIR /app
COPY target/rest-service-complete-1.0.0.jar /app/app.jar
RUN chown appuser:appuser /app/app.jar
USER appuser

EXPOSE 8080
ENTRYPOINT ["java", "-jar", "/app/app.jar"]
