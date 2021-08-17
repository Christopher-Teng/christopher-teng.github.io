FROM node:14.17.5-slim

ARG UID=1000 \
    GID=1000

ENV TINI_VERSION=v0.19.0 \
    PORT=4000

RUN sed -i "s/deb.debian.org/mirrors.tuna.tsinghua.edu.cn/g" /etc/apt/sources.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
    curl \
    && rm -rf /var/lib/apt/lists/*

ADD https://github.com.cnpmjs.org/krallin/tini/releases/download/${TINI_VERSION}/tini /tini

RUN chmod +x /tini

WORKDIR /myblog

RUN npm i -g hexo-cli nrm --registry=http://registry.npm.taobao.org \
    && nrm use taobao	

COPY package*.json ./

RUN npm ci \
 && npm cache clean --force \
 && mv /myblog/node_modules /node_modules

VOLUME /myblog

EXPOSE $PORT

USER $UID:$GID

CMD ["/tini","--","hexo","serve"]
