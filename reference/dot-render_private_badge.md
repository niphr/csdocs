# Render a `_(private)_` marker for topics outside the public API

Render a `_(private)_` marker for topics outside the public API

## Usage

``` r
.render_private_badge(topic)
```

## Arguments

- topic:

  Parsed topic list.

## Value

`" _(private)_"`, or `""` if `topic$is_private` isn't `TRUE`.
