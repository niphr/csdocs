# Render a topic's heading identifier (the part before " - Title")

Renders callable names as `` `name()` `` (joined with a middle dot when
a topic documents more than one, e.g. `lead()` /
[`lag()`](https://rdrr.io/r/stats/lag.html)), or the bare topic name
with no parentheses for non-callable topics (datasets,
concept/package-overview pages) - see
[`.callable_names()`](https://niphr.github.io/csdocs/reference/dot-callable_names.md).

## Usage

``` r
.render_topic_heading(topic)
```

## Arguments

- topic:

  Parsed topic list.

## Value

A Markdown string fragment.
