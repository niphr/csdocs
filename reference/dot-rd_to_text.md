# Flatten an Rd text fragment into a single string, with inline Markdown

Rd fragments are themselves nested lists of text and tag nodes (e.g. for
`\\code{}` or `\\link{}`). `.rd_to_text()` recursively reduces a
fragment to a single-line-safe string, normalizing horizontal
whitespace, and renders common *inline* Rd tags as their Markdown
equivalent (`\\code{}` -\> `` `x` ``, `\\emph{}` -\> `_x_`, `\\href{}{}`
-\> `[text](url)`, etc. - see
[`.rd_inline_piece()`](https://niphr.github.io/csdocs/reference/dot-rd_inline_piece.md))
rather than silently stripping them to plain text.

## Usage

``` r
.rd_to_text(rd, in_code = FALSE)
```

## Arguments

- rd:

  An Rd fragment or a list of Rd fragments.

- in_code:

  Whether this call is already nested inside a code-styled wrapper
  (`\\code{}`/`\\command{}`/`\\link{}`). Threaded through recursion so
  that e.g. `\\code{\link{x}}` (an extremely common pattern) renders as
  a single `` `x` `` instead of doubly-wrapped ` `x` ` - each nested
  code-styled tag only adds backticks when it isn't already inside one.

## Value

A single, trimmed string.

## Details

Some Rd macros (e.g. `\\I{}`) are parsed into a leaf node tagged
`"USERMACRO"` whose value is a character vector like `c("#1", "bar")` -
a `#N` placeholder token followed by the actual substituted text, rather
than a plain scalar. Placeholder tokens are dropped so the substituted
text is used (see
[`.leaf_rd_text()`](https://niphr.github.io/csdocs/reference/dot-leaf_rd_text.md)).

This is "Tier 2" of csdocs's text extraction (single-line inline). Use
[`.rd_to_raw_text()`](https://niphr.github.io/csdocs/reference/dot-rd_to_raw_text.md)
("Tier 1") instead for code content
(`\\usage{}`/`\\examples{}`/`\\preformatted{}`) where exact whitespace
must survive, and
[`.rd_to_block_md()`](https://niphr.github.io/csdocs/reference/dot-rd_to_block_md.md)
("Tier 3", in `render_rd_block.R`) for rich multi-paragraph content
(`\\description{}`/`\\details{}`) that may contain lists, subsections,
or code blocks.
