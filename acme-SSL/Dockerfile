FROM alpine
LABEL mail="mail@toolxg.com"
WORKDIR /acmessl
RUN apk update && apk upgrade
RUN apk add --no-cache -f openssl \
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
RUN curl -O https://raw.githubusercontent.com/toolxg/Namesilo-DDNS-SSL/master/acme-SSL/entrypoint.sh && chmod +x entrypoint.sh

ENTRYPOINT ["/bin/sh","-c","/ddns/entrypoint.sh"]