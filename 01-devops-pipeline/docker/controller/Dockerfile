# One Touch controller image: bakes in the Jenkins plugins
# in section 3 and a Configuration as Code file that seeds the admin user,
# executor count and security settings the wizard used to set by hand. See
# ../README.md.
ARG CONTROLLER_IMAGE
FROM ${CONTROLLER_IMAGE}

COPY plugins.txt /usr/share/jenkins/ref/plugins.txt
RUN jenkins-plugin-cli --plugin-file /usr/share/jenkins/ref/plugins.txt

COPY casc/jenkins.yaml /usr/share/jenkins/ref/casc_configs/jenkins.yaml

ENV JAVA_OPTS="-Djenkins.install.runSetupWizard=false" \
    CASC_JENKINS_CONFIG="/usr/share/jenkins/ref/casc_configs/jenkins.yaml"
