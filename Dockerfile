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
ARG plugins="cache,cors,expires,realip,ipfilter,dnspod"
ARG enable_telemetry="false"

RUN go get -v github.com/abiosoft/parent
# 运行编译
RUN VERSION=${version} PLUGINS=${plugins} ENABLE_TELEMETRY=${enable_telemetry} /bin/sh /usr/bin/builder.sh
