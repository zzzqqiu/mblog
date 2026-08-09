# mBlog (朋友圈主题版)

基于 [mblog-backend](https://github.com/kingwrcy/mblog-backend) / [mblog-front](https://github.com/kingwrcy/mblog-front) 的自部署微博，前端重写为**微信朋友圈风格主题**。

## 目录结构

```
mblog/
├── backend-main/          # Spring Boot 后端 (Java 17 + MySQL/SQLite)
├── mblog-front/           # Vue3 前端 (Vite + NaiveUI + UnoCSS)
│   ├── src/layouts/friends.vue          # 朋友圈布局
│   ├── src/pages/friendsIndex.vue       # 朋友圈首页(时间线分组)
│   └── src/components/themes/           # 朋友圈组件
├── Dockerfile-allinone    # All-in-One 镜像(前端+后端,免数据库)
├── build-allinone.sh      # 一键构建 All-in-One 镜像
├── build-push.sh          # 构建并推送到 Docker Hub
└── maven-settings.xml     # 阿里云 Maven 镜像
```

## 朋友圈主题特性

- 微信朋友圈式封面头图 + 头像 + 签名
- 时间线按天分组(今天/昨天/日期),绿色时间轴
- 动态卡片:头像/昵称/markdown 折叠/九宫格图片
- 点赞 + 评论(回复)面板,深灰底微信风格
- 暗色模式一键切换
- 开发模式无后端时自动展示 mock 数据预览

## Docker 部署

### All-in-One (推荐,含朋友圈主题 + 后端,免数据库)

```bash
docker build -f Dockerfile-allinone -t mblog-allinone:friends .
docker run -d --restart=always --name=mblog \
  -p 38321:38321 -v $(pwd)/mblog:/opt/mblog \
  -e DB_TYPE=-sqlite mblog-allinone:friends
```

访问 `http://服务器IP:38321`，初始账号 `admin/a123456`。

### 前后分离

后端用官方 `kingwrcy/mblog-backend` 镜像，前端用本仓库构建：
```bash
cd mblog-front && npm install && npm run build
# dist/ 部署到 nginx(需配置 SPA fallback)或 CDN
```

## 本地开发

```bash
cd mblog-front
npm install
npm run dev        # http://127.0.0.1:3333
```

> 开发模式自动使用 mock 数据,无需后端即可预览主题效果。

## CI 自动构建 (GitHub Actions)

推送代码到 `main` 后自动构建镜像并推送到 Docker Hub(`.github/workflows/docker-build-push.yml`)。

首次使用需在 GitHub 仓库 **Settings → Secrets and variables → Actions** 添加：

| Secret | 值 |
|--------|----|
| `DOCKERHUB_USERNAME` | withrubia |
| `DOCKERHUB_TOKEN` | Docker Hub Personal Access Token |

之后每次 `git push`，以下镜像自动更新：

- `withrubia/mblog-allinone:friends` (+latest) — 前端含朋友圈主题 + 后端
- `withrubia/mblog-front:friends` (+latest) — 纯前端
