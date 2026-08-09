"""
apps/lpt/link_guarantees.py のテスト。

実際のホームディレクトリには触れない。GUARANTEES_TARGET_DIR / GUARANTEES_SEARCH_DIRS /
GUARANTEES_CACHE_FILE を全て tmp_path 配下へ向けて main() を呼ぶ。
conftest.py を分けるほどのフィクスチャ量ではないため、本ファイル内に閉じる。
"""

import json
import os
import sys
import time
import pathlib

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent.parent))
import link_guarantees  # noqa: E402


def _write_guarantee(repo_dir: pathlib.Path, content: str = "# guarantees\n") -> pathlib.Path:
    docs = repo_dir / "docs"
    docs.mkdir(parents=True, exist_ok=True)
    f = docs / "guarantees.md"
    f.write_text(content)
    return f


def _run(monkeypatch, target_dir, search_dirs, cache_file):
    monkeypatch.setenv("GUARANTEES_TARGET_DIR", str(target_dir))
    monkeypatch.setenv("GUARANTEES_SEARCH_DIRS", ":".join(str(d) for d in search_dirs))
    monkeypatch.setenv("GUARANTEES_CACHE_FILE", str(cache_file))
    link_guarantees.main()


def test_missing_search_dir_is_skipped(tmp_path, monkeypatch):
    existing = tmp_path / "search_a"
    _write_guarantee(existing / "repo1")
    missing = tmp_path / "does_not_exist"

    target = tmp_path / "target"
    cache = tmp_path / "cache.json"

    _run(monkeypatch, target, [existing, missing], cache)

    assert (target / "repo1.md").is_symlink()


def test_conflict_naming_prefers_first_search_dir(tmp_path, monkeypatch):
    search_a = tmp_path / "search_a"
    search_b = tmp_path / "search_b"
    _write_guarantee(search_a / "repo1")
    _write_guarantee(search_b / "repo1")

    target = tmp_path / "target"
    cache = tmp_path / "cache.json"

    # GUARANTEES_SEARCH_DIRS の列挙順（search_a が先）がそのまま優先順位になる
    _run(monkeypatch, target, [search_a, search_b], cache)

    assert (target / "repo1.md").resolve() == (search_a / "repo1" / "docs" / "guarantees.md").resolve()
    assert (target / "search_b-repo1.md").resolve() == (search_b / "repo1" / "docs" / "guarantees.md").resolve()


def test_target_and_parent_excluded_from_scan(tmp_path, monkeypatch):
    search_a = tmp_path / "search_a"
    _write_guarantee(search_a / "repo1")

    # container は target_dir の親であり、かつ docs/guarantees.md を持つ「リポらしき」ディレクトリ。
    # 自己参照除外が効いていなければ container.md として拾われてしまう。
    container = search_a / "container"
    _write_guarantee(container)
    target = container / "guarantees_target"
    cache = tmp_path / "cache.json"

    _run(monkeypatch, target, [search_a], cache)
    names = {p.name for p in target.iterdir()}
    assert names == {"repo1.md"}

    # 自分が張った symlink を含めても2回目で膨らまない（再帰しない）
    _run(monkeypatch, target, [search_a], cache)
    names_after = {p.name for p in target.iterdir()}
    assert names_after == {"repo1.md"}


def test_second_run_without_changes_skips_relink(tmp_path, monkeypatch, capsys):
    search_a = tmp_path / "search_a"
    _write_guarantee(search_a / "repo1")
    target = tmp_path / "target"
    cache = tmp_path / "cache.json"

    _run(monkeypatch, target, [search_a], cache)
    link = target / "repo1.md"
    first_mtime = link.lstat().st_mtime_ns

    capsys.readouterr()
    _run(monkeypatch, target, [search_a], cache)
    out = capsys.readouterr().out

    assert "Skipping" in out
    assert link.lstat().st_mtime_ns == first_mtime


def test_content_change_triggers_relink(tmp_path, monkeypatch, capsys):
    search_a = tmp_path / "search_a"
    guarantee_file = _write_guarantee(search_a / "repo1")
    target = tmp_path / "target"
    cache = tmp_path / "cache.json"

    _run(monkeypatch, target, [search_a], cache)

    # mtime の解像度に依存しないよう明示的に未来の時刻へずらす
    future = time.time() + 5
    guarantee_file.write_text("# changed\n")
    os.utime(guarantee_file, (future, future))

    capsys.readouterr()
    _run(monkeypatch, target, [search_a], cache)
    out = capsys.readouterr().out

    assert "Regenerating" in out


def test_symlinks_are_relative(tmp_path, monkeypatch):
    search_a = tmp_path / "search_a"
    _write_guarantee(search_a / "repo1")
    target = tmp_path / "target"
    cache = tmp_path / "cache.json"

    _run(monkeypatch, target, [search_a], cache)

    raw = os.readlink(target / "repo1.md")
    assert not os.path.isabs(raw)


def test_corrupted_cache_does_not_raise(tmp_path, monkeypatch):
    search_a = tmp_path / "search_a"
    _write_guarantee(search_a / "repo1")
    target = tmp_path / "target"
    cache = tmp_path / "cache.json"
    cache.write_text("{ this is not valid json")

    _run(monkeypatch, target, [search_a], cache)

    assert (target / "repo1.md").is_symlink()
    assert json.loads(cache.read_text())
