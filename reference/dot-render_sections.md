# Render every `\\section{title}{body}` block, if any

A topic can have any number of these (see
[`.parse_rd_sections()`](https://niphr.github.io/csdocs/reference/dot-parse_rd_sections.md)),
each with its own title - e.g. dplyr's `mutate.Rd` has "Useful mutate
functions", "Grouped tibbles", and "Methods". Each renders as its own
`## Title` heading, in source order.

## Usage

``` r
.render_sections(topic)
```

## Arguments

- topic:

  Parsed topic list.

## Value

Markdown string, possibly empty.
