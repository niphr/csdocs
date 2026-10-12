# Render a block-level `\\if{html}{\out{...}}` node, if `x` is one

`\\if{html}{...}` and `\\ifelse{html}{...}{...}` are usually inline
conditionals, which
[`.rd_inline_piece()`](https://niphr.github.io/csdocs/reference/dot-rd_inline_piece.md)
handles. roxygen2 writes R6 method anchors and the "Inherited methods"
block as an `\\if` node whose `html` branch has an `\\out{}` node as a
direct child.
[`.render_rd_out_as_code()`](https://niphr.github.io/csdocs/reference/dot-render_rd_out_as_code.md)
renders that `\\out{}` node.

## Usage

``` r
.if_out_html_block(x)
```

## Arguments

- x:

  An Rd node (only `\\if`/`\\ifelse`-tagged nodes can match).

## Value

A Markdown string, or `NULL` when `x` is not this shape or when
[`.render_rd_out_as_code()`](https://niphr.github.io/csdocs/reference/dot-render_rd_out_as_code.md)
drops the HTML. The caller then treats `x` as inline content.
