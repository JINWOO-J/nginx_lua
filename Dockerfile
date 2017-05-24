#
# - Base nginx
#
FROM ubuntu:16.04
MAINTAINER JINWOO <jinwoo@yellotravel.com>
#
# Prepare the container
#
RUN ln -sf /usr/share/zoneinfo/Asia/Seoul /etc/localtime
ARG NGINX_VERSION
ENV NGINX_VERSION $NGINX_VERSION
RUN echo $NGINX_VERSION
ARG DEBUG_BUILD
ENV DEBUG_BUILD $DEBUG_BUILD
ENV DOCKERIZE_VERSION v0.4.0
ENV DOCKER_GEN_VERSION 0.7.3
ENV LUAROCKS_VERSION 2.4.2
ENV LUA_VERSION 5.2
ENV LUA_CPATH "./?.so;/usr/local/lib/lua/5.1/?.so;/usr/local/lib/lua/5.1/loadall.so;/usr/local/lib/lua/5.1/?/?.so;/usr/local/lib/lua/5.1/?.so"
ENV LUA_PATH "/etc/nginx/lua/?.lua;./?.lua;/usr/share/lua/5.1/?.lua;/usr/share/lua/5.1/?/init.lua;/usr/local/lib/lua/5.1/?.lua;/usr/lib64/lua/5.1/?/init.lua;/usr/local/share/lua/5.1/?.lua;/usr/local/share/lua/5.1/?/?.lua"
ENV DOCKER_HOST "unix:///tmp/docker.sock"
ENV NGINX_ADD_MODULE openresty/lua-upstream-nginx-module yaoweibin/nginx_upstream_check_module openresty/lua-nginx-module vozlt/nginx-module-vts

ENV TERM "xterm-256color"
ENV USERID 24988

ENV NGINX_EXTRA_CONFIGURE_ARGS --sbin-path=/usr/sbin \
                                --conf-path=/etc/nginx/nginx.conf \
                                --with-md5=/usr/lib --with-sha1=/usr/lib \
                                --with-http_ssl_module --with-http_dav_module \
                                --without-mail_pop3_module --without-mail_imap_module \
                                --without-mail_smtp_module \
                                --with-http_stub_status_module \
                                --with-http_realip_module



ENV NGINX_BUILD_DEPS bzip2 \
        file \
        openssl \
        curl \
        libc6 \
        libpcre3 \
        tmux \
        runit \
        libreadline6-dev \
        unzip \
        vim \
        ca-certificates \
        git \
        lua5.1 \
        liblua5.1-dev

ENV NGINX_EXTRA_BUILD_DEPS gcc make pkg-config  \
                            libbz2-dev \
                            libpcre3-dev \
                            libc-dev \
                            libcurl4-openssl-dev \
                            libmcrypt-dev \
                            libssl-dev \
                            libxslt1-dev \
                            libxml2-dev \
                            autoconf \
                            libxml2 \
                            wget \
                            patch \
                            unzip nano less

RUN sed -i 's/archive.ubuntu.com/ftp.daum.net/g' /etc/apt/sources.list

RUN userdel www-data && groupadd -r www-data -g ${USERID} && \
    mkdir /home/www-data && \
    mkdir -p /var/www && \
    useradd -u ${USERID} -r -g www-data -d /home/www-data -s /sbin/nologin -c "Docker image user for web application" www-data && \
    chown -R www-data:www-data /home/www-data /var/www && \
    chmod 700 /home/www-data && \
    chmod 711 /var/www && \
	mkdir -p /etc/nginx/conf.d/

COPY files /

RUN bash -c "/usr/src/compile.sh"

RUN curl -SL --silent -f -O https://github.com/jwilder/docker-gen/releases/download/$DOCKER_GEN_VERSION/docker-gen-linux-amd64-$DOCKER_GEN_VERSION.tar.gz \
 && tar -C /usr/local/bin -xvzf docker-gen-linux-amd64-$DOCKER_GEN_VERSION.tar.gz \
 && rm /docker-gen-linux-amd64-$DOCKER_GEN_VERSION.tar.gz

# Install Forego
ADD https://github.com/jwilder/forego/releases/download/v0.16.1/forego /usr/local/bin/forego
RUN chmod u+x /usr/local/bin/forego

VOLUME [ "/var/www" , "/var/log/nginx" ]

EXPOSE 443
EXPOSE 80

CMD ["/run.sh"]
