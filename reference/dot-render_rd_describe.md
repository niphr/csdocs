# Render a `\\describe{}` node as a Markdown definition-style bullet list

Unlike `\\itemize{}`/`\\enumerate{}`, whose `\\item` is a bare marker,
`\\describe{}`'s `\\item{term}{description}` is a proper 2-child
container - the same shape as `\\arguments{}`'s `\\item{name}{desc}`.
Markdown has no widely-supported definition-list syntax on GitHub/Gitea,
so each entry is rendered as `- **term**: description`.

## Usage

``` r
.render_rd_describe(x)
```

## Arguments

- x:

  A `\\describe{}` Rd node.

## Value

A Markdown string, one `- **term**: description` line per item.
