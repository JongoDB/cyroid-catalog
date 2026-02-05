# CYROID Red Team Lab - MySQL Database
# Database server with weak credentials and sensitive data
#
# Credentials:
# - root:DBr00t2024! (full access)
# - webapp:WebApp123 (wordpress db)
# - backup:Backup2024 (read-only)
#
# Build: docker build -t cyroid/redteam-mysql:latest .

FROM mysql:8.0

# Environment for initial setup
ENV MYSQL_ROOT_PASSWORD=DBr00t2024!

# Copy initialization scripts
COPY init/ /docker-entrypoint-initdb.d/

EXPOSE 3306
