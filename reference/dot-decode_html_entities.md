# Decode the handful of HTML entities that show up in Rd `\\out{}` blocks

Not a general HTML-entity decoder - just the small set that appears in
practice (roxygen2/pandoc-generated `#&gt;` output markers and escaped
quotes/ampersands). `&amp;` is decoded last so a literal `&amp;lt;` in
the source doesn't get double-decoded into `<`.

## Usage

``` r
.decode_html_entities(text)
```

## Arguments

- text:

  A string.

## Value

`text` with entities decoded.
