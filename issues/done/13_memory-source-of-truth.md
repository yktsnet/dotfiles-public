## PR記録: feat: 永続メモリの正本管理（memory.nix）を公開する
issue: 13 (13_memory-source-of-truth.md)
PR: https://github.com/yktsnet/dotfiles-public/pull/40
Merged: f930fe5da8186c1ed48ac8e30b4d4dd345ff4ccc

## 変更内容
- `home-manager/modules/memory.nix` を新規追加。`home.activation` の `entryAfter [ "writeBoundary" ]` で `~/memory` を dotfiles 配下の実体 `memory/` へのシンボリックリンクとして張る。`home.file` ではなく activation script なのは、既存実体・既存リンクとの衝突で activation 全体が落ちるのを避けるため（`claude.nix` と同じ理由、コメントに残した）。
- 分岐は4通り（実体が無い / すでに symlink / 実体が存在 / 何も無い）。「実体が存在する」ケースでは削除も上書きもせず、退避を促すメッセージを標準エラーへ出して activation を継続する。
- 私物版から移植するにあたり警告文2つのうち「実体が無い場合」の文言を公開向けに書き換え（「dotfiles を pull してから再実行すること」→「`memory/` を作るか、この module を imports から外すこと」）。「実体が存在する場合」の文言はそのまま維持。
- `devices/gui/macbook/home.nix` / `devices/gui/home.nix` の imports に `memory.nix` を追加（`claude.nix` の直後、`claude.nix` がある2箇所のみ。`devices/headless/home.nix` には追加しない）。
- `.gitignore` に `memory/` を追加し、user 個人の事実である実体が誤ってコミットされないようにする。
- `docs-agents/harness-guide.md` / `harness-guide.en.md` の 4.5 永続メモリ節に、正本の説明直後（索引の生成物である旨の前）へ1段落追加。`~/memory` が symlink であること・`memory.nix` の activation script が張ること・フック類は `$HOME/memory` 参照のまま変更不要であることを記載。日英で内容を一致させた。

## 保証
- `~/memory` が存在しないとき、dotfiles 配下の実体への symlink を新規作成する → `home-manager/modules/memory.nix` の `else` 分岐（`ln -s "$src" "$dst"`）で担保。テスト無し（裁可済み、Issue 参照）
- `~/memory` が既に symlink のとき、リンク先を dotfiles 配下の実体へ張り替える → `elif [ -L "$dst" ]` 分岐（`ln -sfn "$src" "$dst"`）で担保。テスト無し（裁可済み）
- `~/memory` が実体のディレクトリとして存在するとき、何も削除せず・上書きせず、退避を促すメッセージを標準エラーへ出して activation を継続する → `elif [ -e "$dst" ]` 分岐（`echo ... >&2` のみで `ln` を呼ばない）で担保。分岐を `ln -sfn` に一本化していないことをコード上維持。テスト無し（裁可済み、実装時に一本化しないことを明記）
- dotfiles 配下に実体が無いとき、警告を出して activation を継続する（activation 全体を失敗させない） → `if [ ! -d "$src" ]` 分岐（`echo ... >&2` のみで `exit` しない）で担保。テスト無し（裁可済み）
- `sync-memory-index.sh` / `block-project-scoped-memory.sh` の挙動、既存 home-manager モジュールの activation 順序 → 両フックのファイル・既存モジュールを一切変更していないため維持

なし（理由）: `nix flake check` は評価エラーの検出までで activation の実行時分岐を検証できず、activation を対象にした妥当なテスト手段が本リポに無いため。Issue内で裁可済み。

## 静的確認結果
- `nix flake check`: darwinConfigurations.macbook 評価成功（既存の programs.git / programs.ssh 非推奨警告のみ、本変更と無関係）。x86_64-linux は未評価環境のため対象外表示。
- 目視確認: `harness-guide.md` 4.5節の追加段落と `memory.nix` の実装（symlink・activation script・既存実体を壊さず退避を促す）が一致することを確認。`harness-guide.md` と `harness-guide.en.md` の追加段落の内容（symlink である旨・張る主体・フックは参照先変更不要な旨）が一致することを確認。
- caller/import整合性: `claude.nix` を imports している `devices/gui/macbook/home.nix` と `devices/gui/home.nix` のみに `memory.nix` を追加し、`claude.nix` が無い `devices/headless/home.nix` には追加していないことを確認。

git diff --name-only --cached:
.gitignore
devices/gui/home.nix
devices/gui/macbook/home.nix
docs-agents/harness-guide.en.md
docs-agents/harness-guide.md
home-manager/modules/memory.nix

## 検証手順
実 symlink 生成の確認は Agent 側では完結しない。user が macbook（`darwin-rebuild switch`）または linux-desktop（`home-manager switch`）で rebuild し、以下を確認する。
- `~/memory` が dotfiles 配下 `memory/` への symlink になっていること（`ls -la ~/memory`）
- 実体 `memory/` が無い環境では、rebuild 時に「`memory/` を作るか、この module を imports から外すこと」という警告が標準エラーに出て、activation 自体は成功で終わること
