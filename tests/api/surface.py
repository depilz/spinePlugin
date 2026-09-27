"""Static Lua surface of the plugin's bindings, read from their preprocessed sources (clang++ -E, with line markers).

Usage: python3 tests/api/surface.py <bindings dir> <preprocessed file>...
Prints one sorted row per key, tab-separated owner, kind, key:
  module     function  <key>   luaL_Reg entries outside any metatable (the table luaopen returns)
  <registry> field     <key>   keys set on the luaL_newmetatable(L, "<registry>") table: lua_setfield(L, -2, ...),
                                lua_pushstring + lua_push* + lua_settable, luaL_Reg entries
  <registry> get|set   <key>   strcmp(key, "<key>") literals in the C function set as its __index / __newindex
Only text from files under the bindings dir counts (the line markers say where each line came from), so the
runtime's and Lua's headers never add keys.
"""
import re
import sys
from pathlib import Path

MARKER = re.compile(r'^# \d+ "([^"]*)"')
NEWMETATABLE = re.compile(r'luaL_newmetatable\(\s*L\s*,\s*"([^"]+)"\s*\)')
SETFIELD = re.compile(r'lua_setfield\(\s*L\s*,\s*-2\s*,\s*"([^"]+)"\s*\)')
PUSH_FN = r'lua_pushcclosure\(\s*L\s*,\s*\(\s*(\w+)\s*\)\s*,\s*0\s*\)\s*;'  # lua_pushcfunction, preprocessed
SETTABLE = re.compile(r'lua_pushstring\(\s*L\s*,\s*"([^"]+)"\s*\)\s*;\s*(?:' + PUSH_FN + r'|lua_push\w+\([^;]*;)'
                      r'\s*lua_settable\(\s*L\s*,\s*-3\s*\)')
PUSHED_FIELD = re.compile(PUSH_FN + r'\s*lua_setfield\(\s*L\s*,\s*-2\s*,\s*"([^"]+)"')
REG_ENTRY = re.compile(r'\{\s*"([^"]+)"\s*,\s*\w+\s*\}')
REG_ARRAY = re.compile(r'luaL_Reg\s+\w+\s*\[\s*\]\s*=\s*\{')
STRCMP = re.compile(r'strcmp\(\s*key\s*,\s*"([^"]+)"\s*\)')
LITERAL = re.compile(r'"(?:\\.|[^"\\\n])*"|\'(?:\\.|[^\'\\\n])*\'')
HANDLERS = {"__index": "get", "__newindex": "set"}


def binding_text(path, bindings):
    """The preprocessed text that came from files under bindings, line markers dropped."""
    keep, out = False, []
    for line in Path(path).read_text(errors="replace").splitlines():
        m = MARKER.match(line)
        if m:
            keep = Path(m.group(1)).resolve().is_relative_to(bindings)
        elif keep:
            out.append(line)
    return "\n".join(out)


def masked(text):
    """text with every string and char literal blanked (same length), so braces in them never count."""
    return LITERAL.sub(lambda m: m.group(0)[0] + " " * (len(m.group(0)) - 2) + m.group(0)[-1], text)


def block_end(code, open_brace):
    """Index just past the brace block opening at open_brace in masked code."""
    depth = 0
    for i in range(open_brace, len(code)):
        if code[i] == "{":
            depth += 1
        elif code[i] == "}":
            depth -= 1
            if depth == 0:
                return i + 1
    raise ValueError("unbalanced braces")


def enclosing_block_end(code, pos):
    """Index just past the innermost brace block of masked code containing pos."""
    depth = 0
    for i in range(pos, -1, -1):
        if code[i] == "}":
            depth += 1
        elif code[i] == "{":
            if depth == 0:
                return block_end(code, i)
            depth -= 1
    raise ValueError("no enclosing block")


def function_body(text, code, name):
    m = re.search(r'\b' + re.escape(name) + r'\s*\(\s*lua_State\s*\*\s*\w+\s*\)\s*\{', text)
    if not m:
        raise ValueError(f"no definition of {name}")
    return text[m.end() - 1:block_end(code, m.end() - 1)]


def surface(text):
    rows, spans, code = set(), [], masked(text)
    for m in NEWMETATABLE.finditer(text):
        owner, end = m.group(1), enclosing_block_end(code, m.start())
        region = text[m.end():end]
        spans.append((m.start(), end))
        handlers = {k: f for f, k in PUSHED_FIELD.findall(region)}
        handlers.update({k: f for k, f in SETTABLE.findall(region)})
        keys = SETFIELD.findall(region) + [k for k, _ in SETTABLE.findall(region)] + REG_ENTRY.findall(region)
        rows.update((owner, "field", k) for k in keys)
        for meta, kind in HANDLERS.items():
            if meta in handlers:
                rows.update((owner, kind, k) for k in STRCMP.findall(function_body(text, code, handlers[meta])))
    for m in REG_ARRAY.finditer(text):
        if not any(a <= m.start() < b for a, b in spans):
            array = text[m.end() - 1:block_end(code, m.end() - 1)]
            rows.update(("module", "function", k) for k in REG_ENTRY.findall(array))
    return rows


def main():
    bindings = Path(sys.argv[1]).resolve()
    rows = set()
    for path in sys.argv[2:]:
        rows |= surface(binding_text(path, bindings))
    for row in sorted(rows):
        print("\t".join(row))


if __name__ == "__main__":
    main()
