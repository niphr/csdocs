# Render an inline Rd node with a conditional tag

Renders `\\ifelse{cond}{yes}{no}` and `\\if{cond}{body}`. A helper of
[`.rd_inline_piece()`](https://niphr.github.io/csdocs/reference/dot-rd_inline_piece.md).

## Usage

``` r
.rd_inline_conditional_piece(x, tag, in_code)
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
