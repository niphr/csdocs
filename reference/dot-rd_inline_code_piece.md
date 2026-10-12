# Render an inline Rd node with a code-styled tag

Renders `\\method{generic}{class}` as `generic.class`, and `\\code`,
`\\command` and `\\link` as a code span. A helper of
[`.rd_inline_piece()`](https://niphr.github.io/csdocs/reference/dot-rd_inline_piece.md).

## Usage

``` r
.rd_inline_code_piece(x, tag, in_code)
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
