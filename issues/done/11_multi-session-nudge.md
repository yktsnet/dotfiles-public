## PR記録: feat(session-nudge): 並列セッションを外から観測・介入する層を公開する
issue: 11 (11_multi-session-nudge.md)
PR: https://github.com/yktsnet/dotfiles-public/pull/36
Merged: d6a16477d6aa83c5a568b77d54e6d22d41f41cdd

## 変更内容
私物 `~/dotfiles` で動いている「別の稼働中セッションを外から客観視して、必要なら
cross-session messaging で気づきを送る」仕組みを本リポへ反映した。既存の Role
Separation は「1 Issue = 1 worktree = 1 エージェント」の流れを説明するのみで、
複数セッションが並列に走っている状態には触れていなかった。M-y / M-Y / M-u（起動と
ピッカー）は公開済みのため、その上に乗る観測・介入の層（M-m / session-nudge）だけを
追加した。

- `home-manager/modules/tmux.nix`: `nudgePreview`（fzf プレビュー、sessionId から
  トランスクリプト直近60行を glob で引いて表示）と `nudgePickAndLaunch`（対象セッションを
  fzf で選び `/session-nudge target=<name>` で claude を起動）を新設し、
  `hasClaudeSessionManager` ブロックに `M-m` の bind-key を追加。あわせて
  `M-y` / `M-Y` に明示されていなかった `--permission-mode auto` を追加。
- `.claude/skills/session-nudge/SKILL.md`（新規）: 私物版を移植。判定機ではない旨・
  「A の結論を根拠に使わない」段落・`ctx` を使わない理由・`disable-model-invocation: true`
  はすべて保持。
- `zsh/functions/claude.sh`: `c()`（起動方法を番号選択）と `i()`（Issue ワークフローの
  段階を番号選択）を追加。既存の `skill()` は変更なし。
- `docs/tui_environment.md`: `Alt + y` / `Alt + Y` / `Alt + u` の表に `Alt + m` の行を追記。
- `README.md` / `README.en.md`: Role Separation 節に、並列実行時の観測・介入
  （`M-m` / session-nudge）についての段落を1つ追加。

## 保証
- `hasClaudeSessionManager` が偽のホストでは `M-m` の bind-key が設定されない →
  `M-y`/`M-Y`/`M-u` と同じ `lib.optionalString hasClaudeSessionManager` ブロック内に
  配置したことで担保（テストなし、理由は下記参照）
- 対象セッションの一覧から呼び出し元セッション自身が必ず除外される →
  `nudgePickAndLaunch` の `self_pane` / `resolve_pane`（ps -o ppid= での親探索 +
  `tmux list-panes -a` 照合）で担保（テストなし）
- 対象セッションが1つも見つからない場合はメッセージを表示して終了する →
  `nudgePickAndLaunch` の候補0件チェック（`read -r _` で待ってから exit）で担保（テストなし）
- `session-nudge` は送信前に必ず文案を user に提示する →
  `SKILL.md` 手順5「文案を user に提示し、送るか・直すかを確認する。ここを飛ばさない」で
  担保（テストなし）
- `c()` / `i()` は選択肢以外の入力で何も起動せず終了する →
  各 `case` の `*)` 分岐が `return 1` のみで exec/起動コマンドを呼ばないことで担保（テストなし）

**テスト欠落について（Issue で裁可済み・見送り）**: 上記はいずれも tmux 設定・シェル関数・
skill 本文が対象で、検証には実行環境（tmux セッションと稼働中の Claude）が要る。妥当な
テスト手段が無いため裏付けテストを含めていない。既存の `zsh/functions/*.sh` も同様に
`zsh -n` の構文チェックのみで運用している。

維持保証（変更なし）:
- `M-y` / `M-Y` / `M-u` の既存挙動（隠しセッション起動・popup アタッチ・離脱後継続・
  `M-u` からの復帰）は変えていない（`--permission-mode auto` の追加のみ）
- `zsh/functions/claude.sh` の既存関数 `skill()` は無変更
- `docs/tui_environment.md` の既存キーバインド表の記述は無変更（追記のみ）

保証台帳 `docs/guarantees.md` は本リポに存在しないため更新対象なし。

## 静的確認結果
- `nix flake check`: darwinConfigurations.macbook 評価成功（既存の非推奨オプション警告
  以外のエラーなし。x86_64-linux はローカル環境の制約でスキップ、既存動作と同じ）
- `zsh -n zsh/functions/claude.sh`: 構文エラーなし
- 目視確認: `docs/tui_environment.md` のキーバインド表と `tmux.nix` の `M-m` bind-key の
  記述が一致。README.md / README.en.md の追記段落は内容・リンク先とも日英で一致
- caller/import 整合性: `nudgePickAndLaunch` が呼ぶ `claude agents --json` は既存の
  `agentStatus`（同ファイル内）と同一コマンドで実績あり。`nudgePreview` は
  `nudgePickAndLaunch` から `${nudgePreview}` として参照され、let 束縛順（`nudgePreview` を
  先に定義）も問題なし。`i()` が呼ぶ `issue-open` / `issue` / `issue-finish` / `issue-abort`
  は `zsh/functions/aiagent.sh` に既存。`c()` が呼ぶ `claude-history` は Issue 08 で
  公開済みの CLI（`flake.nix` inputs 済み）
- `git diff --name-only --cached`:
  .claude/skills/session-nudge/SKILL.md
  README.en.md
  README.md
  docs/tui_environment.md
  home-manager/modules/tmux.nix
  zsh/functions/claude.sh

## 検証手順
実際のポップアップ動作確認は user が `macbook` / `linux-desktop` で行う。
1. `home-manager switch` を適用
2. 2つ以上のペインでそれぞれ通常セッション・別の対話 Claude セッションを起動した状態で
   `Alt + m` を押し、fzf の候補リストから呼び出し元自身が除外されていることを確認
3. プレビュー枠に対象セッションの直近の会話が表示されることを確認
4. 対象を選び `session-nudge` が起動すること、相談内容を尋ねられること、送信前に
   文案の承認を求められることを確認
5. 候補が0件の状態（対話セッションが他に無い状態）で `Alt + m` を押し、メッセージが出て
   popup が閉じずに待つことを確認
6. シェルで `c` / `i` を実行し、番号選択・番号外入力時の `return 1`（何も起動しない）を確認
