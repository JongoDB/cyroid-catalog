# CYROID Red Team Lab - Database Server (MariaDB)
# Lightweight database with weak credentials and sensitive data
#
# Credentials:
# - root:DBr00t2024! (full access)
# - webapp:WebApp123 (wordpress db)
# - backup:Backup2024 (read-only)
#
# Build: docker build -t cyroid/redteam-mysql:latest .
# Size: ~400MB (official MariaDB 10.11)

FROM mariadb:10.11

ENV MARIADB_ROOT_PASSWORD=DBr00t2024!

COPY init/ /docker-entrypoint-initdb.d/

EXPOSE 3306
