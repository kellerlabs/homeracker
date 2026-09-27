"""Tests for scadfmt.formatter: one case per rule."""

import re

import pytest

from scadfmt import formatter
from scadfmt.formatter import FormatError, format_source


@pytest.mark.parametrize(
    ("source", "expected"),
    [
        # Operators and `=`
        ("x=1+2*3/4-5%6^7;", "x = 1 + 2 * 3 / 4 - 5 % 6 ^ 7;"),
        ("x=a<b&&c>=d||e!=f;", "x = a < b && c >= d || e != f;"),
        ("x=[5&3,5|3,~5,1<<4,16>>2];", "x = [5 & 3, 5 | 3, ~5, 1 << 4, 16 >> 2];"),
        ("cube(size=10,center=true);", "cube(size = 10, center = true);"),
        ("module m(a=1,b=[1,2]){}", "module m(a = 1, b = [1, 2]) {}"),
        # Unary operators
        ("x=[-1,+a,!b,-(c)];", "x = [-1, +a, !b, -(c)];"),
        ("x=- -a;", "x = - -a;"),
        ("-a;", "-a;"),
        ("x=a- -b;", "x = a - -b;"),
        ("x=f(a)-b;", "x = f(a) - b;"),
        ("x=[for(i=v)if(c)i else -i];", "x = [for (i = v) if (c) i else -i];"),
        # Ternary vs range colon
        ("x=a?b:c;", "x = a ? b : c;"),
        ("x=[a?b:c,0:2];", "x = [a ? b : c, 0:2];"),
        ("r=[ 0 : 2 : -10 ];", "r = [0:2:-10];"),
        # Calls, indexing, members, keywords
        ("x=f (a)[0].y;", "x = f(a)[0].y;"),
        ("if(a)b();", "if (a) b();"),
        ("for(i=[0:2])b();", "for (i = [0:2]) b();"),
        ("intersection_for(i=v)b();", "intersection_for (i = v) b();"),
        ("f=function(x)x;", "f = function (x) x;"),
        ("x=let(a=1)assert(a)echo(a)a;", "x = let(a = 1) assert(a) echo(a) a;"),
        ("x=[each[1,2]];", "x = [each [1, 2]];"),
        ("x=g(1)(2);", "x = g(1)(2);"),
        # Modifiers
        ("#a();%b();*c();!d();", "#a(); %b(); *c(); !d();"),
        ("translate(v) # cube();", "translate(v) #cube();"),
        ("if(a)b();else *c();", "if (a) b(); else *c();"),
        ("x=(a)*b;", "x = (a) * b;"),
        # Braces
        ("module m(){a();b();}", "module m() { a(); b(); }"),
        ("if(a){b();}else{c();}", "if (a) { b(); } else { c(); }"),
        # Includes
        ("include<a/b.scad>", "include <a/b.scad>"),
        ("use   <a.scad>\nx=1;", "use <a.scad>\nx = 1;"),
        # Comments
        ("/* a */x=1;/* b */", "/* a */ x = 1; /* b */"),
        ("x=1;// c  ", "x = 1;  // c"),
    ],
)
def test_single_line_rules(source, expected):
    assert format_source(source) == expected + "\n"


def test_block_indentation():
    source = "module m() {\nif (a) {\nb();\n}\n}\n"
    assert format_source(source) == "module m() {\n  if (a) {\n    b();\n  }\n}\n"


def test_multi_line_brackets_indent_once_per_line():
    source = "x = f([\n1,\n2\n]);\n"
    assert format_source(source) == "x = f([\n  1,\n  2\n]);\n"


def test_multi_line_signature_body_stays_one_level_in():
    source = "module m(a,\nb) {\nc();\n}\n"
    assert format_source(source) == "module m(a,\n  b) {\n  c();\n}\n"


def test_module_chain_nests_per_line():
    source = "translate(v)\nrotate(r)\ncube();\nnext();\n"
    assert format_source(source) == "translate(v)\n  rotate(r)\n    cube();\nnext();\n"


def test_comment_lines_inside_a_chain_do_not_nest():
    source = "translate(v)\n// line\n/* block */\ncube();\n"
    assert format_source(source) == "translate(v)\n  // line\n  /* block */\n  cube();\n"


def test_expression_continuation_stays_one_level_in():
    source = "function f(m) =\nm == 1\n? a\n: b;\n"
    assert format_source(source) == "function f(m) =\n  m == 1\n  ? a\n  : b;\n"


def test_chain_ending_in_block():
    source = "rotate(r)\ndifference() {\na();\n}\n"
    assert format_source(source) == "rotate(r)\n  difference() {\n    a();\n  }\n"


def test_brace_on_own_line_is_not_a_continuation():
    source = "module m()\n{\na();\n}\n"
    assert format_source(source) == "module m()\n{\n  a();\n}\n"


def test_statement_after_include_is_not_a_continuation():
    assert format_source("include <a.scad>\nx = 1;\n") == "include <a.scad>\nx = 1;\n"


def test_comment_lines_follow_code_indent():
    source = "module m() {\n// inside\na();\n}\n"
    assert format_source(source) == "module m() {\n  // inside\n  a();\n}\n"


def test_trailing_comments_align_per_run():
    source = "a = 1; // one\nlong_name = 2; // two\n\nb = 3;   // alone\n"
    expected = "a = 1;          // one\nlong_name = 2;  // two\n\nb = 3;  // alone\n"
    assert format_source(source) == expected


def test_comment_only_line_ends_alignment_run():
    source = "a = 1; // x\n// break\nlong_name = 2; // y\n"
    assert format_source(source) == "a = 1;  // x\n// break\nlong_name = 2;  // y\n"


def test_blank_lines_are_capped():
    source = "\n\na = 1;\n\n\n\n\nmodule m() {\n\n\n\nb();\n}\n\n\n"
    expected = "a = 1;\n\n\nmodule m() {\n\n  b();\n}\n"
    assert format_source(source) == expected


def test_fmt_off_keeps_lines_verbatim():
    source = "x=1;\n// fmt: off\nm = [\n  1,   0,\n\n\n\n  0,   1 ];\n// fmt: on\ny=2;\n"
    expected = "x = 1;\n// fmt: off\nm = [\n  1,   0,\n\n\n\n  0,   1 ];\n// fmt: on\ny = 2;\n"
    assert format_source(source) == expected


def test_block_comment_keeps_inner_lines():
    source = "module m() {\n/**\n  * Doc.   \n  */\na();\n}\n"
    assert format_source(source) == "module m() {\n  /**\n  * Doc.\n  */\n  a();\n}\n"


def test_crlf_input_gives_lf_output():
    assert format_source("x=1;\r\ny=2;\r\n") == "x = 1;\ny = 2;\n"


def test_empty_input():
    assert format_source("") == ""
    assert format_source("\n\n") == ""


@pytest.mark.parametrize(
    ("source", "message"),
    [
        ("x = @;", "unexpected character"),
        ("a());", "unexpected ')'"),
        ("a(];", "unexpected ']'"),
        ("module m() {", "unclosed '{'"),
    ],
)
def test_errors(source, message):
    with pytest.raises(FormatError, match=re.escape(message)):
        format_source(source)


def test_output_with_different_tokens_is_rejected(monkeypatch):
    monkeypatch.setattr(formatter, "_render", lambda lines, source_lines: "x = 2;\n")
    with pytest.raises(FormatError, match="would change the code"):
        format_source("x = 1;")
