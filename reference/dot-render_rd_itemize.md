# Render an `\\itemize{}` node as a Markdown bullet list

Each item is collapsed to a single line via
[`.collapse_whitespace()`](https://niphr.github.io/csdocs/reference/dot-collapse_whitespace.md),
same as a table cell. Rd source hard-wraps item text across lines for
readability; left as raw newlines, a continuation line isn't reliably
recognized as part of the same list item across Markdown renderers (and
can be actively misread as a new block - a line that happens to start
with a digit and `. `, or contains something like `<table>`, is
ambiguous or gets parsed as literal HTML). GitHub/Gitea compatibility
requires each bullet to be self-contained on one line.

## Usage

``` r
.render_rd_itemize(x)
```

## Arguments

- x:

  An `\\itemize{}` Rd node.

## Value

A Markdown string, one `- item` line per item.
