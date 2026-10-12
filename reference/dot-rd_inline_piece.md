# Render one Rd child node as an inline Markdown piece

Dispatches to
[`.leaf_rd_text()`](https://niphr.github.io/csdocs/reference/dot-leaf_rd_text.md)
for non-list (leaf) nodes; special-cases `\\method{generic}{class}`
(rendered as `generic.class`, the convention used in `\\usage{}` for S3
method signatures) and the common inline formatting tags (`\\code`,
`\\emph`, `\\href`, ...). Nodes that are lists but not a recognized tag
(e.g. `\\item`, or an unnamed wrapper list) are treated as transparent
containers via a plain recursive
[`.rd_to_text()`](https://niphr.github.io/csdocs/reference/dot-rd_to_text.md)
call.

## Usage

``` r
.rd_inline_piece(x, in_code = FALSE)
```

## Arguments

- x:

  A single Rd child node (leaf or list).

- in_code:

  Whether `x` is already nested inside a code-styled wrapper - see
  [`.rd_to_text()`](https://niphr.github.io/csdocs/reference/dot-rd_to_text.md).

## Value

A string fragment.
