FROM node:14.17.5-slim

RUN sed -i "s/deb.debian.org/mirrors.tuna.tsinghua.edu.cn/g" /etc/apt/sources.list \
    && sed -i "s|security.debian.org/debian-security|mirrors.ustc.edu.cn/debian-security|g" /etc/apt/sources.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
    curl \
    && rm -rf /var/lib/apt/lists/*


COPY tini /
RUN chmod a+x /tini

WORKDIR /myblog

RUN npm i -g hexo-cli nrm --registry=http://registry.npm.taobao.org \
    && nrm use taobao	

COPY package*.json ./

RUN npm ci \
 && npm cache clean --force \
 && mv ./node_modules /node_modules

VOLUME /myblog

ENV PORT 4000

EXPOSE 4000

CMD ["/tini", "--", "hexo", "serve"]
