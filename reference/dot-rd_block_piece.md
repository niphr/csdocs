# Classify one Rd child of a block for [`.rd_to_block_md()`](https://niphr.github.io/csdocs/reference/dot-rd_to_block_md.md)

Classify one Rd child of a block for
[`.rd_to_block_md()`](https://niphr.github.io/csdocs/reference/dot-rd_to_block_md.md)

## Usage

``` r
.rd_block_piece(child, heading_level)
```

## Arguments

- child:

  One Rd node.

- heading_level:

  As in
  [`.rd_to_block_md()`](https://niphr.github.io/csdocs/reference/dot-rd_to_block_md.md).

## Value

A list. `kind` is `"block"` or `"item"`, with the Markdown in `md`, or
`"inline"`, with the Rd node in `node`.
