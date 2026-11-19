# paas-wrapper-template

把一个上游服务镜像包一层 Caddy，变成单端口部署，跑在只暴露一个 HTTP 端口的免费 PaaS 上（比如 blitz.cloud）。仓库里零密钥，密钥只放在平台的环境变量里。

## 它解决什么

很多免费 PaaS（blitz.cloud）只暴露一个 HTTP 端口，但服务本身要占两个端口（比如 Magpie 的 API 网关 3425 + Web UI 3430）。这个模板用 Caddy 做反向代理，把两个端口合成一个 8080 对外，API 路径用环境变量里的密钥鉴权，Web UI 直接放行。

Caddy 代替 Nginx 的关键好处：Caddyfile 原生读 `{$环境变量}`，密钥不用写进仓库文件，仓库公开也没事。原来用 Nginx 的做法得把密钥写死在 nginx.conf 里，那个仓库只能私有。

## 快速开始

1. 在 GitHub 上点 **Use this template** 建一个新仓库（或直接 fork）。
2. 按下面改三处（默认是 Magpie 的配置，开箱即用）：
   - `Dockerfile` 里的 `UPSTREAM_IMAGE` 和 `SERVICE_BIN`（要包的上游镜像和二进制路径）
   - `Caddyfile` 里的两个端口（API 端口和 Web UI 端口）和需要鉴权的路径前缀
   - `entrypoint.sh` 里的启动命令
3. 在部署平台（blitz.cloud）上连这个仓库，并设置环境变量（见下）。
4. 部署，完事。

## 环境变量（在平台上设置，不要写进仓库）

| 变量 | 说明 |
| --- | --- |
| `API_KEY` | 客户端访问 API 路由时要带的 Bearer 令牌。Caddy 用它鉴权，仓库里不存。 |
| （服务的其他变量） | 比如 Magpie 的 `MAGPIE_WEB_KEY`、`MAGPIE_PUBLIC_URL`，按服务需要加。 |

## 密钥管理

仓库里不放任何密钥。所有密钥只放在两处：

- 平台的环境变量（部署时用）
- Bitwarden 免费版的 Cloud-Services 文件夹，每服务一条记录，备注里存标准 `.env` 文本块（格式见 `.env.example`），迁移时复制粘贴

## 自动更新

`.github/workflows/auto-update.yml` 每天 03:00 UTC 查一次上游镜像的 SHA256 摘要，变了才提交 `.upstream-digest` 触发重建，没变就什么都不做，不会空烧 blitz.cloud 每月 300 分钟的构建额度。

注意：blitz.cloud 默认不构建机器人 / GitHub Actions 的推送。两种办法：

- 在 blitz.cloud 应用设置里开启“允许工作流触发的构建”，或
- 把工作流改成用你自己的 GitHub PAT 推送。

24/7 的 VPS（比如以后抢到的 weeny.cloud）不用这个，改用 Docker Compose + Watchtower（`--label-enable --interval 86400`，服务加 `com.centurylinklabs.watchtower.enable=true` 标签）。

## 单端口服务不用这个模板

如果服务本身只占一个端口，直接在 blitz.cloud 点 Deploy Docker image，或先查它的 App Store（119 个现成应用），不用建仓库。

## 目录

- `Dockerfile` — 基于 debian:bookworm-slim，装 Caddy +（可选）Python 3，从上游镜像拷二进制。
- `Caddyfile` — 单端口反向代理，API 路径用 `{$API_KEY}` 鉴权。
- `entrypoint.sh` — 后台起服务，前台跑 Caddy。
- `.github/workflows/auto-update.yml` — 每天查上游镜像摘要，变了才提交重建。
- `.upstream-digest` — 上次记录的上游镜像摘要，由工作流维护。
- `.env.example` — 环境变量的格式示例（不含真实值）。
