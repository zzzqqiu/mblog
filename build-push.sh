#!/bin/sh
# ============================================================
# 构建并推送到 Docker Hub
# 用法:
#   export DOCKERHUB_TOKEN=dckr_pat_xxx   (或交互输入)
#   sh build-push.sh
#
# 会推送两个镜像:
#   withrubia/mblog-allinone:friends    (All-in-One,前端含朋友圈主题+后端)
#   withrubia/mblog-front:friends       (纯前端)
# ============================================================
set -e
cd "$(dirname "$0")"

USERNAME="withrubia"
VERSION="friends"

# 1. 登录
if [ -z "$DOCKERHUB_TOKEN" ]; then
  echo "请输入 Docker Hub PAT:"
  read -rs DOCKERHUB_TOKEN
  echo ""
fi
echo ">>> 登录 Docker Hub ($USERNAME) ..."
echo "$DOCKERHUB_TOKEN" | docker login -u "$USERNAME" --password-stdin

# 2. 构建 All-in-One 镜像
echo ">>> 构建 $USERNAME/mblog-allinone:$VERSION ..."
docker build -f Dockerfile-allinone \
  -t "$USERNAME/mblog-allinone:$VERSION" \
  -t "$USERNAME/mblog-allinone:latest" .

# 3. 构建纯前端镜像
echo ">>> 构建 $USERNAME/mblog-front:$VERSION ..."
docker build -f mblog-front/Dockerfile \
  -t "$USERNAME/mblog-front:$VERSION" \
  -t "$USERNAME/mblog-front:latest" \
  mblog-front/

# 4. 推送
echo ">>> 推送中 ..."
docker push "$USERNAME/mblog-allinone:$VERSION"
docker push "$USERNAME/mblog-allinone:latest"
docker push "$USERNAME/mblog-front:$VERSION"
docker push "$USERNAME/mblog-front:latest"

echo ""
echo ">>> 全部完成!"
echo "    docker pull $USERNAME/mblog-allinone:$VERSION"
