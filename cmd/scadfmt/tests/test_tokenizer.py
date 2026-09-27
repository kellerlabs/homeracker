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


@pytest.mark.parametrize("number", ["1", "1.", ".5", "1e3", "1.5E-3", "2e+4"])
def test_numbers(number):
    assert kinds_and_texts(number) == [(Kind.NUMBER, number)]


def test_special_variable_is_one_ident():
    assert kinds_and_texts("$fn") == [(Kind.IDENT, "$fn")]


@pytest.mark.parametrize("keyword", ["include", "use"])
def test_include_path_is_one_token(keyword):
    assert kinds_and_texts(f"{keyword} <BOSL2/std.scad>") == [(Kind.IDENT, keyword), (Kind.PATH, "<BOSL2/std.scad>")]


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
    assert [t.text for t in tokens if t.kind == Kind.NEWLINE] == ["\n", "\n", "\n"]


def test_unknown_character():
    with pytest.raises(TokenizeError, match=r"2:3: unexpected character '@'"):
        tokenize("a;\nb @")


def test_unterminated_string():
    with pytest.raises(TokenizeError, match="1:5: unterminated string"):
        tokenize('x = "abc')


def test_unterminated_block_comment():
    with pytest.raises(TokenizeError, match="1:1: unterminated block comment"):
        tokenize("/* never closed")


def test_significant_ignores_newlines_and_comment_trailing_whitespace():
    assert significant(tokenize("a // c  \n/* x  \ny */")) == significant(tokenize("a // c\n/* x\ny */"))
    assert (Kind.NEWLINE, "\n") not in significant(tokenize("a\nb"))
