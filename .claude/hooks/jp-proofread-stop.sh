#!/usr/bin/env bash
# Stop hook: この会話で書き換えた日本語の .md について、前回校正に出した版から変わった行を
# 出し、その範囲だけを jp-proofread-run.sh に渡して裏で校正させる。終了は止めない（block しない）。
#
# 校正役を Agent ツールで呼ばせると、起動と完了通知のたびに会話側のモデルが1ターンずつ起きる。
# 校正の記録は diff に残り、変更が無ければ伝えることも無いので、会話の外で走らせ、結果は
# 次に user が話しかけたターンで jp-proofread-notice.sh が渡す。
#
# 対象は transcript の Edit / Write の file_path と、Bash のコマンドに現れたパス（bash_md_paths）で
# 拾う。git の差分で拾うと、この会話の前から残っている未コミットの .md まで巻き込むため。
#
# 範囲で渡すのは、数行の直しのたびにファイル全体を読み直させないため。比べる相手は、この
# セッションで前回校正に出した版の写し、無ければ git の HEAD、それも無ければ空である。
# 変わった行に日本語が無ければ起動しない。
set -uo pipefail

# 校正役のヘッドレス実行も同じ設定を読むので、そこで再帰させない
[ -n "${JP_PROOFREAD_CHILD:-}" ] && exit 0

input=$(cat)
session=$(printf '%s' "$input" | jq -r '.session_id // empty')
transcript=$(printf '%s' "$input" | jq -r '.transcript_path // empty')

[ -n "$session" ] && [ -f "$transcript" ] || exit 0

state_dir="${XDG_CACHE_HOME:-$HOME/.cache}/claude/jp-proofread"
state="$state_dir/$session"
snap_dir="$state_dir/snap/$session"
mkdir -p "$snap_dir" 2>/dev/null || exit 0

tmp_root="${TMPDIR:-/tmp}"
tmp_root="${tmp_root%/}"

has_japanese() {
  perl -CSD -ne 'if (/[\p{Hiragana}\p{Katakana}\p{Han}]/) { $f = 1; last } END { exit($f ? 0 : 1) }' "$@" 2>/dev/null
}

snap_of() {
  printf '%s/%s' "$snap_dir" "$(printf '%s' "$1" | cksum | awk '{print $1 "-" $2}')"
}

# 比べる相手を標準出力へ出す
baseline() {
  local p="$1" snap dir rel
  snap=$(snap_of "$p")
  if [ -f "$snap" ]; then
    cat "$snap"
    return
  fi
  dir=$(dirname "$p")
  rel=$(git -C "$dir" ls-files --full-name -- "$(basename "$p")" 2>/dev/null)
  [ -n "$rel" ] && git -C "$dir" show "HEAD:$rel" 2>/dev/null
}

# 今の版で変わった行を「開始-終了」のカンマ区切りで出す（diff -U0 の hunk 見出しから取る）
changed_ranges() {
  diff -U0 "$1" "$2" | awk '
    /^@@/ {
      split($3, a, ",")
      start = substr(a[1], 2) + 0
      len = (2 in a) ? a[2] + 0 : 1
      if (len > 0) { out = out (out ? "," : "") start "-" (start + len - 1) }
    }
    END { print out }'
}

# この会話の校正役が、そのファイルをまだ見ているか
running_for() {
  local m
  for m in "$state".running.*; do
    [ -f "$m" ] || continue
    kill -0 "${m##*.}" 2>/dev/null || continue
    grep -qxF "$1" "$m" && return 0
  done
  return 1
}

# Bash で書き換えた .md は Edit / Write の記録に残らない。コマンドに現れた .md のパスを、その
# 呼び出しの cwd と、コマンド中の cd / -C の先のどれを起点にしても解決して拾う。その呼び出しより後に
# 更新されたものだけを残す（読んだだけのファイルが、会話の前からの未コミットの変更ごと
# 巻き込まれないように）。python の中で組み立てたパスや glob は拾えない
bash_md_paths() {
  jq -c 'select(.type == "assistant")
    | .cwd as $cwd | ((.timestamp // "1970-01-01T00:00:00Z") | sub("\\.[0-9]+Z$"; "Z") | fromdateiso8601) as $ts
    | .message.content[]?
    | select(.type == "tool_use" and .name == "Bash") | [$cwd, .input.command, $ts]' "$transcript" 2>/dev/null |
    perl -MJSON::PP -MCwd=abs_path -ne '
      my ($cwd, $cmd, $ts) = @{ decode_json($_) };
      next unless defined $cwd && defined $cmd;
      my $home = $ENV{HOME};
      my $expand = sub { my $d = shift; $d =~ s/^["\x27]|["\x27]$//g; $d =~ s/^(~|\$HOME|\$\{HOME\})(?=\/|$)/$home/; $d };
      my @bases = ($cwd);
      while ($cmd =~ /(?:\bcd|\s-C)\s+("[^"]+"|\x27[^\x27]+\x27|[^\s;&|)]+)/g) {
        my $d = $expand->($1);
        push @bases, ($d =~ m{^/} ? $d : "$cwd/$d");
      }
      while ($cmd =~ m{((?:~|\$HOME|\$\{HOME\})?[\w./@+-]*[\w-]\.md)(?![\w.])}g) {
        my $p = $expand->($1);
        for my $c ($p =~ m{^/} ? ($p) : map { "$_/$p" } @bases) {
          print abs_path($c), "\n" if -f $c && (stat $c)[9] >= $ts;
        }
      }'
}

runner="${JP_PROOFREAD_RUNNER:-$(dirname "$0")/jp-proofread-run.sh}"
base_tmp=$(mktemp) || exit 0
trap 'rm -f "$base_tmp"' EXIT

# macOS の /bin/bash は 3.2 で mapfile を持たないので、while read で受ける
while IFS= read -r p; do
  case "$p" in
    *.md) ;;
    *) continue ;;
  esac
  [ -f "$p" ] || continue
  # 一時ファイル・配布先の config dir・永続メモリは読み手のいる文書ではない
  case "$p" in
    /tmp/* | /private/tmp/* | "$tmp_root"/* | "$HOME"/.claude/* | "$HOME"/memory/*) continue ;;
  esac

  baseline "$p" >"$base_tmp"
  ranges=$(changed_ranges "$base_tmp" "$p")
  [ -n "$ranges" ] || continue
  snap=$(snap_of "$p")

  # 走っている校正の後から書き換えた分は、その校正が終わってから拾う
  if running_for "$p"; then
    touch "$snap.dirty"
    continue
  fi

  lines=""
  for r in ${ranges//,/ }; do
    lines="$lines$(sed -n "${r%-*},${r#*-}p" "$p")"$'\n'
  done
  if ! printf '%s' "$lines" | has_japanese; then
    cp "$p" "$snap"
    continue
  fi

  # 起動した版を写しに置き、同じ版で再び起動しないようにする。直した後の版は run 側が置き直す
  cp "$p" "$snap"
  rm -f "$snap.dirty"
  # 標準入出力を切らないと、フックの出力待ちが校正の終わりまで延びる
  nohup "$runner" "$session" "$p" "$ranges" </dev/null >/dev/null 2>&1 &
done < <(
  {
    jq -r 'select(.type == "assistant") | .message.content[]?
      | select(.type == "tool_use" and (.name == "Edit" or .name == "Write"))
      | .input.file_path // empty' "$transcript" 2>/dev/null
    bash_md_paths
  } | sort -u
)

exit 0
