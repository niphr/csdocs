# Detect a block-level `\\if{html}{\out{...}}` HTML code block, if `x` is one

`\\if{html}{...}` / `\\ifelse{html}{...}{...}` are usually simple inline
conditionals (handled by
[`.rd_inline_piece()`](https://niphr.github.io/csdocs/reference/dot-rd_inline_piece.md)),
but roxygen2's Markdown support compiles fenced code blocks
(```` ```r ````) into
`\\if{html}{\out{<div class="sourceCode r">...}}` - a real multi-line
code block authored as raw HTML passthrough, which needs block-level
handling (a fenced Markdown code block), not inline text. This detects
that specific shape: an `\\if`/`\\ifelse` node whose `html`-condition
branch has an `\\out{}` node as a direct child.

## Usage

``` r
.if_out_html_block(x)
```

## Arguments

- x:

  An Rd node (only `\\if`/`\\ifelse`-tagged nodes can match).

## Value

The rendered fenced code block (a string), or `NULL` if `x` isn't this
specific shape (the caller should treat it as ordinary inline/other
content instead).
