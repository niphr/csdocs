# Render a list of Rd block-level children as multi-paragraph Markdown

This is "Tier 3" of csdocs's text extraction (see
[`.rd_to_text()`](https://niphr.github.io/csdocs/reference/dot-rd_to_text.md)
for Tier 2 and
[`.rd_to_raw_text()`](https://niphr.github.io/csdocs/reference/dot-rd_to_raw_text.md)
for Tier 1): unlike those, which produce single-line-safe text,
`.rd_to_block_md()` walks Rd content and produces real multi-line
Markdown — paragraphs, bullet/numbered lists, nested subsection
headings, and fenced code blocks — instead of flattening everything to a
single run of prose. Use it for `\\description{}` and `\\details{}`,
which commonly contain `\\itemize{}`, `\\enumerate{}`,
`\\subsection{}{}`, and `\\preformatted{}`. It also renders the
top-level `\\item{name}{desc}` nodes of `\\value{}` as a list.

## Usage

``` r
.rd_to_block_md(rd, heading_level = 3)
```

## Arguments

- rd:

  A list of Rd fragments.

- heading_level:

  Heading depth for any `\\subsection{}{}` found at this level (e.g. `3`
  renders `### Title`). Nested subsections increase this by 1 per level.

## Value

A single Markdown string with blank lines between block segments.

## Details

`rd` is expected to already be a plain list of block-level children
(e.g. from
[`.first_rd_tag_children()`](https://niphr.github.io/csdocs/reference/dot-first_rd_tag_children.md)
or, for a `\\subsection{}{}` body, `subsection_node[[2]]` directly) —
not wrapped in an outer singleton list the way
[`.get_rd_tag()`](https://niphr.github.io/csdocs/reference/dot-get_rd_tag.md)
returns matches.
