# Get the children of the first Rd node matching a tag

A convenience wrapper around
[`.get_rd_tag()`](https://niphr.github.io/csdocs/reference/dot-get_rd_tag.md)
for the common case of a singleton top-level tag (e.g. a topic's one
`\\description{}` block): unwraps the match and returns *its* children
directly, ready to hand to a renderer like
[`.rd_to_block_md()`](https://niphr.github.io/csdocs/reference/dot-rd_to_block_md.md).
Contrast with
[`.get_rd_tag()`](https://niphr.github.io/csdocs/reference/dot-get_rd_tag.md)
itself, which returns the matching node(s), not their contents.

## Usage

``` r
.first_rd_tag_children(rd, tag)
```

## Arguments

- rd:

  An `Rd` object or a list of Rd fragments.

- tag:

  Tag name including the leading backslash, e.g. `"\\description"`.

## Value

The children of the first match, or an empty list if there is no match.
