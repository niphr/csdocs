# Render the arguments table, if present

Cell content is escaped via
[`.escape_table_pipe()`](https://niphr.github.io/csdocs/reference/dot-escape_table_pipe.md) -
argument descriptions are free-form prose that may legitimately contain
a literal `|` (e.g. "TRUE or FALSE"), which would otherwise terminate
the cell early and break the rest of the table.

## Usage

``` r
.render_arguments_section(topic)
```

## Arguments

- topic:

  Parsed topic list.

## Value

Markdown string, possibly empty.
