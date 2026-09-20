FROM alpine:3.20 AS dev-env

RUN apk add --no-cache \
    build-base \
    coreutils \
    curl \
    git \
    unzip \
    readline-dev \
    linux-headers \
    libpcre32 \
    pcre-dev \
    openssl-dev \
    zlib-dev \
    nginx

RUN cd /tmp && \
    curl -R -O https://lua.org && \
    tar zxf lua-5.5.1.tar.gz && \
    cd lua-5.5.1 && \
    make linux-readline && \
    make install

RUN cd /tmp && \
    git clone https://github.com && \
    cd luarocks && \
    ./configure --with-lua-interpreter=lua --with-lua-version=5.5 && \
    make && \
    make install
    
RUN luarocks install pallene

RUN luarocks install lua-nginx-module

WORKDIR /app

# Comando padrão para manter o container de dev rodando em modo interativo
CMD ["/bin/sh"]
