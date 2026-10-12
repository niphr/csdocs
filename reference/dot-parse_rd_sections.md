# Extract all `\\section{title}{body}` blocks of an Rd object

Unlike the other top-level tags (`\\details{}`, `\\value{}`, ...),
`\\section{}` can appear multiple times per topic, each with its own
title - e.g. dplyr's `mutate.Rd` has separate "Useful mutate functions",
"Grouped tibbles", and "Methods" sections.

## Usage

``` r
.parse_rd_sections(rd)
```

## Arguments

- rd:

  An `Rd` object.

## Value

A list of `list(title, body)` pairs, `body` rendered as Tier 3 Markdown
via
[`.rd_to_block_md()`](https://niphr.github.io/csdocs/reference/dot-rd_to_block_md.md).
