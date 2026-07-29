# VHS demo: template_fill
# 生成: リポルートで nix-shell に入り `vhs packages/template_fill/demo.tape`
# 前提: .venv に requirements.txt がインストール済み
# 示したいこと: マッピングYAMLの「セル番地: 項目名」に従い、
#               JSONの値がテンプレートxlsxの該当セルに流し込まれる
# 尺規範: 10秒以内（仕込みは Hide、長行は Type@ で加速）

Output packages/template_fill/demo.gif

Set FontSize 18
Set Width 1000
Set Height 500
Set Theme "Catppuccin Mocha"
Set TypingSpeed 20ms

Hide
Type "alias py=.venv/bin/python; d=packages/template_fill/demo"
Enter
Type `cells() { py -c 'import sys; from openpyxl import load_workbook as l; ws = l(sys.argv[1]).active; print("B3=", ws["B3"].value, " B5=", ws["B5"].value, " B7=", ws["B7"].value)' "$1"; }`
Enter
Type "clear"
Enter
Show

Type "# YAMLの番地へJSONの値を流し込む"
Enter
Sleep 500ms

Type "cat $d/mapping.yaml $d/data.json"
Enter
Sleep 1400ms

Type "cells $d/template.xlsx"
Enter
Sleep 1000ms

Type@12ms "py -m packages.template_fill $d/mapping.yaml $d/data.json -o generated/demo.xlsx"
Enter
Sleep 1000ms

Type "cells generated/demo.xlsx"
Enter
Sleep 2000ms
