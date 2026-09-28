-- diff 閲覧は crit(ブラウザ) ではなく Nvim 側に置く。見つけた箇所から gf で実ファイルへ抜け、
-- <leader>cp でパスを取って Claude に渡す導線を繋ぐため。
-- 起動は zsh の d() から `nvim -c 'CodeDiff ...'`。
return {
  {
    "esmuellert/codediff.nvim",
    cmd = "CodeDiff",
  },
}
