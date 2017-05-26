#!/bin/sh
docker exec -it nginxlua_app_1  sh -c "nginx -s reload"
