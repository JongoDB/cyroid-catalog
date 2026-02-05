# CYROID Red Team Lab - Database Server (MariaDB)
# Lightweight database with weak credentials and sensitive data
#
# Credentials:
# - root:DBr00t2024! (full access)
# - webapp:WebApp123 (wordpress db)
# - backup:Backup2024 (read-only)
#
# Build: docker build -t cyroid/redteam-mysql:latest .
# Size: ~150MB (vs ~550MB for mysql:8.0)

FROM mariadb:10-alpine

ENV MARIADB_ROOT_PASSWORD=DBr00t2024!

COPY init/ /docker-entrypoint-initdb.d/

EXPOSE 3306
