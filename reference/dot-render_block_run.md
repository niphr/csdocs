# Render one run of pieces of the same kind

Render one run of pieces of the same kind

## Usage

``` r
.render_block_run(pieces, kind)
```

## Arguments

- pieces:

  A list of pieces from
  [`.rd_block_piece()`](https://niphr.github.io/csdocs/reference/dot-rd_block_piece.md).

- kind:

  The `kind` of the run.

## Value

A Markdown string, or `NULL` when an inline run has no text.
