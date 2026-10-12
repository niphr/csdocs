# Render a compact "Aliases:" line for aliases not already in the heading

`topic$aliases` commonly includes the topic's own name plus every name
already surfaced via
[`.render_topic_heading()`](https://niphr.github.io/csdocs/reference/dot-render_topic_heading.md)
(e.g. S3 method aliases, or the callable names of a multi-function
topic) - repeating those here would be redundant. Only genuinely
additional aliases are listed, so e.g.
[`lag()`](https://rdrr.io/r/stats/lag.html) stays findable even though
the topic file itself is named `lead-lag.md`.

## Usage

``` r
.render_aliases_line(topic)
```

## Arguments

- topic:

  Parsed topic list.

## Value

Markdown string, possibly empty.
