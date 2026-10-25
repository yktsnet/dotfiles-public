## i の worktree を .claude/worktrees/ へ移し、README のリンクを絞る
id: 38
branch-slug: worktrees-and-readme-links
status: close
type: cleanup
対象: home-manager/modules/zsh/functions/aiagent.sh, .gitignore, README.md, README.en.md
内容: (1) `i` は worktree をリポの兄弟 `{repo}.wt/` に作る。リポを並べたディレクトリの直下に `.wt` が出るので、そこを一覧するツール（リポを選んで tmux セッションを開く関数など）の候補に紛れる。置き場を、手で作る worktree と同じ `{repo}/.claude/worktrees/<id>` にそろえ、置き場の規則を1つにする。 (2) README の本文に28本のリンクがあり、Design 節では1文に4本並ぶ箇所もある。多くは `.claude/skills/README.md` から辿れる個々の skill への内部リンクで、読む流れを切る。仕組みの主張を裏付ける先、または考え方の全体を説明する先だけを残し、ほかは名前だけにする。
対象外: (1) 稼働側 dotfiles の同名関数（直し済み）。`docs/issue-workflow.md`（置き場のパスを書いていない）。worktree を畳む条件の変更 (2) 本文の論旨・節構成の変更。`.claude/skills/README.md` の変更
仮定: (1) worktree をリポの中に置いても、実行者の Claude Code が親チェックアウトの CLAUDE.md を読み込まないことは、相談者が入れ子の worktree で確かめた（worktree の CLAUDE.md だけが読まれる） (2) 残すリンクの線引きは相談者が下の一覧で決めた。言語切替とバッジはリンクの数に含めずに残す
確認: (1) `zsh -n home-manager/modules/zsh/functions/aiagent.sh` が通る。`grep -n '\.wt' home-manager/modules/zsh/functions/aiagent.sh` が何も返さない。一時ディレクトリに作った git リポで aiagent.sh を source し、`.claude/worktrees/` 配下に未登録のディレクトリと `git worktree add` で登録したディレクトリを置いて `_aiagent_sweep_wt` を呼ぶと、未登録の方だけが消え、登録済みは残る。同じリポで `.claude/worktrees/x` を worktree にしたとき、`git status --porcelain` に `.claude/` が出ない（本リポの `.gitignore` で無視される） (2) README.md と README.en.md の本文（言語切替・バッジを除く）のリンクが、下の「残す」一覧と一致する（`grep -o '\](' ` で数え、宛先を列挙して照合する）。外したリンクの名前（skill 名など）は本文に地の文やコード表記で残り、文が成り立っている。2ファイルで残すリンクの集合が同じ。CI の文書の参照切れの検査が通る
人が見るもの: (1) home-manager の switch 後に `i` で実行者を1本起動し、worktree が `{repo}/.claude/worktrees/<id>` にでき、セッションを閉じると畳まれること (2) 絞ったあとの README を GitHub 上で読み、辿りたいのに辿れない箇所が無いか

---

### 保証
- 新たに宣言する保証:
  - `i` が作る worktree は `{repo}/.claude/worktrees/<branch_leaf>` に置かれる
  - 残骸の掃除（`_aiagent_sweep_wt`）は `.claude/worktrees/` 配下のうち git に登録されていないディレクトリだけを消し、手で作った登録済みの worktree は消さない
- 維持する保証:
  - 同名の worktree が既にあれば、`i` は作らずに止める
  - abort・マージ後の後片付けで worktree と残骸が消える
  - worktree を畳む条件（PR が出ている・origin と揃う・未コミットの変更が無い）は変わらない
- README の変更は挙動に触れないので、保証は無い

### home-manager/modules/zsh/functions/aiagent.sh
- `_aiagent_sweep_wt`（147行付近）: `wt_base` を `${git_root}/.claude/worktrees` にする。冒頭コメントの「.wt は i() 専用領域なので安全」は、手で作る worktree と同居するので「登録済みの worktree は消さない」旨へ書き換える
- 445-451行付近: 既存チェックと `wt_dirs+=` のパスを `${git_root}/.claude/worktrees/${branch_leaf}` にする
- 268行付近のコメント: `{repo}.wt/` の例は前提が無くなるので外す

### .gitignore
- `.claude/worktrees/` を足す。既存の「AIエージェント」の節に置く

### README.md / README.en.md
#### 残すリンク（本文）
- sdlc-kit（冒頭）
- Zenn: 保証駆動開発（§1）
- sdlc-kit の docs/lifecycle.md（§1）
- issue-verifier（§2 別の文脈。確認者の定義そのもの）
- docs/issue-workflow.md と Zenn: Issue 駆動ワークフロー（§2 末尾）
- Skills 節の `.claude/skills/README.md`・`.claude/agents/`・`.claude/hooks/`（索引として集約する）

#### 外すリンク（名前は残す）
guarantee-audit、mvp-docs、repo-standardize、repo-readme、module-dev、skill-dev、§2 本文のフック、jp-proofreader、local-issue、pr-workflow、screen-operator、consolidate-rules、check-scope.sh、nix-tool-install、sops-secrets

#### 文言の調整
- Skills 節の「Design の各節から指している」は、索引から辿る形に合わせて直す
- 外したリンクの括弧書き（「（[x](…)・[y](…)）」）は、名前だけの括弧にするか、文に溶かす。括弧に名前が4つ並ぶ §1 の3段落目は、名前を減らしてよい
- 日本語版を直したら、英語版も同じリンク集合にそろえる
