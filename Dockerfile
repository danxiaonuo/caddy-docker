# 指定构建的基础镜像
FROM golang:1.13-alpine as builder
# 修改源
RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g' /etc/apk/repositories
# 更新源
RUN apk upgrade
# 安装相关依赖包
RUN apk add --no-cache git gcc musl-dev
# 拷贝编译脚本
COPY builder.sh /usr/bin/builder.sh
# 指定版本
ARG version="v2.0.0"
# 指定编译插件
ARG plugins="git,cache,cors,expires,realip,ipfilter,cloudflare,dnspod"
ARG enable_telemetry="true"

RUN go get -v github.com/abiosoft/parent
# 运行编译
RUN VERSION=${version} PLUGINS=${plugins} ENABLE_TELEMETRY=${enable_telemetry} /bin/sh /usr/bin/builder.sh

# 指定创建的基础镜像
FROM alpine:latest
# 作者描述信息
MAINTAINER danxiaonuo
# 语言设置
ENV LANG zh_CN.UTF-8
# 时区设置
ENV TZ=Asia/Shanghai
# 修改源
RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g' /etc/apk/repositories
# 更新源
RUN apk upgrade
# 同步时间
RUN apk add -U tzdata \
&& ln -sf /usr/share/zoneinfo/${TZ} /etc/localtime \
&& echo ${TZ} > /etc/timezone

LABEL maintainer "danxiaonuo <danxiaonuo@danxiaonuo.me>"

ARG version="2.0.0"
LABEL caddy_version="$version"

# Let's Encrypt Agreement
ENV ACME_AGREE="false"

# Telemetry Stats
ENV ENABLE_TELEMETRY="$enable_telemetry"

RUN apk add --no-cache \
    ca-certificates \
    git \
    mailcap \
    openssh-client \
    tzdata

# 拷贝 caddy 二进制文件至安装目录
COPY --from=builder /install/caddy /usr/bin/caddy

# validate install
RUN /usr/bin/caddy -version
RUN /usr/bin/caddy -plugins

EXPOSE 80 443 2019
VOLUME /root/.caddy /srv
WORKDIR /srv

COPY Caddyfile /etc/Caddyfile
COPY index.html /srv/index.html

# install process wrapper
COPY --from=builder /go/bin/parent /bin/parent

ENTRYPOINT ["/bin/parent", "caddy"]
CMD ["--conf", "/etc/Caddyfile", "--log", "stdout", "--agree=$ACME_AGREE"]
