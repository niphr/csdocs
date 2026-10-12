# Render one `\\figure{file}{options}` node as its alt text, if any

We can't usefully embed a remote image in Markdown output meant to
render in GitHub/Gitea, so `\\figure{}` is reduced to whatever alt text
its `options` argument specifies (`options: alt='...'`), or dropped
entirely if there is none. In practice `\\figure{}` is almost always
reached through `\\ifelse{html}{\figure{...}}{...}` (e.g. lifecycle
badges), where the "no" branch already supplies a clean plain-text
fallback and this function is never called - it exists for the rarer
case of a bare `\\figure{}` with no such alternative.

## Usage

``` r
.render_rd_figure_alt(x)
```

## Arguments

- x:

  A `\\figure{}` Rd node.

## Value

The alt text, or `""`.
