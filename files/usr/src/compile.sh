#!/bin/bash

function print_w(){
	RESET='\e[0m'  # RESET
	BWhite='\e[7m';    # backgroud White
	printf "${BWhite} ${1} ${RESET}\n";
}

function PrintOK() {
    IRed='\e[0;91m'         # Rosso
    IGreen='\e[0;92m'       # Verde
    RESET='\e[0m'  # RESET
    MSG=${1}
    CHECK=${2:-0}

    if [ ${CHECK} == 0 ];
    then
        printf "${IGreen} [OK] ${CHECK}  ${MSG} ${RESET} \n"
    else
        printf "${IRed} [FAIL] ${CHECK}  ${MSG} ${RESET} \n"
        printf "${IRed} [FAIL] Stopped script ${RESET} \n"
        exit 0;
    fi
}
DEBUG_BUILD=${DEBUG_BUILD:-"no"}
if [ $DEBUG_BUILD == "yes" ];
then
    set -x
fi

print_w "NGINX_VERSION = ${NGINX_VERSION} \n";
apt-get update > /dev/null
PrintOK "apt-get update" $?
apt-get install -y $NGINX_BUILD_DEPS $NGINX_EXTRA_BUILD_DEPS --no-install-recommends > /dev/null
PrintOK "apt-get install" $?

rm -rf /var/lib/apt/lists/*
gpg --keyserver pgpkeys.mit.edu --recv-key A1C052F8 > /dev/null 2>&1
PrintOK "import to gpg keyserver [pgpkeys.mit.edu]" $?
mkdir -p /var/log/nginx
mkdir -p /usr/src/nginx
#set -x
cd /usr/src/nginx

curl -SL --silent -f "http://nginx.org/download/${NGINX_VERSION}.tar.gz" -o nginx.tar.bz2
PrintOK "Download ${NGINX_VERSION}.tar.gz" $?
curl -SL --silent -f "http://nginx.org/download/${NGINX_VERSION}.tar.gz.asc" -o nginx.tar.bz2.asc
PrintOK "Download ${NGINX_VERSION}.tar.gz.asc" $?

gpg --verify nginx.tar.bz2.asc > /dev/null 2>&1
PrintOK "gpg --verify nginx.tar.bz2.asc" $?

mkdir -p /usr/src/nginx
tar -xof nginx.tar.bz2 -C /usr/src/nginx --strip-components=1

PrintOK "extract source code from nginx.tar.bz2 " $?
## ADD Lua

curl -SL --silent -f -O http://luarocks.org/releases/luarocks-${LUAROCKS_VERSION}.tar.gz
PrintOK "extract source code from luarocks-${LUAROCKS_VERSION}.tar.gz " $?
tar zxf luarocks-${LUAROCKS_VERSION}.tar.gz
cd luarocks-${LUAROCKS_VERSION}
./configure > /dev/null
PrintOK "./configure luarocks-${LUAROCKS_VERSION} install " $?
make bootstrap -s
PrintOK "make luarocks-${LUAROCKS_VERSION} install " $?
ln -sf /usr/local/lib/luarocks/rocks /usr/share/lua5.1

# lua-ffi-zlib lua-resty-upstream

luarocks install https://raw.github.com/diegonehab/luasocket/master/luasocket-scm-0.rockspec > /dev/null
PrintOK "lua module install - luasocket " $?
luarocks install lua-cjson  > /dev/null
PrintOK "lua module install - lua-cjson " $?
luarocks install json2lua > /dev/null
PrintOK "lua module install - json2lua " $?

git clone --quiet https://github.com/jmckaskill/luaffi
cd luaffi
sed -i 's/lua5\.2/lua5\.1/g' Makefile
make -j4 -s > /dev/null 2>&1
cp ffi.so /usr/local/lib/lua/5.1/
PrintOK "copy ffi.so to /usr/local/lib/lua/5.1/ " $?

cd /usr/src/nginx

#NGINX_ADD_MODULE_ARR=("openresty/lua-upstream-nginx-module", "yaoweibin/nginx_upstream_check_module","openresty/lua-nginx-module", "vozlt/nginx-module-vts")
if [ ${#NGINX_ADD_MODULE} > 0 ]; then
    for module in $NGINX_ADD_MODULE
    do
        git clone --quiet https://github.com/${module}
        PrintOK "git clone https://github.com/${module} " $?
        MODULE_NAME=$(basename $module)
        ADD_MODULE_OPTION="${ADD_MODULE_OPTION} --add-module=${MODULE_NAME}"
    done
else
    ADD_MODULE_OPTION=""
fi

# git clone --quiet https://github.com/openresty/lua-upstream-nginx-module
# git clone --quiet https://github.com/yaoweibin/nginx_upstream_check_module
# git clone --quiet https://github.com/openresty/lua-nginx-module
# git clone --quiet https://github.com/simpl/ngx_devel_kit
# git clone --quiet https://github.com/yzprofile/ngx_http_dyups_module
# git clone --quiet https://github.com/iZephyr/nginx-http-touch

patch -p 0 < nginx_upstream_check_module/check_1.9.2+.patch
PrintOK "Patch nginx_upstream_check_module " $?

./configure ${NGINX_EXTRA_CONFIGURE_ARGS} ${ADD_MODULE_OPTION} > /dev/null

# ./configure ${NGINX_EXTRA_CONFIGURE_ARGS} \
#             --add-module=nginx-module-vts \
#             --add-module=nginx_upstream_check_module \
#             --add-module=lua-nginx-module \
#             --add-module=lua-upstream-nginx-module > /dev/null

PrintOK "nginx - configure" $?
make -j"$(nproc)" -s > /dev/null 2>&1
PrintOK "make" $?
make install -s
PrintOK "nginx - make install" $?
#find /usr/local/bin /usr/local/sbin -type f -executable -exec strip --strip-all '{}' \;
make clean -s
PrintOK "nginx - make clean" $?
curl -SL --silent -f -O https://github.com/jwilder/dockerize/releases/download/$DOCKERIZE_VERSION/dockerize-linux-amd64-$DOCKERIZE_VERSION.tar.gz
PrintOK "Download dockerize-linux-amd64-$DOCKERIZE_VERSION.tar.gz" $?
tar -C /usr/local/bin -xzf dockerize-linux-amd64-$DOCKERIZE_VERSION.tar.gz
rm -f dockerize-linux-amd64-$DOCKERIZE_VERSION.tar.gz
cd ..

if [ $DEBUG_BUILD == "yes" ];then
    print_w "Keep source file and compiled file"
else
    rm -rf /usr/src/nginx
    apt-get purge --yes --auto-remove -o APT::AutoRemove::RecommendsImportant=false -o APT::AutoRemove::SuggestsImportant=false $NGINX_EXTRA_BUILD_DEPS > /dev/null
    PrintOK "Clean up apt package file and source file" $?
fi
