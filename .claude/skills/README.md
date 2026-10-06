# skills

このリポジトリは、稼働中の dotfiles から公開する分だけを抜き出したものである。写像ではないので、稼働側にあって公開側に無いことは欠陥ではない。

## 一覧

基準と手順は、それを使う skill が持つ。独立したガイドの MD は置かず、skill に寄せきれないもの（複数の skill が読む `repo-standardize/reference/cicd.md`、フックの書き方の `../hooks/README.md`）だけを MD として残す。

| 領域 | skill | 持つもの |
|---|---|---|
| 型の判定 | [repo-standardize](repo-standardize/SKILL.md) | リポ類型と検証手段・settings.json・CLAUDE.md と context/・ファイル衛生。CI/CD は [reference/cicd.md](repo-standardize/reference/cicd.md) |
| | [repo-readme](repo-readme/SKILL.md) | README の種別判定（Type A / B / C）・下限・コアメッセージ・アウトライン |
| | [module-dev](module-dev/SKILL.md) | モジュール型リポの型・境界・デモ |
| | [mermaid-diagram](mermaid-diagram/SKILL.md) | 図を描くかの判断・幅の制約・形と線種 |
| 知識の置き場 | [skill-dev](skill-dev/SKILL.md) | 置き場の基準・自動発火の絞り方・探索の分け方 |
| | [consolidate-rules](consolidate-rules/SKILL.md) | 規則同士の矛盾・陳腐化の棚卸し |
| 保証 | [guarantee-audit](guarantee-audit/SKILL.md) | テスト方針（GDD）・保証台帳の敷設と棚卸し |
| | [mvp-docs](mvp-docs/SKILL.md) | 立ち上げ期の PLAN.md / JUDGE.md |
| 分業 | [local-issue](local-issue/SKILL.md) | フェーズ・担当分離・例外の3経路・Issue の設計 |
| | [pr-workflow](pr-workflow/SKILL.md) | 実行者の実装からローカルコミットまで |
| | [session-nudge](session-nudge/SKILL.md) | 別セッションを外から客観視する相談 |
| 公開 | [readme-i18n](readme-i18n/SKILL.md)・[repo-publish](repo-publish/SKILL.md)・[repo-about](repo-about/SKILL.md) | 英語版 README・公開手続き・About と topics |
| 前提 | [nix-tool-install](nix-tool-install/SKILL.md)・[sops-secrets](sops-secrets/SKILL.md)・[jp-writing](jp-writing/SKILL.md) | Nix 経由の導入・機密の暗号化・日本語の文章規範 |

## 公開の基準

稼働側の skill（と、それを動かす hooks・zsh・home-manager モジュール）を公開側に置くのは、次の3問に全て「はい」と答えられるときだけ。

1. **README のどの節の主張を裏付けるか言えるか。** 便利だから、よくできているから、は理由にならない
2. **稼働環境の実体が無くても読めるか。** 実機・実データ・本番パス・個人の設定を外しても、それ単体で意味が追えるか
3. **稼働側が変わるたびに追いかける手間に見合うか。** 公開した時点から、稼働側の変更に合わせる保守が恒久的に発生する

公開する skill は、ホスト名・固有のパス・会社の事情を一般化してから置く。

## 点検のしかた

skill を足したり外したりするときは、公開側の各 skill を上の3問に当てはめ、落ちたものを外す。残すものは稼働側と中身がずれていないかを見て、ずれていれば稼働側に合わせる（公開側で直したものは稼働側へ戻す）。候補を探すために稼働側を全部見て回ることはしない。
