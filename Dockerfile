# 指定构建的基础镜像
FROM golang:alpine as builder
# 作者描述信息
LABEL maintainer "danxiaonuo <danxiaonuo@danxiaonuo.me>"
# 语言设置
ENV LANG zh_CN.UTF-8
# 时区设置
ENV TZ=Asia/Shanghai
# CADDY版本号
ENV CADDY_SOURCE_VERSION=v2.1.1
# 修改源
RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g' /etc/apk/repositories
# 更新源
RUN apk upgrade
# 同步时间
RUN apk add -U tzdata \
&& ln -sf /usr/share/zoneinfo/${TZ} /etc/localtime \
&& echo ${TZ} > /etc/timezone
# 安装相关依赖
RUN apk add --no-cache bash gcc musl-dev go openssl openssh-client git ca-certificates mailcap 
# 切换工作目录
WORKDIR /src
# 克隆caddy代码
RUN git clone -b $CADDY_SOURCE_VERSION https://github.com/caddyserver/caddy.git --single-branch
# 切换工作目录
WORKDIR /src/caddy/cmd/caddy
# 获取最新代码
RUN go get -d ./...
# 拷贝编译脚本
COPY caddy-builder.sh /usr/bin/caddy-builder
# 授予脚本权限
RUN chmod +x /usr/bin/caddy-builder
# 切换工作目录
WORKDIR /src/custom-caddy/cmd/caddy
# 编译模块
RUN caddy-builder \
    github.com/abiosoft/caddy-exec \
    github.com/abiosoft/caddy-hmac \
    github.com/abiosoft/caddy-json-parse \
    github.com/abiosoft/caddy-json-schema \
    github.com/abiosoft/caddy-named-routes \
    github.com/abiosoft/caddy-yaml \
    github.com/awoodbeck/caddy-toml-adapter \
    github.com/caddy-dns/cloudflare \
    github.com/caddy-dns/gandi \
    github.com/caddy-dns/route53 \
    github.com/caddyserver/cache-handler \
    github.com/caddyserver/cue-adapter \
    github.com/caddyserver/format-encoder \
    github.com/caddyserver/forwardproxy \
    github.com/caddyserver/json5-adapter \
    github.com/caddyserver/jsonc-adapter \
    github.com/caddyserver/nginx-adapter \
    github.com/caddyserver/ntlm-transport \
    github.com/greenpau/caddy-auth-forms \
    github.com/greenpau/caddy-auth-jwt \
    github.com/greenpau/caddy-auth-saml \
    github.com/hairyhenderson/caddy-teapot-module \
    github.com/hairyhenderson/caddyprom \
    github.com/mholt/caddy-dynamicdns \
    github.com/mholt/caddy-webdav \
    github.com/nwhirschfeld/client_cert_matcher \
    github.com/sjtug/caddy2-filter \
    github.com/vrongmeal/caddygit
	

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
# 安装相关依赖
RUN apk add --no-cache --update ca-certificates asciidoctor libc6-compat libstdc++ pcre bash nodejs nodejs-npm git mailcap openssh-client curl wget

# 安装字体库
RUN apk add --no-cache --update font-adobe-100dpi ttf-dejavu fontconfig && mkdir /usr/share/fonts/win
COPY ./font/. /usr/share/fonts/win/
RUN chmod -R 777 /usr/share/fonts/win && fc-cache -f

# 安装 PWA
RUN npm install workbox-build gulp gulp-uglify readable-stream uglify-es --save-dev && npm update

# 拷贝 caddy 二进制文件至安装目录
COPY --from=builder /usr/bin/caddy /usr/bin/caddy

# 创建相关目录
RUN set -eux; \
	mkdir -p \
		/config/caddy \
		/data/caddy \
		/etc/caddy \
		/usr/share/caddy \
	; \
	wget -O /etc/caddy/Caddyfile "https://raw.githubusercontent.com/caddyserver/dist/master/config/Caddyfile"; \
	wget -O /usr/share/caddy/index.html "https://raw.githubusercontent.com/caddyserver/dist/master/welcome/index.html"

# 设置数据目录环境
ENV XDG_CONFIG_HOME=/config
ENV XDG_DATA_HOME=/data

# 暴露端口
EXPOSE 80 443
# 挂载目录
VOLUME /config /data 

# 工作目录
WORKDIR /data

# 运行caddy
CMD ["caddy", "run", "--config", "/etc/caddy/Caddyfile", "--adapter", "caddyfile"]
