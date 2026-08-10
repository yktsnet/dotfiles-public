## PR記録: feat: module-guide に型の判定手順とモジュール境界の切り方を足す
issue: 18 (18_module-guide-judgment.md)
PR: https://github.com/yktsnet/dotfiles-public/pull/50
Merged: 9a04cee415e2cc7abbbc4eb8a348d1e6c4fc377b

## 変更内容
- `docs-agents/module-guide.md` §1 冒頭に、組み込み型／それ以外（後者はさらにツールキット型／研究型）を分岐で決める判定手順と、割れやすいツールキット型／研究型の境目のリトマス試験を追加。表の内容は変更なし
- §1 に「readme-guide.md の Type A/B/C との関係」節（####）を追加。2つの分類が独立ではなく片方が決まればもう片方はおおむね決まること、決める順序（module-guide の型は設計段階で `module-dev` が先に決め、Type A/B/C は動くコードができてから `repo-standardize` が判定する）、食い違った場合の優先順位（構造に反映済みの module-guide 側を優先）を1段落で明記。readme-guide.md 自体は変更していない
- §2 に「境界の切り方」節（###）を追加。ドメイン語彙の見分け方（変数名・型名・設定キーの具体例）、迷ったら固有側に倒す非対称性の根拠、モジュール分割は実装が2つ以上そろってからという目安を記載
- §4「既存リポへのモジュール追加を判断する」を新設。既存リポに足すか新リポを立てるかの分かれ目（配布単位が同じか）、型が合わないモジュールを足したくなった場合の扱い（足さず新リポへ独立させる）を短く記載
- `docs-agents/module-guide.en.md` を上記に合わせて更新（既存の英語版の文体・見出し構成を維持）

## 保証
Issue記載のとおり、なし（ドキュメントのみの変更。実行される処理を持たない。維持する保証もなし。既存テスト `apps/lpt/tests/` は本変更の対象範囲に触れない）

## 静的確認結果
- `nix flake check`: darwinConfigurations.macbook 評価成功（既存の programs.git / programs.ssh 非推奨オプション警告のみ、本変更と無関係）
- 目視確認: 日英の記述内容が一致（各76行、節構成・段落数が対応）。`readme-guide.md` §1 の Type A/B/C・§ の用語（Type A=実証型/Type B=利用保証型/Type C=実験型・Lab）との対応が正しいことを確認。既存3節（型の表・構造のツリーと箇条書き・デモの箇条書き）の記述内容は無変更で、追記のみで矛盾なし
- `git diff --name-only --cached`:
  docs-agents/module-guide.en.md
  docs-agents/module-guide.md

## 検証手順
ドキュメントのみの変更のため実行確認は不要。レビューは `git diff main...claude/18-module-guide-judgment` の目視で完結する。
