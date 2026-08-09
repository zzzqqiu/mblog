# ============================================================
# mblog-front 自定义镜像 (含朋友圈主题)
# 构建: docker build -t yourname/mblog-front:friends .
# 运行时通过 MBLOG_SERVER_URL 环境变量注入后端地址
# ============================================================
FROM node:18-alpine as build-stage

ARG VERSION=v1.0.2
WORKDIR /app
RUN corepack enable

# 国内镜像源(淘宝源新域名),加速依赖安装
COPY package.json yarn.lock ./
RUN --mount=type=cache,id=yarn-store,target=/root/.yarn-store \
    yarn install --registry=https://registry.npmmirror.com

# 拷贝全部源码(包含朋友圈主题改动)
COPY . .

# 注入版本号,保留 VITE_BASE_URL=REPLACE_URL_HERE 占位符
# 占位符会在容器启动时由 entrypoint.sh 替换成真实后端地址
RUN sed -i 's#REPLACE_VERSION_HERE#'"$VERSION"'#g' /app/.env.docker

RUN yarn build-only --mode=docker

FROM nginx:stable-alpine as production-stage

COPY --from=build-stage /app/dist /usr/share/nginx/html
COPY --from=build-stage /app/nginx.conf /etc/nginx/conf.d/default.conf

COPY entrypoint.sh /usr/share/nginx

EXPOSE 80

RUN chmod +x /usr/share/nginx/entrypoint.sh

CMD /usr/share/nginx/entrypoint.sh
