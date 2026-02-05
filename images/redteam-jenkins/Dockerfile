# CYROID Red Team Lab - Vulnerable Jenkins
# Jenkins with Script Console enabled and weak authentication
#
# Credentials:
# - admin:admin (full access)
# - developer:Dev2024! (build access)
#
# Vulnerabilities:
# - Script Console enabled (RCE via Groovy)
# - Weak admin password
# - No CSRF protection
#
# Build: docker build -t cyroid/redteam-jenkins:latest .
# Size: ~470MB (Jenkins base is large but necessary)

FROM jenkins/jenkins:lts-jdk17

USER root

RUN apt-get update && apt-get install -y --no-install-recommends \
        netcat-openbsd \
    && rm -rf /var/lib/apt/lists/*

USER jenkins

ENV JAVA_OPTS="-Djenkins.install.runSetupWizard=false -Dhudson.security.csrf.GlobalCrumbIssuerConfiguration.DISABLE_CSRF_PROTECTION=true"

COPY --chown=jenkins:jenkins jenkins-config/ /usr/share/jenkins/ref/

RUN jenkins-plugin-cli --plugins \
        git \
        workflow-aggregator \
        credentials \
        script-security \
        matrix-auth
