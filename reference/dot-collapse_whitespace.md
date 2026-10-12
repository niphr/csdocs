# Collapse a prose string to a single line

Rd source hard-wraps prose (`\\description{}`, `\\item{}{}`
descriptions, etc.) at some column width for source readability - those
line breaks aren't semantically meaningful. Left in place, they break
Markdown tables, since a table cell can't contain a literal newline:
text after the break renders as plain content outside the table and
everything below it in the same table is broken too. Use this on prose
fields only - never on `\\usage{}`/`\\examples{}` content, where
newlines are real code line breaks that must be preserved.

## Usage

``` r
.collapse_whitespace(text)
```

## Arguments

- text:

  A string, typically already passed through
  [`.rd_to_text()`](https://niphr.github.io/csdocs/reference/dot-rd_to_text.md).

## Value

`text` with all runs of whitespace (including newlines) collapsed to a
single space, trimmed.
