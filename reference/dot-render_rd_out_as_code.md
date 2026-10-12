# Render the raw HTML of an `\\out{}` node as Markdown

The function keeps two shapes of R6 class HTML and drops all other HTML.

## Usage

``` r
.render_rd_out_as_code(out_node)
```

## Arguments

- out_node:

  An `\\out{}` Rd node.

## Value

A Markdown string, or `NULL` when the function drops the HTML.

## Details

- An anchor `<a id="X"></a>` becomes `<a id="x"></a>` on its own line.
  The id is lowercase, because GitHub lowercases an `id` and does not
  change an `href`.
  [`.rd_inline_link_piece()`](https://niphr.github.io/csdocs/reference/dot-rd_inline_link_piece.md)
  lowercases the in-page `\\href{#X}` fragment to match.

- The "Inherited methods" block becomes a Markdown list of code spans,
  with no links. See
  [`.render_inherited_methods()`](https://niphr.github.io/csdocs/reference/dot-render_inherited_methods.md).

roxygen2 writes a fenced code block as `\\preformatted{}` between two
`\\out{}` wrappers.
[`.render_rd_preformatted()`](https://niphr.github.io/csdocs/reference/dot-render_rd_preformatted.md)
renders the code, so the wrappers carry nothing to keep.
