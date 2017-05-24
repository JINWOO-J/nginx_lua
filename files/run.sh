#!/bin/bash
export USE_DOCKERIZE=${USE_DOCKERIZE:-"yes"}
export UPSTREAM=${UPSTREAM:-"localhost:9000"}
export DOMAIN=${DOMAIN:-"localhost"}
export LOCATION=${LOCATION:-"#ADD_LOCATION"}
export WEBROOT=${WEBROOT:-"/var/www/public"}
export NGINX_EXTRACONF=${NGINX_EXTRACONF:-""}
export USE_DEFAULT_SERVER=${USE_DEFAULT_SERVER:-"no"}
export USE_DEFAULT_SERVER_CONF=${USE_DEFAULT_SERVER_CONF:-""}

export NUMBER_PROC=${NUMBER_PROC:-$(nproc)}
export SENDFILE=${SENDFILE:-"on"};
export SERVER_TOKENS=${SERVER_TOKENS:-"off"}
export KEEPALIVE_TIMEOUT=${KEEPALIVE_TIMEOUT:-"65"}
export KEEPALIVE_REQUESTS=${KEEPALIVE_REQUESTS:-"15"}
export TCP_NODELAY=${TCP_NODELAY:-"on"}
export TCP_NOPUSH=${TCP_NOPUSH:-"on"}
export CLIENT_BODY_BUFFER_SIZE=${CLIENT_BODY_BUFFER_SIZE:-"3m"}
export CLIENT_HEADER_BUFFER_SIZE=${CLIENT_HEADER_BUFFER_SIZE:-"16k"}
export CLIENT_MAX_BODY_SIZE=${CLIENT_MAX_BODY_SIZE:-"100m"}
export FASTCGI_BUFFER_SIZE=${FASTCGI_BUFFER_SIZE:-"256K"}
export FASTCGI_BUFFERS=${FASTCGI_BUFFERS:-"8192 4k"}
export TYPES_HASH_MAX_SIZE=${TYPES_HASH_MAX_SIZE:-"2048"}

export NGINX_LOG_TYPE=${NGINX_LOG_TYPE:-"default"}  # json or main default
export NGINX_LOG_FORMAT=${NGINX_LOG_FORMAT:-""}

export USE_NGINX_STATUS=${USE_NGINX_STATUS:-"yes"}
export NGINX_STATUS_URI=${NGINX_STATUS_URI:-"nginx_status"}
export NGINX_STATUS_URI_ALLOWIP=${NGINX_STATUS_URI_ALLOWIP:-"127.0.0.1"}

export USE_PHP_STATUS=${USE_PHP_STATUS:-"yes"}
export PHP_STATUS_URI=${PHP_STATUS_URI:-"php_status"}
export PHP_STATUS_URI_ALLOWIP=${PHP_STATUS_URI_ALLOWIP:-"127.0.0.1"}

export NGINX_LOG_OUTPUT=${NGINX_LOG_OUTPUT:-"stdout"}
export USE_NGINX_LUA=${USE_NGINX_LUA:-'yes'}
export UPSTREAM_NAME=${UPSTREAM_NAME:-'_upstreamer'}

export USE_DOCKERGEN=${USE_DOCKERGEN:-'no'}

export NGINX_ALLOW_IP=${NGINX_ALLOW_IP:-""}
export NGINX_DENY_IP=${NGINX_DENY_IP:-""}


RESET='\e[0m'  # RESET
BWHITE='\e[7m';    # backgroud White

IRED='\e[0;91m'         # Rosso
IGREEN='\e[0;92m'       # Verde
RESET='\e[0m'  # RESET

function print_w(){
	printf "${BWHITE} ${1} ${RESET}\n";
}
function print_g(){
	printf "${IGREEN} ${1} ${RESET}\n";
}


if [ $USE_DEFAULT_SERVER = "yes" ]
then
    export USE_DEFAULT_SERVER_CONF="server {listen 80 default_server; server_name _; return 444;}"
else
    if [ $DOMAIN = "localhost" ]
    then
        export DOMAIN="default";
        print_g "default server "${USE_DEFAULT_SERVER}" - ${DOMAIN}"
    fi
fi

if [ $USE_DOCKERIZE == "yes" ];
then
    print_g "USE the dockerize template - ${NGINX_VERSION}"
    dockerize -template /etc/nginx/default.tmpl | grep -ve '^ *$'  > /etc/nginx/sites-available/default
    dockerize -template /etc/nginx/nginx_conf.tmpl |  grep -ve '^ *$' > /etc/nginx/nginx.conf
fi

if [[ $USE_DOCKERGEN == "yes" ]]; then
    if [[ $DOCKER_HOST == unix://* ]]; then
	socket_file=${DOCKER_HOST#unix://}
	if ! [ -S $socket_file ]; then
	cat >&2 <<-EOT
		ERROR: you need to share your Docker host socket with a volume at $socket_file
		Typically you should run your jwilder/nginx-proxy with: \`-v /var/run/docker.sock:$socket_file:ro\`
		See the documentation at http://git.io/vZaGJ
	EOT
	socketMissing=1
	fi
    print_w "USE docker-gen with dynamic upstream  ${NGINX_VERSION}"
    echo 'dockergen: docker-gen -watch -notify "nginx -s reload" /etc/nginx/dockergen_nginx.tmpl  /etc/nginx/sites-available/upstream' > /Procfile
    echo 'nginx: nginx' >> /Procfile
    forego start
    #forego start docker-gen -watch -notify "nginx -s reload" /etc/nginx/dockergen_nginx.tmpl  /etc/nginx/sites-available/upstream &
    fi
else
    print_w "START >> ${NGINX_VERSION}"
    nginx
fi
