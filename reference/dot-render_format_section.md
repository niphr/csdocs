# Render the format section, if present

`\\format{}` is where dataset topics (e.g. `starwars`, `storms`)
describe their variables - almost always via `\\describe{}`, handled as
Tier 3 Markdown like `\\details{}`.

## Usage

``` r
.render_format_section(topic)
```

## Arguments

- topic:

  Parsed topic list.

## Value

Markdown string, possibly empty.
