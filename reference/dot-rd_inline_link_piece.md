# Render an inline Rd node with a link or figure tag

Renders `\\href`, `\\url` and `\\figure`. A helper of
[`.rd_inline_piece()`](https://niphr.github.io/csdocs/reference/dot-rd_inline_piece.md).

## Usage

``` r
.rd_inline_link_piece(x, tag, in_code)
```

## Arguments

- x:

  A single Rd list node.

- tag:

  The `Rd_tag` of `x`, or `""`.

- in_code:

  As in
  [`.rd_inline_piece()`](https://niphr.github.io/csdocs/reference/dot-rd_inline_piece.md).

## Value

A string fragment, or `NULL` when `tag` is not one of these tags.
