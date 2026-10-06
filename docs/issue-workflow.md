# Issue 駆動の手順

Issue を起こしてからマージするまでの手順。人が打つコマンドは `i` だけである。

## 一周の流れ

| 段 | 誰が | どこで |
|---|---|---|
| 1. 起票 | 相談者 | 会話の中で `local-issue` skill を使い、`issues/` に draft を書く |
| 2. 承認 | user | `i` → `approve`。draft を open に変え、続けて実装するかを聞く |
| 3. 実装・確認・直し | 実行者と user | `i` → `run` で起動した実行者のセッション |
| 4. PR を出す | 実行者 | user の OK を受けて、Issue を `done/` へ閉じ、push して PR を出す |
| 5. セッションを閉じる | user | 閉じると worktree が畳まれる |
| 6. マージ | user | `i` → `merge`（GitHub の画面からでもよい） |
| 7. 後片付け | 自動 | マージした直後か、次に `i` を開いたとき |

起票は会話の文脈の中でしか書けないので skill で行い、実装は別プロセスで走らせたいのでシェルから起動する。

## `i` の一覧

`AIAGENT_REPO_ROOTS` が指すリポを横断して、その時点で手を付けられるものだけを並べる。どのディレクトリから呼んでもよい。

- `AIAGENT_REPO_ROOTS` は空白区切りで、各要素は「それ自体が git リポならそのリポ、そうでなければ直下の git リポ」を対象にする
- 未設定なら `$HOME/dotfiles-public` の1つだけを対象にする

```text
run      dotfiles-public      21_builder-opens-pr.md
approve  repo-b               03_yyy.md
merge    repo-b               #42 feat: ...
abort    repo-b               claude/5-xxx
status   show where everything is
```

| 行 | 対象 | 選んだときの動き |
|---|---|---|
| `run` | open の Issue（実行者の枝がまだ無いもの） | そのリポで worktree を切り、実行者を起動する |
| `approve` | draft の Issue | open に変える。y で続けて `run` に進む |
| `merge` | 実行者が出した `claude/*` の open な PR | 確認のあと squash でマージし、後片付けと main の pull まで済ませる。必須チェックのあるリポでは、チェックが通ってマージされるまで待つ。落ちたら auto-merge を外して止まる |
| `abort` | 実行者の `claude/*` の枝 | 確認（既定は No）のあと、枝を消す。worktree が残っていれば一緒に消す |
| `status` | — | Issue や枝が残っているリポの現在地を出す |

- 右側のプレビューに、Issue なら本文、PR なら本文と変更したファイルの一覧が出る。GitHub を開かずに PR を読める
- fzf なので、リポ名やファイル名の一部を打てば絞り込める
- 候補が1件も無いときは一覧を出さず、`status` の内容だけを出す
- 選んだリポに移ったまま終わる
- `run` は main から切る。マージ済みの作業枝に居残っていれば main へ戻ってから起動し、未マージの枝や未コミットの変更があれば止まる

### 複数を並行で走らせる

同じリポの `run` なら、TAB で3件まで選べる。1件ごとに worktree を切り、tmux の隠しセッションで実行者を起動する。入るのは `M-u` のピッカーから。tmux の外では起動しない。

依存し合う Issue は同時に選ばない。前提のある Issue は、相談者が draft のまま残している。

並行しても裁可が成り立つのは、確認と直しが実行者のセッションごとに閉じているからである。

## 実行者のセッションでやること

実行者は `pr-workflow` に従い、実装してコミットしたら止まる。そこから先は user とのやり取りになる。

1. 実行者がコミットのあと crit を開く。ブラウザで差分にコメントし、Finish Review を押す。実行者が指摘に対応する（1往復だけ）
2. 実行者が出す `Review:` と `Verify:` を見て、動作を確かめる
3. 直す点があれば、そのセッションで伝える。実行者が追加コミットで直す
4. 問題が無ければ「PR を出して」と伝える。実行者が Issue を `done/` へ移して閉じ、push して PR を出す
5. セッションを閉じる

PR を出す前に見つけた問題は、このセッションで直す。新しい Issue にはしない。マージした後に問題が出たときだけ、`{id}a` として Issue を起こす。

実装中に Issue の範囲を外れる作業に気づくと、実行者は「新しい Issue にする／この Issue で直す／見送る」を聞いてくる。新しい Issue にした分は、main 側の `issues/` に draft で置かれ、次に `i` を開くと `approve` に並ぶ。

## 後片付け

手で呼ぶものは無い。

- **worktree**：1件で起動した実行者のセッションを閉じたとき、PR が出ていて、枝が origin と揃い、未コミットの変更が無ければ畳む。どれかが欠けていれば残す
- **枝**：マージ済みの `claude/*` は、`i` の `merge` の直後か、次に `i` を開いたときに畳む。GitHub の画面でマージした分も、次の `i` で拾う
- **tmux で起動した実行者の worktree**：終わりを待てないので、マージ後に枝と一緒に畳む

未コミットの変更が残っているときは、worktree を畳まずに残してその旨を出す。

## 実装の在りか

| 対象 | ファイル |
|---|---|
| `i` と worktree・後片付け | `home-manager/modules/zsh/functions/aiagent.sh` |
| 起票 | `.claude/skills/local-issue/` |
| 実行者の手順 | `.claude/skills/pr-workflow/SKILL.md` |
