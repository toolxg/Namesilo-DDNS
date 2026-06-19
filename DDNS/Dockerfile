FROM alpine
WORKDIR /ddns
COPY /DDNS/src/ /ddns
ENV LOOPTIME=""
ENV DOMAIN=""
ENV HOST=""
ENV APIKEY=""
ENV TZ=Asia/Shanghai
ENV PROXY=""
ENV LOOPTIME=""
ENV UTO=""
ENV LOG_LEVEL=""
ENV LOG_FILE=""
ENV PROXY_MODEL=0
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
RUN chmod +x namesiloddns-dk.sh && \
    chmod +x entrypoint.sh && \
    apk update && apk upgrade && \
    apk add --no-cache --upgrade curl grep jq bash tzdata
ENTRYPOINT ["/bin/bash","-c","/ddns/entrypoint.sh"]