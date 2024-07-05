FROM alpine
WORKDIR /ddns
RUN ls && \
    chmod +x namesiloddns-dk.sh && \
    chmod +x entrypoint.sh && \
    sed -i 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g' /etc/apk/repositories && \
    apk update && apk upgrade && \
    apk add --no-cache --upgrade curl grep libxml2-utils bash tzdata proxychains-ng
ENTRYPOINT ["/bin/bash","-c","/ddns/entrypoint.sh"]