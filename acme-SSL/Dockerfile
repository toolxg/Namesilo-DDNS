FROM alpine
WORKDIR /acmessl
RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g' /etc/apk/repositories && \
    apk update && apk upgrade && \
    apk add --no-cache -f openssl \
    openssh-client \
    coreutils \
    bind-tools \
    curl \
    sed \
    socat \
    tzdata \
    oath-toolkit-oathtool \
    tar \
    libidn \
    jq \
    cronie
RUN sh -c "$(curl -fsSL https://get.acme.sh)" acme home /acmessl --cert-home /acmessl/certs --config-home /acmessl/data | grep 'Install success!' && /acmessl/acme.sh --uninstall-cronjob

ENTRYPOINT ["/bin/bash","-c","/ddns/entrypoint.sh"]