# VHS demo: watch_convert
# 生成: リポルートで nix-shell に入り `vhs packages/watch_convert/demo.tape`
# 前提: .venv に requirements.txt がインストール済み
# 示したいこと: ディレクトリへの保存を検知し、連続保存はデバウンスで束ねて、
#               静定後に1回だけ任意コマンドを実行する
# 注: 実変換（Gotenberg呼び出し）はapp/側の仕事。このモジュールが担う
#     検知とデバウンスだけを、自己完結のexecコマンドで示す。
# 尺規範: 10秒以内（仕込みは Hide、長行は Type@ で加速）

Output packages/watch_convert/demo.gif

Set FontSize 18
Set Width 1000
Set Height 500
Set Theme "Catppuccin Mocha"
Set TypingSpeed 20ms

Hide
Type "alias py=.venv/bin/python; mkdir -p shared && rm -f shared/*.xlsx"
Enter
Type "clear"
Enter
Show

Type "# 保存を検知し、静定後に1回だけ実行する"
Enter
Sleep 500ms

Type@12ms "py -m packages.watch_convert shared --exec 'echo converted: {src}' --debounce 1 &"
Enter
Sleep 900ms

Type "touch shared/report.xlsx"
Enter
Sleep 1900ms

Type@15ms "for i in 1 2 3; do touch shared/report.xlsx; sleep 0.2; done"
Enter
Sleep 2400ms
