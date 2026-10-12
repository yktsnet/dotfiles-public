#!/usr/bin/env bash
# PreToolUse hook (Edit|Write|Bash): 配布先 ~/.claude 配下の Nix 管理対象への直接編集を拒否する。
# home-manager/modules/claude.nix が rm -rf + コピーで上書きデプロイするため、
# ~/.claude 側への直接編集は次回 rebuild で消える。
# Edit|Write は file_path を、Bash はリダイレクト / sed -i / tee 等のシェル経由の
# 書き込みを見る（cat / grep / diff 等の読み取りは通す）。
home="${HOME}"
input=$(cat)
tool_name=$(printf '%s' "$input" | jq -r '.tool_name // ""')

guarded="(settings\\.json|CLAUDE\\.md|(hooks|skills|agents)(/|\\b))"
dotfiles_path="本リポの .claude/ 配下の同じ相対パス（CLAUDE.md のみ home-manager/config/claude/ 配下のガイド）"

case "$tool_name" in
  Bash)
    cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // ""')
    target="(~|\\\$HOME|${home})/\\.claude/${guarded}"
    printf '%s' "$cmd" | grep -Eq "$target" || exit 0
    # /dev/null への捨てリダイレクトは書き込みではない。読み取り専用コマンドに
    # 付く 2>/dev/null で誤爆するため、判定前に落とす。
    cmd=$(printf '%s' "$cmd" | sed -E 's#[0-9]*>>?[[:space:]]*/dev/null##g')
    # ヒアドキュメントの本文はコマンドではなくデータ（文書・コミットメッセージ）
    # なので判定から外す。リダイレクトは開始行に出るので、本文を落としても
    # `cat <<EOF > 配布先` は捕まる。ただしシェルに食わせる場合は本文がそのまま
    # コマンドになるので残す。\047 は ' の八進表記（awk を単一引用符で囲むため）。
    cmd=$(printf '%s' "$cmd" | awk '
      delim != "" {
        if ($0 ~ "^[[:space:]]*" delim "[[:space:]]*$") delim = ""
        next
      }
      {
        if (match($0, /<<-?[[:space:]]*[\042\047]?[A-Za-z_][A-Za-z0-9_]*/)) {
          tok = substr($0, RSTART, RLENGTH)
          sub(/^<<-?[[:space:]]*[\042\047]?/, "", tok)
          if ($0 !~ /(^|[[:space:];&|`(])(sudo[[:space:]]+)?(bash|sh|zsh|dash|env)([[:space:]]|$)/) delim = tok
        }
        print
      }')
    # 書き込み構文は対象と結びついているものだけを見る。「どこかに書き込み構文が
    # あるか」で判定すると、本文中の `<timestamp>` の `>` をリダイレクトと誤認して
    # 正本側の編集まで拒否する。対象は同一セグメント内（次の ; & | ` ) まで）に
    # 来ることを要求する。
    seg='[^;&|`)]*'
    # in-place 編集は sed / perl / ruby の -i に限る。裸の `-i` を書き込みと見なすと
    # `grep -i` が止まる。python / node のような汎用インタプリタは、読み取りだけの
    # `-c` 実行が大半なのでコマンド名では拾わない（書き込むならリダイレクトが付く）。
    inplace="(^|[[:space:];&|\`(])(sed|perl|ruby)[[:space:]]+${seg}-[[:alnum:]]*i([[:space:]]|=)${seg}${target}"
    verbs="(^|[;&|\`(])[[:space:]]*(sudo[[:space:]]+)?(tee|cp|mv|rm|ln|mkdir|touch|chmod|install|dd|truncate|patch)[[:space:]]+${seg}${target}"
    redirect=">>?[[:space:]]*[\"\047]?${target}"
    printf '%s' "$cmd" | grep -Eq "(${redirect}|${inplace}|${verbs})" || exit 0
    ;;
  *)
    file_path=$(printf '%s' "$input" | jq -r '.tool_input.file_path // ""')
    # 配布先を剥がして、正本側の相対パスに読み替える。
    case "$file_path" in
      "$home/.claude/"*) rel="${file_path#"$home/.claude/"}" ;;
      *) exit 0 ;;
    esac
    case "$rel" in
      CLAUDE.md)
        dotfiles_path="本リポの home-manager/config/claude/ 配下のガイド"
        ;;
      settings.json|hooks/*|skills/*|agents/*)
        dotfiles_path="本リポの .claude/$rel"
        ;;
      *) exit 0 ;;
    esac
    ;;
esac

cat <<EOF
{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"配布先 ~/.claude の settings.json・CLAUDE.md・hooks/・skills/・agents/ は home-manager (home-manager/modules/claude.nix) が rm -rf + コピーで上書きデプロイする、Nix管理対象。Edit/Write でもシェル経由でも直接書き換えない（次回 home-manager switch / rebuild で消える）。代わりに ${dotfiles_path} を編集し、デプロイは user に委ねること。読み取りは制限しない。"}}
EOF
