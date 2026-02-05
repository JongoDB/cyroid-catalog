# CYROID Red Team Lab - Internal Wiki (Static)
# Contains sensitive internal documentation as static HTML
#
# Build: docker build -t cyroid/redteam-wiki:latest .
# Size: ~25MB (nginx:alpine vs ~200MB for php:apache)

FROM nginx:alpine

COPY html/ /usr/share/nginx/html/

EXPOSE 80
