FROM alpine:3.11.5

ENV NGINX_VERSION 1.16.1-r8

RUN apk add --no-cache --repository http://dl-cdn.alpinelinux.org/alpine/v3.11/main nginx=${NGINX_VERSION} && mkdir -p /run/nginx

EXPOSE 80

COPY *conf /etc/nginx/conf.d/

COPY ./www/ /var/www/

CMD ["nginx", "-g", "daemon off;"]
