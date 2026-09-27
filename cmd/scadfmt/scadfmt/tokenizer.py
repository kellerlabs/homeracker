"""Split OpenSCAD source into tokens.

The formatter only ever changes the whitespace between tokens, so the token list is also its safety check:
the tokens of the formatted output must equal the tokens of the input.
"""

import re
from dataclasses import dataclass
from enum import Enum


class Kind(Enum):
    """Token kinds the formatter distinguishes."""

    NEWLINE = "newline"
    LINE_COMMENT = "line_comment"
    BLOCK_COMMENT = "block_comment"
    STRING = "string"
    NUMBER = "number"
    IDENT = "ident"
    PATH = "path"
    OP = "op"


@dataclass(frozen=True)
class Token:
    """One token with the position of its first character (1-based)."""

    kind: Kind
    text: str
    line: int
    col: int


class TokenizeError(ValueError):
    """Raised on input the tokenizer cannot split safely."""


# Longest operators first, so `<=` wins over `<`.
OPERATORS = (
    "<<",
    ">>",
    "<=",
    ">=",
    "==",
    "!=",
    "&&",
    "||",
    "+",
    "-",
    "*",
    "/",
    "%",
    "^",
    "!",
    "~",
    "&",
    "|",
    "<",
    ">",
    "=",
    "?",
    ":",
    ",",
    ";",
    ".",
    "(",
    ")",
    "[",
    "]",
    "{",
    "}",
    "#",
)

_PATTERNS = [
    # OpenSCAD also skips U+00A0 (no-break space) and U+FEFF (byte order mark).
    (None, re.compile("[ \t\f\v\u00a0\ufeff]+")),
    (Kind.NEWLINE, re.compile(r"\r\n|\r|\n")),
    # Like OpenSCAD's lexer, a line comment ends at LF only; a trailing CR is stripped on output.
    (Kind.LINE_COMMENT, re.compile(r"//[^\n]*")),
    (Kind.BLOCK_COMMENT, re.compile(r"/\*.*?\*/", re.S)),
    (Kind.STRING, re.compile(r'"(?:\\.|[^"\\])*"', re.S)),
    (Kind.NUMBER, re.compile(r"0[xX][0-9A-Fa-f]+|(?:\d+\.?\d*|\.\d+)(?:[eE][+-]?\d+)?")),
    # `$`, `$1` and Unicode letters (behind --enable=unicode-identifiers) are valid OpenSCAD identifiers too.
    (Kind.IDENT, re.compile(r"\$\w*|[^\W\d]\w*")),
    (Kind.OP, re.compile("|".join(re.escape(op) for op in OPERATORS))),
]

# `include <path>` and `use <path>` take a path, not an expression.
_PATH = re.compile(r"<[^>\r\n]*>")
_PATH_KEYWORDS = ("include", "use")
_IDENT_CHAR = re.compile(r"[^\W\d]|\$")


def tokenize(source: str) -> list[Token]:
    """Split source into tokens, dropping spaces and tabs but keeping newlines.

    Args:
        source: OpenSCAD source text.

    Returns:
        The tokens in source order.

    Raises:
        TokenizeError: On a character that starts no known token, or an unterminated string or comment.
    """
    tokens: list[Token] = []
    pos, line, line_start = 0, 1, 0
    while pos < len(source):
        col = pos - line_start + 1
        previous = _last_significant(tokens)
        if previous and previous.kind == Kind.IDENT and previous.text in _PATH_KEYWORDS:
            match = _PATH.match(source, pos)
            if match:
                tokens.append(Token(Kind.PATH, match.group(), line, col))
                pos = match.end()
                continue
        for kind, pattern in _PATTERNS:
            match = pattern.match(source, pos)
            if match:
                break
        else:
            raise TokenizeError(_unknown_message(source, pos, line, col))
        if kind == Kind.OP and source.startswith("/*", pos):
            raise TokenizeError(_unknown_message(source, pos, line, col))
        if kind == Kind.NUMBER and _IDENT_CHAR.match(source, match.end()):
            # OpenSCAD reads `1abc` as one (deprecated) identifier; splitting it would change the code.
            raise TokenizeError(f"{line}:{col}: identifiers starting with a digit are not supported")
        text = match.group()
        if kind is not None:
            tokens.append(Token(kind, "\n" if kind == Kind.NEWLINE else text, line, col))
        newlines = 1 if kind == Kind.NEWLINE else text.count("\n")
        if newlines:
            line += newlines
            line_start = pos + len(text) if kind == Kind.NEWLINE else pos + text.rfind("\n") + 1
        pos = match.end()
    return tokens


def _last_significant(tokens: list[Token]) -> Token | None:
    """Return the last token that is neither a newline nor a comment."""
    for token in reversed(tokens):
        if token.kind not in (Kind.NEWLINE, Kind.LINE_COMMENT, Kind.BLOCK_COMMENT):
            return token
    return None


def _unknown_message(source: str, pos: int, line: int, col: int) -> str:
    """Describe why tokenizing stopped at pos."""
    if source.startswith("/*", pos):
        return f"{line}:{col}: unterminated block comment"
    if source[pos] == '"':
        return f"{line}:{col}: unterminated string"
    return f"{line}:{col}: unexpected character {source[pos]!r}"


def significant(tokens: list[Token]) -> list[tuple[Kind, str]]:
    """Reduce tokens to what must survive formatting unchanged.

    Newlines drop out, and trailing whitespace inside comments is ignored because the formatter strips it.

    Args:
        tokens: Tokens from `tokenize`.

    Returns:
        (kind, text) pairs to compare before and after formatting.
    """
    result = []
    for token in tokens:
        if token.kind == Kind.NEWLINE:
            continue
        text = token.text
        if token.kind in (Kind.LINE_COMMENT, Kind.BLOCK_COMMENT):
            text = "\n".join(part.rstrip() for part in text.splitlines())
        result.append((token.kind, text))
    return result
