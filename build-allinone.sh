#!/bin/sh
# ============================================================
# 一键构建 All-in-One 镜像(含朋友圈主题前端 + 后端)
# 用法: sh build-allinone.sh  [镜像名:tag]
# 默认:  mblog-allinone:friends
# ============================================================
set -e
cd "$(dirname "$0")"

IMAGE="${1:-mblog-allinone:friends}"

echo ">>> 构建镜像: $IMAGE"
docker build -f Dockerfile-allinone -t "$IMAGE" .

echo ""
echo ">>> 构建完成!运行方式:"
echo "    # sqlite 版(免数据库,推荐):"
echo "    docker run -d --restart=always --name=mblog-allinone \\"
echo "      -p 38321:38321 -v \$(pwd)/mblog:/opt/mblog \\"
echo "      -e DB_TYPE=-sqlite $IMAGE"
echo ""
echo "    # 访问: http://服务器IP:38321  初始账号 admin/a123456"
