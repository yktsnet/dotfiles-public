# secrets-agents/production-server.md (Dummy Example)

> [!IMPORTANT]
> **secrets-agents/ ディレクトリの運用について**
> このディレクトリ（secrets-agents/）は、本番環境のIP、接続ポート、ユーザー名といった「外部公開を避けるべき設計値」を集約し、AI Agent（Claude Code 等）にローカルで安全に参照させるためのものです。
> **実際の運用では、このディレクトリをプライベートなリポジトリとして独立して管理するか、あるいは `.gitignore` に追加してGitHubなどの外部リモートには絶対にプッシュしない**ように運用します（本リポジトリでは公開サンプルとしてダミーファイルを配置しています）。

---

## SSH / Host Details
- IP: 192.168.1.100 (Dummy)
- Hostname: production.local
- User: dummy-user

## Docker Containers & Ports
- app: http://localhost:8093
- db: 127.0.0.1:3307
- localstack: 127.0.0.1:4567

## Paths
- App Root: /home/dummy-user/apps/kawa-watch
