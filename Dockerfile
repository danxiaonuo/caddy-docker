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
# 获取进程文件
RUN go get -v github.com/abiosoft/parent
# 运行编译
RUN VERSION=${version} PLUGINS=${plugins} ENABLE_TELEMETRY=${enable_telemetry} /bin/sh /usr/bin/builder.sh

# 指定创建的基础镜像
FROM alpine:latest
# 作者描述信息
LABEL maintainer "danxiaonuo <danxiaonuo@danxiaonuo.me>"
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

# 指定版本号
ARG version="2.0.0"
LABEL caddy_version="$version"

# 自动申请Let's Encrypt证书
ENV ACME_AGREE="true"

# Telemetry Stats
ENV ENABLE_TELEMETRY="$enable_telemetry"

# 安装相关依赖
RUN apk add --no-cache ca-certificates mailcap

# 拷贝 caddy 二进制文件至安装目录
COPY --from=builder /install/caddy /usr/bin/caddy

# 验证安装
RUN /usr/bin/caddy -version
RUN /usr/bin/caddy -plugins

# 暴露端口
EXPOSE 80 443 2019
# 挂载目录
VOLUME /root/.caddy /srv
# 工作目录
WORKDIR /srv

拷贝相关文件
COPY Caddyfile /etc/Caddyfile
COPY index.html /srv/index.html

# 安装进程文件
COPY --from=builder /go/bin/parent /bin/parent

# 运行caddy
ENTRYPOINT ["/bin/parent", "caddy"]
CMD ["--conf", "/etc/Caddyfile", "--log", "stdout", "--agree=$ACME_AGREE"]
