# CYROID Red Team Lab - Vulnerable CI/CD Dashboard
# Lightweight Python app with command injection (replaces heavy Jenkins)
#
# Credentials:
# - admin:admin (full access)
# - developer:Dev2024! (build access)
#
# Vulnerabilities:
# - Command injection in build script field
# - Weak admin password
# - No CSRF protection
#
# Build: docker build -t cyroid/redteam-jenkins:latest .
# Size: ~60MB (vs ~470MB for real Jenkins)

FROM python:3.12-alpine

RUN apk add --no-cache bash curl netcat-openbsd \
    && pip install --no-cache-dir flask

WORKDIR /app
COPY app.py /app/
COPY templates/ /app/templates/

EXPOSE 8080

CMD ["python", "app.py"]
