"""Format OpenSCAD source by re-spacing and re-indenting its tokens.

Line breaks stay where the author put them. Only the whitespace between tokens changes, which `format_source`
verifies by comparing the tokens of input and output.
"""

from dataclasses import dataclass, field

from scadfmt.tokenizer import Kind, Token, TokenizeError, significant, tokenize

INDENT = "  "
COMMENT_GAP = 2
MAX_BLANK_LINES_TOP = 2
MAX_BLANK_LINES_NESTED = 1
FMT_OFF = "// fmt: off"
FMT_ON = "// fmt: on"

OPENERS = {"(": ")", "[": "]", "{": "}"}
CLOSERS = {v: k for k, v in OPENERS.items()}
# Keywords followed by a space before `(`; every other name is a call and stays tight.
SPACED_BEFORE_PAREN = {"if", "for", "intersection_for", "function"}
MODIFIERS = {"#", "%", "!", "*"}
UNARY = {"-", "+", "!", "~"}
HEADER_KEYWORDS = {"if", "for", "intersection_for", "let", "function", "assert", "echo"}
# A previous token after which a line continues the statement instead of starting a new one.
STATEMENT_ENDS = {";", "{", "}"}


class FormatError(ValueError):
    """Raised when source cannot be formatted safely."""


@dataclass
class _Frame:
    """An open bracket (or the file root) and what the formatter tracks inside it."""

    char: str
    level: int
    pending_ternaries: int = 0
    # `(` right after `if`, `for`, `let`, `function`...: a `-` after its `)` starts an operand.
    header: bool = False
    # Levels of unbraced `if` lines still waiting for a possible `else`.
    if_levels: list[int] = field(default_factory=list)


@dataclass
class _Line:
    """One output line before trailing comments are aligned."""

    indent: str
    code: str
    comment: str | None = None
    verbatim: bool = False
    blank: bool = False


@dataclass
# pylint: disable-next=too-many-instance-attributes  # Plain state holder for one formatting pass
class _State:
    """Everything the formatter carries from one token to the next."""

    stack: list[_Frame] = field(default_factory=lambda: [_Frame("", -1)])
    previous: Token | None = None
    previous_role: str = ""
    in_expression: bool = False
    # Level of the line the last code line belongs to, see `_render_tokens`.
    line_anchor: int = 0
    after_header: bool = False
    newline: str = "\n"
    # Stack depths at which open module/function definitions started, and whether one just ended.
    definition_depths: list[int] = field(default_factory=list)
    definition_ended: bool = False


def format_source(source: str) -> str:
    """Format OpenSCAD source.

    Args:
        source: OpenSCAD source text.

    Returns:
        The formatted source, ending in exactly one newline. Line endings follow the first one in source.

    Raises:
        FormatError: On input that cannot be tokenized, has unbalanced brackets, or would change meaning.
    """
    try:
        tokens = tokenize(source)
    except TokenizeError as e:
        raise FormatError(str(e)) from e
    source_lines = source.replace("\r\n", "\n").replace("\r", "\n").split("\n")
    output = _render(_split_lines(_insert_breaks(tokens)), source_lines, _newline(source))
    if significant(tokenize(output)) != significant(tokens):
        raise FormatError("formatting would change the code, file left untouched (please report this as a bug)")
    return output


def _newline(source: str) -> str:
    """The line ending the file uses, judged by its first line break (LF if it has none)."""
    first = next((i for i, char in enumerate(source) if char in "\r\n"), None)
    if first is None or source[first] == "\n":
        return "\n"
    return "\r\n" if source.startswith("\r\n", first) else "\r"


def _insert_breaks(tokens: list[Token]) -> list[Token]:
    """Put block contents and statements on their own lines.

    Adds a line break after `{`, around `}` (keeping `} else`) and after `;` outside parentheses, except in empty
    `{}`, before a trailing comment and inside `// fmt: off` regions. Added breaks have empty text.
    """
    out: list[Token] = []
    stack: list[str] = []
    fmt_off = False

    def ensure_break(after: Token) -> None:
        if out and out[-1].kind != Kind.NEWLINE:
            out.append(Token(Kind.NEWLINE, "", after.line, after.col))

    for index, token in enumerate(tokens):
        following = tokens[index + 1] if index + 1 < len(tokens) else None
        if token.kind == Kind.LINE_COMMENT and token.text.strip() in (FMT_OFF, FMT_ON):
            fmt_off = token.text.strip() == FMT_OFF
        is_op = token.kind == Kind.OP
        if not fmt_off and is_op and token.text == "}" and not (out and out[-1].text == "{"):
            ensure_break(token)
        out.append(token)
        if is_op and token.text in OPENERS:
            stack.append(token.text)
        elif is_op and token.text in CLOSERS and stack:
            stack.pop()
        if fmt_off or not is_op or following is None:
            continue
        if following.kind in (Kind.NEWLINE, Kind.LINE_COMMENT):
            continue
        if _breaks_after(token.text, following.text, not stack or stack[-1] == "{"):
            ensure_break(token)
    return out


def _breaks_after(text: str, following: str, at_statement_level: bool) -> bool:
    """Whether a line break follows the operator text when following comes next on the same line."""
    if text == "{":
        return following != "}"
    if text == "}":
        return following not in ("else", ";")
    return text == ";" and at_statement_level


def _split_lines(tokens: list[Token]) -> list[tuple[list[Token], int, int]]:
    """Group tokens into physical lines.

    Returns:
        (tokens, first source line, last source line) per line. A multi-line comment or string keeps the lines it
        spans in one group.
    """
    lines = []
    current: list[Token] = []
    start = 1
    for token in tokens:
        if token.kind == Kind.NEWLINE:
            lines.append((current, start, token.line))
            # An added break (empty text) splits a source line, so the next group starts on the same one.
            current, start = [], token.line + 1 if token.text else token.line
        else:
            current.append(token)
    if current:
        lines.append((current, start, current[-1].line + current[-1].text.count("\n")))
    return lines


def _render(lines: list[tuple[list[Token], int, int]], source_lines: list[str], newline: str = "\n") -> str:
    """Turn grouped tokens into formatted text joined by newline."""
    state = _State(newline=newline)
    out: list[_Line] = []
    blank_run = 0
    fmt_off = False
    next_code_is_import = _next_code_is_import(lines)
    definition_starts = _definition_starts(lines)
    after_import = False
    for index, (tokens, first, last) in enumerate(lines):
        if not tokens:
            if fmt_off:
                out.append(_Line("", "", verbatim=True))
            else:
                blank_run += 1
            continue
        level = _match_else(tokens, _line_level(tokens[0], state), state)
        marker = tokens[0].text.strip() if len(tokens) == 1 and tokens[0].kind == Kind.LINE_COMMENT else None
        if after_import and not fmt_off:
            blank_run, after_import = _import_block_gap(tokens, next_code_is_import[index])
        if not _is_comment_only(tokens):
            after_import = _is_import(tokens)
        if not fmt_off:
            blank_run = _definition_gap(tokens, blank_run, definition_starts[index], state)
            if _is_definition(tokens):
                state.definition_depths.append(len(state.stack))
            out.extend(_blank_lines(blank_run, top_level=len(state.stack) == 1 and level == 0))
        blank_run = 0
        code, comment = _render_tokens(tokens, level, state)
        _close_definitions(state)
        if fmt_off and marker != FMT_ON:
            out.extend(_Line("", text, verbatim=True) for text in source_lines[first - 1 : last])
            continue
        out.append(_Line(INDENT * level, code, comment))
        fmt_off = marker == FMT_OFF or (fmt_off and marker != FMT_ON)
    if len(state.stack) > 1:
        frame = state.stack[-1]
        raise FormatError(f"unclosed {frame.char!r} at end of file")
    # Blank lines only reach out before a following line, so only leading ones need trimming.
    while out and out[0].blank:
        out.pop(0)
    _align_comments(out)
    # Joined with the file's newline directly: a multi-line string keeps its own line endings.
    text = newline.join(line.code if line.verbatim else _join(line) for line in out)
    return text + newline if text else ""


def _is_definition(tokens: list[Token]) -> bool:
    """True for a line starting a `module` or `function` definition (not a function literal)."""
    first = tokens[0]
    return (
        first.kind == Kind.IDENT
        and first.text in ("module", "function")
        and tokens[1:2] != []
        and (tokens[1].kind == Kind.IDENT)
    )


def _definition_starts(lines: list[tuple[list[Token], int, int]]) -> list[bool]:
    """Per line: whether a definition, including the comments directly above it, starts here."""
    starts = [False] * len(lines)
    for index, (tokens, _, _) in enumerate(lines):
        if not tokens or not _is_definition(tokens):
            continue
        top = index
        while top > 0 and _is_attached_comment(lines[top - 1][0]):
            top -= 1
        starts[top] = True
    return starts


def _is_attached_comment(tokens: list[Token]) -> bool:
    """True for a comment-only line that belongs to the definition below it (fmt markers never do)."""
    if not tokens or not _is_comment_only(tokens):
        return False
    return tokens[0].text.strip() not in (FMT_OFF, FMT_ON)


def _definition_gap(tokens: list[Token], blank_run: int, starts_definition: bool, state: _State) -> int:
    """Exactly one blank line before and after a definition, but none next to a brace or the file start.

    Returns:
        The number of blank lines to put before this line.
    """
    ended, state.definition_ended = state.definition_ended, False
    if not (starts_definition or ended):
        return blank_run
    previous, first = state.previous, tokens[0]
    if previous is None or (previous.kind == Kind.OP and previous.text == "{"):
        return blank_run
    if first.kind == Kind.OP and first.text in CLOSERS:
        return blank_run
    return 1


def _close_definitions(state: _State) -> None:
    """Mark a definition as ended once its closing `;` or `}` brings the bracket depth back."""
    previous = state.previous
    while (
        state.definition_depths
        and len(state.stack) == state.definition_depths[-1]
        and previous is not None
        and previous.text in (";", "}")
    ):
        state.definition_depths.pop()
        state.definition_ended = True


def _blank_lines(count: int, top_level: bool) -> list[_Line]:
    """Up to count blank lines, capped by where they sit."""
    allowed = MAX_BLANK_LINES_TOP if top_level else MAX_BLANK_LINES_NESTED
    return [_Line("", "", blank=True) for _ in range(min(count, allowed))]


def _match_else(tokens: list[Token], level: int, state: _State) -> int:
    """Put an `else` at the level of the unbraced `if` it belongs to, and track those `if`s.

    Returns:
        The line's level, corrected for an `else`.
    """
    frame, first = state.stack[-1], tokens[0]
    if (first.kind == Kind.OP and first.text in CLOSERS) or _is_comment_only(tokens):
        return level
    is_else = first.kind == Kind.IDENT and first.text == "else"
    if is_else and frame.if_levels:
        level = frame.if_levels.pop()
    elif frame.char in ("", "{") and level == frame.level + 1:
        # A new statement ends every `if` at or below its level.
        frame.if_levels = [pending for pending in frame.if_levels if pending < level]
    starts_if = first.text == "if" or (is_else and len(tokens) > 1 and tokens[1].text == "if")
    if first.kind == Kind.IDENT and starts_if:
        frame.if_levels.append(level)
    return level


def _is_import(tokens: list[Token]) -> bool:
    """True for an `include <...>` or `use <...>` line."""
    return len(tokens) > 1 and tokens[1].kind == Kind.PATH


def _is_comment_only(tokens: list[Token]) -> bool:
    """True for a line holding only comments."""
    return all(token.kind in (Kind.LINE_COMMENT, Kind.BLOCK_COMMENT) for token in tokens)


def _import_block_gap(tokens: list[Token], next_code_is_import: bool) -> tuple[int, bool]:
    """Blank lines before a line that follows an import: none inside the block, exactly one after it.

    Returns:
        The blank line count and whether the line still belongs to the import block.
    """
    inside = _is_import(tokens) or (_is_comment_only(tokens) and next_code_is_import)
    return (0 if inside else 1), inside


def _next_code_is_import(lines: list[tuple[list[Token], int, int]]) -> list[bool]:
    """Per line: whether the next line with code after it is an import."""
    result = [False] * len(lines)
    following = False
    for index in range(len(lines) - 1, -1, -1):
        result[index] = following
        tokens = lines[index][0]
        if tokens and not _is_comment_only(tokens):
            following = _is_import(tokens)
    return result


def _join(line: _Line) -> str:
    """Build one output line from its parts."""
    if line.blank:
        return ""
    if line.comment is None:
        return line.indent + line.code
    if not line.code:
        return line.indent + line.comment
    return line.indent + line.code + " " * COMMENT_GAP + line.comment


def _align_comments(out: list[_Line]) -> None:
    """Align trailing comments of consecutive lines to one column; a lone one keeps the default gap."""
    run: list[_Line] = []
    for line in [*out, None]:
        if line is not None and not line.verbatim and line.code and line.comment is not None:
            run.append(line)
            continue
        if len(run) > 1:
            width = max(len(item.indent + item.code) for item in run)
            for item in run:
                item.code += " " * (width - len(item.indent + item.code))
        run = []


def _line_level(first: Token, state: _State) -> int:
    """Indent level of a line starting with first, given the state before it."""
    top = state.stack[-1]
    if first.kind == Kind.OP and first.text in CLOSERS:
        return max(top.level, 0)
    base = top.level + 1
    if top.char in ("(", "["):
        return base
    previous = state.previous
    starts_statement = (
        previous is None
        or previous.kind == Kind.PATH
        or (previous.kind == Kind.OP and previous.text in STATEMENT_ENDS)
        or (first.kind == Kind.OP and first.text == "{")
    )
    if starts_statement:
        return base
    # Expressions continue one level in; a chain of module calls nests one level per line.
    return base + 1 if state.in_expression else max(state.line_anchor, top.level) + 1


def _render_tokens(tokens: list[Token], level: int, state: _State) -> tuple[str, str | None]:
    """Render one line's tokens and update state.

    Returns:
        The code part and the trailing line comment, if any.
    """
    comment = None
    if tokens[-1].kind == Kind.LINE_COMMENT:
        comment = tokens[-1].text.rstrip()
        tokens = tokens[:-1]
    parts: list[str] = []
    before: Token | None = None
    before_role = ""
    # A bracket opened after closing a multi-line `(` or `[` on this line belongs to the line that opened it.
    anchor = level
    for token in tokens:
        role = _role(token, state)
        text = _token_text(token, state.newline)
        if before is not None and _needs_space(before, before_role, token, role):
            parts.append(" ")
        parts.append(text)
        before, before_role = token, role
        closed = _advance(token, role, anchor, state)
        if closed is not None and closed.char in ("(", "["):
            anchor = min(anchor, closed.level)
    if any(token.kind != Kind.BLOCK_COMMENT for token in tokens):
        state.line_anchor = anchor
    return "".join(parts), comment


def _token_text(token: Token, newline: str) -> str:
    """Token text as written to the output."""
    if token.kind == Kind.BLOCK_COMMENT:
        return newline.join(part.rstrip() for part in token.text.splitlines())
    return token.text


def _role(token: Token, state: _State) -> str:
    """Classify an operator by its position: binary, unary, modifier, range or plain."""
    if token.kind != Kind.OP:
        return ""
    text = token.text
    previous, frame = state.previous, state.stack[-1]
    if text in MODIFIERS and _at_statement_start(state):
        return "modifier"
    if text in UNARY and (state.after_header or _expects_operand(previous)):
        return "unary"
    if text == ":":
        return "binary" if frame.pending_ternaries else "range"
    if text in OPENERS or text in CLOSERS or text in (",", ";", "."):
        return ""
    return "binary"


def _at_statement_start(state: _State) -> bool:
    """True where a `#`, `%`, `!` or `*` is a modifier rather than an operator."""
    if state.stack[-1].char not in ("", "{") or state.in_expression:
        return False
    previous = state.previous
    if previous is None or state.previous_role == "modifier":
        return True
    if previous.kind == Kind.IDENT:
        return previous.text == "else"
    return previous.kind == Kind.OP and previous.text in (";", "{", "}", ")")


def _expects_operand(previous: Token | None) -> bool:
    """True when the next token starts an operand, so `-` or `!` is unary."""
    if previous is None:
        return True
    if previous.kind == Kind.IDENT:
        return previous.text in ("else", "each")
    return previous.kind == Kind.OP and previous.text not in (")", "]")


# pylint: disable-next=too-many-return-statements  # One rule per line reads better than a nested condition
def _needs_space(left: Token, left_role: str, right: Token, right_role: str) -> bool:
    """Whether one space separates left and right on the same line."""
    lt, rt = left.text, right.text
    if right.kind == Kind.OP and rt in (")", "]", ",", ";"):
        return False
    if left.kind == Kind.OP and lt in ("(", "[", "."):
        return False
    if right.kind == Kind.OP and rt == ".":
        return False
    if left_role == "unary" and right_role == "unary" and lt in "+-" and rt in "+-":
        return True  # `- -x`, never `--x`
    if left_role in ("unary", "modifier") or "range" in (left_role, right_role):
        return False
    if "binary" in (left_role, right_role):
        return True
    if right.kind == Kind.OP and rt == "}":
        return lt != "{"
    if right.kind == Kind.OP and rt in ("(", "["):
        return _space_before_bracket(left, rt)
    return True


def _space_before_bracket(left: Token, bracket: str) -> bool:
    """Whether `(` or `[` after left gets a space: calls and indexing stay tight."""
    if left.kind == Kind.IDENT:
        return left.text in SPACED_BEFORE_PAREN if bracket == "(" else left.text == "each"
    if left.kind == Kind.OP and left.text in (")", "]"):
        return False
    return True


def _advance(token: Token, role: str, level: int, state: _State) -> _Frame | None:
    """Update state after emitting token.

    Returns:
        The frame token closed, if it is a closing bracket.
    """
    if token.kind in (Kind.LINE_COMMENT, Kind.BLOCK_COMMENT):
        return None
    before = state.previous
    state.previous, state.previous_role, state.after_header = token, role, False
    if token.kind != Kind.OP:
        return None
    text, frame = token.text, state.stack[-1]
    if text in OPENERS:
        header = text == "(" and before is not None and before.kind == Kind.IDENT and before.text in HEADER_KEYWORDS
        state.stack.append(_Frame(text, level, header=header))
        if text == "{":
            state.in_expression = False
    elif text in CLOSERS:
        if frame.char != CLOSERS[text]:
            raise FormatError(f"{token.line}:{token.col}: unexpected {text!r}")
        state.stack.pop()
        state.after_header = frame.header
        if text == "}":
            state.in_expression = False
        return frame
    elif text == "?":
        frame.pending_ternaries += 1
    elif text == ":" and role == "binary":
        frame.pending_ternaries -= 1
    elif text == ";" and frame.char in ("", "{"):
        state.in_expression = False
        frame.pending_ternaries = 0
    elif text == "=" and frame.char in ("", "{"):
        state.in_expression = True
    return None
