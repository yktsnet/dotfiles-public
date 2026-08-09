## PR記録: feat: 保証台帳をフリート横断で集約する仕組みを公開する
issue: 16 (16_guarantee-ledger-aggregation.md)
PR: https://github.com/yktsnet/dotfiles-public/pull/46
Merged: 0023a88e3cac6adb88c207bdfdaf9063c81dca44

## 変更内容
複数リポに散った保証台帳（`docs/guarantees.md`）を1箇所へ symlink で集約する仕組みを公開した。GDD がリポ単位ではなくフリート単位の運用であることを示す。

- `apps/lpt/link_guarantees.py`（新規）: 走査対象を優先順位付きで見て、見つかった `docs/guarantees.md` への相対 symlink を集約先へ張る。パス3つ（`GUARANTEES_TARGET_DIR` / `GUARANTEES_SEARCH_DIRS` / `GUARANTEES_CACHE_FILE`）は環境変数から受け取り、コード内に個人のディレクトリ名を持たない
- `apps/lpt/tests/test_link_guarantees.py`（新規）: `tmp_path` に擬似リポ構造を作り、実際のホームディレクトリに触れずに入出力を検証する。本リポで最初の Python テスト
- `apps/lpt/README.md`（新規）: 環境変数の意味・既定値・実行例
- `home-manager/modules/guarantees.nix`（新規）: `home.activation` の `entryAfter [ "writeBoundary" ]` でスクリプトを呼ぶ。スクリプト不在時は何もしない
- `devices/gui/macbook/home.nix` / `devices/gui/home.nix`: `guarantees.nix` を imports に追加（`devices/headless/home.nix` には追加しない）
- `.github/workflows/ci.yml`: `nix-check` / `zsh-check` と並ぶ `python-check` ジョブを追加し `pytest apps/lpt/tests/` を走らせる
- `docs-agents/test-policy.md` / `test-policy.en.md`: 保証台帳の節にフリート横断集約の背景を1段落追加（正本の配置は変えないこと、優先順位による衝突解決を明記）

## 保証
- 走査対象のうち存在しないものは黙って読み飛ばす（例外で落ちない） → `test_missing_search_dir_is_skipped`
- 同名リポが複数の走査対象にある場合、優先順位が最も高い1つが接頭辞なしの名前を取り、残りは走査元ディレクトリ名を接頭辞に付ける → `test_conflict_naming_prefers_first_search_dir`
- 集約先ディレクトリ自身とその親は走査対象から除外される（自己参照・再帰を作らない） → `test_target_and_parent_excluded_from_scan`
- 前回実行時から台帳の集合と更新時刻のいずれも変化していなければ symlink を張り直さない（変化があれば張り直す側も対で検証） → `test_second_run_without_changes_skips_relink`, `test_content_change_triggers_relink`
- 張るのは相対パスの symlink であり実体をコピーしない → `test_symlinks_are_relative`
- キャッシュファイルが壊れている場合、例外で落ちずに再生成へ進む → `test_corrupted_cache_does_not_raise`
- 集約先・走査対象は環境変数で変更でき、コード内にハードコードされた個人のディレクトリ名を持たない → 全テストが `monkeypatch.setenv` で `tmp_path` を注入しており、実ホームディレクトリに依存しないことで担保。`grep` でも個人ディレクトリ名の不在を確認済み
- （維持）`test-policy.md` が定義する保証台帳の書式・裁可フローを変えない → なし（ドキュメントへの段落追加のみ、既存記述は変更していない）
- （維持）既存の home-manager モジュールの activation 順序に影響を与えない → なし（`entryAfter [ "writeBoundary" ]` のみで既存モジュールの並びは触れていない）
- （維持）集約は読み取りと symlink 生成のみで各リポの `docs/guarantees.md` を書き換えない → なし（`link_guarantees.py` に `docs/guarantees.md` への書き込み操作が存在しないことをコードレビューで確認）

このリポには `docs/guarantees.md` が未整備のため、台帳ファイル自体の更新は対象外（`guarantee-audit` skill 未実施）。

## 静的確認結果
- `nix shell nixpkgs#python311Packages.pytest -c pytest apps/lpt/tests/ -v` → 7 passed
- `nix flake check --impure` → darwinConfigurations.macbook 評価成功（既存の deprecation warning のみ、本変更起因のエラーなし）
- `grep` で `apps/lpt/*.py` に個人ディレクトリ名（`ykts` / `github-private` / `github-public` / `github-clone` / `share-docs`）が残っていないことを確認
- caller/import 整合性: `guarantees.nix` が参照するスクリプトパス（`$HOME/dotfiles/apps/lpt/link_guarantees.py`）は実ファイル配置と一致。`devices/gui/macbook/home.nix` / `devices/gui/home.nix` の import パスは既存の `claude.nix` / `memory.nix` の相対パスパターンと一致。`devices/headless/home.nix` は未変更
- `git diff --name-only --cached` は issue の対象9ファイルと完全一致:
  ```
  .github/workflows/ci.yml
  apps/lpt/README.md
  apps/lpt/link_guarantees.py
  apps/lpt/tests/test_link_guarantees.py
  devices/gui/home.nix
  devices/gui/macbook/home.nix
  docs-agents/test-policy.en.md
  docs-agents/test-policy.md
  home-manager/modules/guarantees.nix
  ```

## 検証手順
実際の symlink 生成は macbook / linux-desktop で `home-manager switch`（または darwin-rebuild / nixos-rebuild）を実行して確認する。適用後、`~/guarantees`（既定値、上書きしていなければ）に各リポの `docs/guarantees.md` への symlink が張られていることを目視で確認する。
