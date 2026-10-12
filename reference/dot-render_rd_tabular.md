# Render a `\\tabular{spec}{body}` node as a Markdown table

`spec` is a column-alignment string like `"ll"` (2 left-aligned columns)
or `"lcr"` (left, center, right) - `l`/`c`/`r` map to the corresponding
Markdown table alignment marker; anything else defaults to left. `spec`
is filtered down to `[lcr]` characters before use, since the raw Rd
source can carry stray whitespace/newlines around the spec that would
otherwise shift the character-to-column mapping. Cell text is also
pipe-escaped (see
[`.escape_table_pipe()`](https://niphr.github.io/csdocs/reference/dot-escape_table_pipe.md)) -
a literal `|` in cell content would otherwise break the row. Rows that
are entirely blank once collapsed (e.g. a spacer `\\cr` with nothing
between it and the next, or trailing whitespace after the last real row)
are dropped. The first surviving row becomes the Markdown table's
header, since GFM tables require one and Rd's `\\tabular{}` doesn't
distinguish a header row - this matches how such tables are typically
authored in practice (a label row followed by data rows).

## Usage

``` r
.render_rd_tabular(x)
```

## Arguments

- x:

  A `\\tabular{}{}` Rd node (2 children: alignment spec, body).

## Value

A Markdown table string, or `""` if the table has no non-blank rows.
