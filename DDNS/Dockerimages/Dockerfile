FROM alpine
WORKDIR /ddns
COPY /DDNS/Dockerimages/src/ /ddns
ENV DOMAIN=""
ENV HOST=""
ENV APIKEY=""
RUN ls
RUN chmod +x namesiloddns-dk.sh && \
    chmod +x entrypoint.sh && \
    apk update && apk upgrade && \
    apk add --no-cache --upgrade curl grep libxml2-utils bash tzdata proxychains-ng
ENTRYPOINT ["/bin/bash","-c","/ddns/entrypoint.sh"]