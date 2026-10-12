# Render the `README.md` index file for a reference output directory

The index groups the topics under `##` headings (see
[`.group_index_topics()`](https://niphr.github.io/csdocs/reference/dot-group_index_topics.md)),
with one table per group. Each row's "Topic" cell uses the same heading
identifier as the topic's own file (see
[`.render_topic_heading()`](https://niphr.github.io/csdocs/reference/dot-render_topic_heading.md)) -
callable names get `()`, datasets/concept pages don't - plus the same
`_(private)_` marker (see
[`.render_private_badge()`](https://niphr.github.io/csdocs/reference/dot-render_private_badge.md))
if applicable. Aliases beyond that (e.g.
[`lag()`](https://rdrr.io/r/stats/lag.html) alongside a `lead-lag` topic
named after both) get their own column so they stay findable even though
they don't have their own file/row - see
[`.render_aliases_line()`](https://niphr.github.io/csdocs/reference/dot-render_aliases_line.md)
for the same logic applied to the topic file itself. Title and alias
cells are pipe-escaped (see
[`.escape_table_pipe()`](https://niphr.github.io/csdocs/reference/dot-escape_table_pipe.md))
since both are free-form text that could contain a literal `|`.

## Usage

``` r
.render_index_md(topics, package, version, sections = NULL)
```

## Arguments

- topics:

  List of parsed topic lists.

- package:

  Package name.

- version:

  Package version.

- sections:

  Result of
  [`.read_pkgdown_sections()`](https://niphr.github.io/csdocs/reference/dot-read_pkgdown_sections.md),
  or `NULL` to group by `\concept`.

## Value

A single Markdown string (contents of `README.md`).
