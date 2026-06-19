FROM alpine
WORKDIR /ddns
COPY /DDNS/Dockerimages/src/ /ddns
ENV DOMAIN=""
ENV HOST=""
ENV APIKEY=""
ENV TZ=Asia/Shanghai
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
RUN chmod +x namesiloddns-dk.sh && \
    chmod +x entrypoint.sh && \
    apk update && apk upgrade && \
    apk add --no-cache --upgrade curl grep libxml2-utils bash tzdata proxychains-ng
ENTRYPOINT ["/bin/bash","-c","/ddns/entrypoint.sh"]