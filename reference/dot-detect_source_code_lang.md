# Detect a `class="sourceCode <lang>"` marker in raw HTML, if present

Detect a `class="sourceCode <lang>"` marker in raw HTML, if present

## Usage

``` r
.detect_source_code_lang(html)
```

## Arguments

- html:

  Raw HTML string.

## Value

The language string (e.g. `"r"`), or `NULL` if not found.
