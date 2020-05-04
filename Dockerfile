ARG VERSION=alpine
FROM nginx:${VERSION} as builder

ENV VTS_VERSION=0.1.18
ENV VTS_GITREPO=vozlt/nginx-module-vts

# Download sources
RUN wget "http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz" -O nginx.tar.gz && \
    wget "https://github.com/${VTS_GITREPO}/archive/v${VTS_VERSION}.tar.gz" -O extra_module.tar.gz

# For latest build deps, see https://github.com/nginxinc/docker-nginx/blob/master/mainline/alpine/Dockerfile
RUN  apk add --no-cache --virtual .build-deps \
    gcc \
    libc-dev \
    make \
    openssl-dev \
    pcre-dev \
    zlib-dev \
    linux-headers \
    libxslt-dev \
    gd-dev \
    geoip-dev \
    perl-dev \
    libedit-dev \
    mercurial \
    bash \
    alpine-sdk \
    findutils

SHELL ["/bin/ash", "-eo", "pipefail", "-c"]

RUN rm -rf /usr/src/nginx /usr/src/extra_module && mkdir -p /usr/src/nginx /usr/src/extra_module && \
    tar -zxC /usr/src/nginx -f nginx.tar.gz && \
    tar -xzC /usr/src/extra_module -f extra_module.tar.gz

WORKDIR /usr/src/nginx/nginx-${NGINX_VERSION}

# Reuse same cli arguments as the nginx:alpine image used to build
RUN CONFARGS=$(nginx -V 2>&1 | sed -n -e 's/^.*arguments: //p') && \
    sh -c "./configure --with-compat $CONFARGS --add-dynamic-module=/usr/src/extra_module/*" && make modules


# Production container starts here
FROM nginx:${VERSION}

COPY --from=builder /usr/src/nginx/nginx-${NGINX_VERSION}/objs/*_module.so /etc/nginx/modules/

COPY nginx.conf /etc/nginx

# Validate the config
RUN nginx -t
