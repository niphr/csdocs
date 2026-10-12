# Find the renderer for a block-level Rd tag

[`.rd_to_block_md()`](https://niphr.github.io/csdocs/reference/dot-rd_to_block_md.md)
renders six block-level tags, each with its own renderer. A tag matches
only when it is [`identical()`](https://rdrr.io/r/base/identical.html)
to one of them.

## Usage

``` r
.rd_block_renderer(tag, heading_level)
```

## Arguments

- tag:

  The `Rd_tag` attribute of one Rd child node, or `NULL`.

- heading_level:

  As in
  [`.rd_to_block_md()`](https://niphr.github.io/csdocs/reference/dot-rd_to_block_md.md).
  Only the `\\subsection{}{}` renderer uses it.

## Value

A function of one Rd node that returns a Markdown string, or `NULL` when
`tag` is not a block-level tag.
