"""Tests for scadfmt.tokenizer."""

import pytest

from scadfmt.tokenizer import Kind, TokenizeError, significant, tokenize


def kinds_and_texts(source):
    return [(t.kind, t.text) for t in tokenize(source)]


def test_basic_statement():
    assert kinds_and_texts("x = 1.5;") == [
        (Kind.IDENT, "x"),
        (Kind.OP, "="),
        (Kind.NUMBER, "1.5"),
        (Kind.OP, ";"),
    ]


@pytest.mark.parametrize("op", ["<<", ">>", "<=", ">=", "==", "!=", "&&", "||"])
def test_multi_char_operators_win(op):
    assert kinds_and_texts(f"a{op}b")[1] == (Kind.OP, op)


@pytest.mark.parametrize("number", ["1", "1.", ".5", "1e3", "1.5E-3", "2e+4", "0xFF", "0x0a"])
def test_numbers(number):
    assert kinds_and_texts(number) == [(Kind.NUMBER, number)]


@pytest.mark.parametrize("name", ["$fn", "$", "$1", "_x", "π", "größe"])
def test_identifiers(name):
    assert kinds_and_texts(name) == [(Kind.IDENT, name)]


@pytest.mark.parametrize("keyword", ["include", "use"])
def test_include_path_is_one_token(keyword):
    assert kinds_and_texts(f"{keyword} <BOSL2/std.scad>") == [(Kind.IDENT, keyword), (Kind.PATH, "<BOSL2/std.scad>")]
    path = tokenize(f"x;\n{keyword}  <a.scad>")[-1]
    assert (path.line, path.col) == (2, len(keyword) + 3)


def test_less_than_after_other_ident_is_operator():
    assert kinds_and_texts("a <b>")[1] == (Kind.OP, "<")


def test_comments_and_strings():
    assert kinds_and_texts('/* a */ "x\\"y" // z') == [
        (Kind.BLOCK_COMMENT, "/* a */"),
        (Kind.STRING, '"x\\"y"'),
        (Kind.LINE_COMMENT, "// z"),
    ]


def test_positions_and_newlines():
    tokens = tokenize("a\r\n  b\rc\n/* x\ny */ d")
    assert [(t.text, t.line, t.col) for t in tokens if t.kind != Kind.NEWLINE] == [
        ("a", 1, 1),
        ("b", 2, 3),
        ("c", 3, 1),
        ("/* x\ny */", 4, 1),
        ("d", 5, 6),
    ]
    assert tokenize("/* a\nb\nc */ d")[-1].col == 6
    assert [t.text for t in tokens if t.kind == Kind.NEWLINE] == ["\n", "\n", "\n"]


@pytest.mark.parametrize("source", ["1abc", "2_x", "0x1g", "3π"])
def test_digit_leading_identifier_is_rejected(source):
    with pytest.raises(TokenizeError, match="1:1: identifiers starting with a digit"):
        tokenize(source)


def test_no_break_space_and_bom_are_whitespace():
    assert kinds_and_texts("\ufeffa\u00a0=\u00a01;") == kinds_and_texts("a = 1;")


def test_line_comment_ends_at_lf_only():
    tokens = tokenize("// c\ry = 2;\nz")
    assert [(t.kind, t.text) for t in tokens] == [
        (Kind.LINE_COMMENT, "// c\ry = 2;"),
        (Kind.NEWLINE, "\n"),
        (Kind.IDENT, "z"),
    ]
    assert tokens[-1].line == 2


def test_unknown_character():
    with pytest.raises(TokenizeError, match=r"2:3: unexpected character '@'"):
        tokenize("a;\nb @")


def test_unterminated_string():
    with pytest.raises(TokenizeError, match="1:5: unterminated string"):
        tokenize('x = "abc')


@pytest.mark.parametrize(("source", "position"), [("/* never closed", "1:1"), ("x /* never closed", "1:3")])
def test_unterminated_block_comment(source, position):
    with pytest.raises(TokenizeError, match=f"{position}: unterminated block comment"):
        tokenize(source)


def test_significant_ignores_newlines_and_comment_trailing_whitespace():
    assert significant(tokenize("a // c  \n/* x  \ny */")) == significant(tokenize("a // c\n/* x\ny */"))
    assert (Kind.NEWLINE, "\n") not in significant(tokenize("a\nb"))


def test_significant_strips_comment_line_ends():
    assert significant(tokenize("/* a  \nb */ // c  ")) == [
        (Kind.BLOCK_COMMENT, "/* a\nb */"),
        (Kind.LINE_COMMENT, "// c"),
    ]
