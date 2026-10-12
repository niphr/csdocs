# Render an inline Rd node with a link or figure tag

Renders `\\link`, `\\linkS4class`, `\\href`, `\\url` and `\\figure`. A
`\\link` to a topic of the same package becomes a relative Markdown link
when a link map is active (see
[`.with_link_map()`](https://niphr.github.io/csdocs/reference/dot-with_link_map.md)),
and a code span otherwise. A helper of
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
