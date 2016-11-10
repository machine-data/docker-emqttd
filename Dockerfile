## -*- docker-image-name: "crate-emqttd" -*-
#
# Crate Dockerfile
# https://github.com/crate/docker-crate
#

FROM alpine:3.4
MAINTAINER Crate.IO GmbH office@crate.io

ENV GOSU_VERSION 1.9
ENV OTP_VERSION OTP-19.1


# Install GOSU
RUN set -x \
    && apk add --no-cache --virtual .gosu-deps \
        dpkg \
        gnupg \
        curl \
    && export ARCH=$(echo $(dpkg --print-architecture) | cut -d"-" -f3) \
    && curl -o /usr/local/bin/gosu -fSL "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$ARCH" \
    && curl -o /usr/local/bin/gosu.asc -fSL "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$ARCH.asc" \
    && export GNUPGHOME="$(mktemp -d)" \
    && gpg --keyserver ha.pool.sks-keyservers.net --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 \
    && gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu \
    && rm -r "$GNUPGHOME" /usr/local/bin/gosu.asc \
    && chmod +x /usr/local/bin/gosu \
    && gosu nobody true \
    && apk del .gosu-deps

RUN apk add --no-cache --virtual .erl-rundeps \
        openjdk8 \
        ncurses-dev \
        perl-dev \
        git \
        openssl-dev \
        zlib-dev \
        autoconf \
        build-base \
    #&& apk add --no-cache --virtual .erl-build-deps \
    && export PATH="/usr/lib/jvm/java-1.8-openjdk/bin:$PATH" \
    && git clone https://github.com/erlang/otp.git \
    && cd otp \
    && /usr/bin/git checkout $OTP_VERSION \
    && export ERL_TOP=$PWD \
    && export PATH=$ERL_TOP/bin:$PATH \
    && export CPPFLAGS="-D_BSD_SOURCE $CPPFLAGS" \
    && ./otp_build autoconf \
    && ./configure \
    && make \
    && make install
#&& apk del .erl-build-deps

RUN apk add --no-cache --virtual .emqtt-builddeps \
        git \
        autoconf \
        build-base \
    && git clone https://github.com/emqtt/emqttd-relx.git \
    && cd emqttd-relx && make \
    && cd _rel/emqttd

RUN addgroup emqttd && adduser -G emqttd -H emqttd -D



CMD /emqttd-relx/_rel/emqttd/bin/emqttd console