"""Tests for cmd/test/mutation_report.py."""

import json
import sys
from pathlib import Path
from unittest.mock import patch

import pytest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

import mutation_report as mr  # noqa: E402  pylint: disable=wrong-import-position

DIFF = """\
diff --git a/cmd/scadm/scadm/flatten.py b/cmd/scadm/scadm/flatten.py
--- a/cmd/scadm/scadm/flatten.py
+++ b/cmd/scadm/scadm/flatten.py
@@ -10,0 +11,2 @@ def a():
+    x = 1
+    y = 2
@@ -30 +32 @@ def b():
-    old
+    new
@@ -50,3 +52,0 @@ def c():
-    gone
diff --git a/cmd/scadm/scadm/removed.py b/cmd/scadm/scadm/removed.py
--- a/cmd/scadm/scadm/removed.py
+++ /dev/null
@@ -1,2 +0,0 @@
-x
"""

SOURCE = """\
import os

CONST = 1


def top(a):
    return a + 1


@decorator
def decorated():
    return 2


class Thing:
    def method(self):
        return 3

    def other(self):
        return 4
"""


class TestParseChangedLines:
    def test_added_modified_and_deleted_hunks(self):
        changed = mr.parse_changed_lines(DIFF)
        assert changed == {"cmd/scadm/scadm/flatten.py": {11, 12, 32, 52, 53}}

    def test_deleted_file_is_ignored(self):
        assert "cmd/scadm/scadm/removed.py" not in mr.parse_changed_lines(DIFF)


class TestModuleName:
    @pytest.mark.parametrize(
        ("path", "expected"),
        [
            ("cmd/scadm/scadm/flatten.py", "scadm.flatten"),
            ("cmd/scadm/scadm/sub/mod.py", "scadm.sub.mod"),
            ("cmd/scadm/scadm/__init__.py", "scadm"),
            ("cmd/scadm/tests/test_flatten.py", None),
            ("cmd/scadm/scadm/py.typed", None),
            ("cmd/export/md-to-mw.py", None),
        ],
    )
    def test_mapping(self, path, expected):
        assert mr.module_name(path, "scadm") == expected

    @pytest.mark.parametrize(
        ("path", "expected"),
        [
            ("cmd/scadfmt/scadfmt/formatter.py", "scadfmt.formatter"),
            ("cmd/scadm/scadm/flatten.py", None),
            ("cmd/scadfmt/tests/test_formatter.py", None),
        ],
    )
    def test_mapping_is_per_package(self, path, expected):
        assert mr.module_name(path, "scadfmt") == expected


class TestChangedFunctions:
    def test_function_body(self):
        assert mr.changed_functions(SOURCE, {7}) == ["x_top"]

    def test_decorator_line_counts(self):
        assert mr.changed_functions(SOURCE, {10}) == ["x_decorated"]

    def test_method_uses_mutmut_class_separator(self):
        assert mr.changed_functions(SOURCE, {17, 20}) == ["xǁThingǁmethod", "xǁThingǁother"]

    def test_module_level_change_is_out_of_scope(self):
        assert not mr.changed_functions(SOURCE, {1, 3})


class TestScope:
    def test_globs_for_changed_functions(self, tmp_path):
        target = tmp_path / "cmd/scadm/scadm/flatten.py"
        target.parent.mkdir(parents=True)
        target.write_text(SOURCE, encoding="utf-8")
        diff = "+++ b/cmd/scadm/scadm/flatten.py\n@@ -6 +6,2 @@\n+x\n+y\n"
        assert mr.scope(diff, tmp_path, "scadm") == ["scadm.flatten.x_top__mutmut_*"]
        assert not mr.scope(diff, tmp_path, "scadfmt")

    def test_deleting_last_body_line_selects_that_function(self, tmp_path):
        # git reports a pure deletion's new-side start as the line before the removed block.
        target = tmp_path / "cmd/scadm/scadm/m.py"
        target.parent.mkdir(parents=True)
        target.write_text("def a():\n    x = 1\n\n\ndef b():\n    pass\n", encoding="utf-8")
        diff = "+++ b/cmd/scadm/scadm/m.py\n@@ -3 +2,0 @@ def a():\n-    return x\n"
        assert mr.scope(diff, tmp_path, "scadm") == ["scadm.m.x_a__mutmut_*"]

    def test_non_source_and_missing_files_are_skipped(self, tmp_path):
        diff = "+++ b/cmd/scadm/tests/test_x.py\n@@ -1 +1 @@\n+x\n+++ b/cmd/scadm/scadm/gone.py\n@@ -1 +1 @@\n+x\n"
        assert not mr.scope(diff, tmp_path, "scadm")


RESULTS = """\
    scadm.flatten.x_top__mutmut_1: killed
    scadm.flatten.x_top__mutmut_2: survived
    scadm.flatten.x_top__mutmut_3: timeout
    scadm.flatten.x_top__mutmut_4: not checked
    scadm.cli.x_main__mutmut_1: survived
some unrelated line
"""


class TestSummarize:
    def test_scoped(self):
        summary = mr.summarize(mr.parse_results(RESULTS), ["scadm.flatten.x_top__mutmut_*"])
        assert summary["killed"] == 1
        assert summary["survived"] == 1
        assert summary["timeout"] == 1
        assert summary["other"] == 1
        assert summary["total"] == 4
        assert summary["score"] == pytest.approx(200 / 3)
        assert summary["survivors"] == ["scadm.flatten.x_top__mutmut_2"]

    def test_full_run(self):
        summary = mr.summarize(mr.parse_results(RESULTS), None)
        assert summary["survivors"] == ["scadm.cli.x_main__mutmut_1", "scadm.flatten.x_top__mutmut_2"]
        assert summary["total"] == 5

    def test_nothing_tested_has_no_score(self):
        assert mr.summarize({}, None)["score"] is None


class TestRenderReport:
    def _summary(self, survivors=()):
        return {
            "killed": 3,
            "survived": len(survivors),
            "timeout": 0,
            "other": 0,
            "total": 3 + len(survivors),
            "score": 75.0,
            "survivors": list(survivors),
        }

    def test_starts_with_package_heading(self):
        report = mr.render_report(self._summary(), package="scadfmt", functions=2, timed_out=False, diffs={})
        assert report.startswith("### 🧰 scadfmt\n\n")
        assert "2 changed function(s)" in report
        assert "75.0%" in report
        assert "No surviving mutants" in report

    def test_no_changed_functions(self):
        report = mr.render_report(self._summary(), package="scadfmt", functions=0, timed_out=False, diffs={})
        assert "No `scadfmt` functions changed" in report
        assert "|" not in report

    def test_full_run_scope_and_timeout_warning(self):
        report = mr.render_report(self._summary(), package="scadm", functions=None, timed_out=True, diffs={})
        assert "all `scadm` functions" in report
        assert "nightly job" in report

    def test_lists_survivors_with_diffs_and_caps(self):
        names = [f"scadm.m.x_f__mutmut_{i:02d}" for i in range(mr.MAX_LISTED_SURVIVORS + 3)]
        report = mr.render_report(
            self._summary(names), package="scadm", functions=1, timed_out=False, diffs={names[0]: "-a\n+b"}
        )
        assert "-a\n+b" in report
        assert names[mr.MAX_LISTED_SURVIVORS - 1] in report
        assert names[mr.MAX_LISTED_SURVIVORS] not in report
        assert "…and 3 more" in report
        assert "(diff unavailable)" in report


def test_combine_puts_sections_under_one_marker():
    comment = mr.combine(["### 🧰 scadm\n\nA\n", "### 🧰 scadfmt\n\nB\n"])
    assert comment == f"{mr.MARKER}\n## 🧬 Mutation testing\n\n### 🧰 scadm\n\nA\n\n### 🧰 scadfmt\n\nB\n"


class TestDiscordPayload:
    def test_embed(self):
        summary = mr.summarize(mr.parse_results(RESULTS), None)
        payload = mr.discord_payload(summary, "https://example.test/run/1", "scadfmt")
        embed = payload["embeds"][0]
        assert embed["title"] == "🧬 Weekly mutation run: scadfmt"
        assert embed["url"] == "https://example.test/run/1"
        fields = {f["name"]: f["value"] for f in embed["fields"]}
        assert fields["🙁 Survived"] == "2"
        assert fields["Score"] == "50.0%"


class TestCoverageBadge:
    @pytest.mark.parametrize(
        ("percent", "message", "color"),
        [(95.05, "95%", "brightgreen"), (85, "85%", "green"), (72.4, "72%", "yellow"), (10, "10%", "red")],
    )
    def test_badge(self, percent, message, color):
        badge = mr.coverage_badge({"totals": {"percent_covered": percent}})
        assert badge == {"schemaVersion": 1, "label": "coverage", "message": message, "color": color}


class TestMain:
    def test_coverage_badge_command(self, tmp_path, capsys):
        cov = tmp_path / "coverage.json"
        cov.write_text(json.dumps({"totals": {"percent_covered": 91.2}}), encoding="utf-8")
        assert mr.main(["coverage-badge", str(cov)]) == 0
        assert json.loads(capsys.readouterr().out)["message"] == "91%"

    def test_report_command_scoped(self, tmp_path, capsys):
        globs = tmp_path / "globs.txt"
        globs.write_text("scadm.flatten.x_top__mutmut_*\n", encoding="utf-8")

        def fake(*args, cwd):  # pylint: disable=unused-argument
            return RESULTS if args[0] == "results" else "-x\n+y"

        with patch.object(mr, "_mutmut", side_effect=fake):
            assert mr.main(["report", "--package", "scadm", "--globs-file", str(globs), "--timed-out"]) == 0
        out = capsys.readouterr().out
        assert "1 changed function(s)" in out
        assert "scadm.flatten.x_top__mutmut_2" in out
        assert "scadm.cli.x_main__mutmut_1" not in out
        assert "nightly job" in out

    def test_report_command_empty_scope_skips_mutmut(self, tmp_path, capsys):
        globs = tmp_path / "globs.txt"
        globs.write_text("\n", encoding="utf-8")
        with patch.object(mr, "_mutmut") as mutmut:
            assert mr.main(["report", "--package", "scadm", "--globs-file", str(globs)]) == 0
        mutmut.assert_not_called()
        assert "No `scadm` functions changed" in capsys.readouterr().out

    def test_discord_command_full_run(self, capsys):
        with patch.object(mr, "_mutmut", return_value=RESULTS) as mutmut:
            assert mr.main(["discord", "--package", "scadfmt", "--run-url", "https://example.test/r"]) == 0
        assert mutmut.call_args.kwargs["cwd"].parts[-2:] == ("cmd", "scadfmt")
        assert json.loads(capsys.readouterr().out)["embeds"][0]["url"] == "https://example.test/r"

    def test_scope_command(self, capsys):
        with patch.object(mr.subprocess, "run") as run:
            run.return_value.stdout = ""
            assert mr.main(["scope", "--package", "scadfmt", "--base", "abc123"]) == 0
        assert run.call_args.args[0] == ["git", "diff", "-U0", "abc123...HEAD", "--", "cmd/scadfmt/scadfmt"]
        assert capsys.readouterr().out == "\n"

    def test_combine_command(self, tmp_path, capsys):
        first, second = tmp_path / "a.md", tmp_path / "b.md"
        first.write_text("A\n", encoding="utf-8")
        second.write_text("B\n", encoding="utf-8")
        assert mr.main(["combine", str(first), str(second)]) == 0
        assert capsys.readouterr().out == mr.combine(["A\n", "B\n"])

    def test_package_is_required(self):
        with pytest.raises(SystemExit):
            mr.main(["report"])
