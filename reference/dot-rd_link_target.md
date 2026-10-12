# Find the alias that a `\\link` or `\\linkS4class` node points to

`\\link{x}` points to `x`, `\\link[=x]{text}` to `x`, and
`\\linkS4class{x}` to `x-class`. A link with a package option, such as
`\\link[pkg]{x}` or `\\link[pkg:x]{text}`, points to another package.

## Usage

``` r
.rd_link_target(x)
```

## Arguments

- x:

  A `\\link` or `\\linkS4class` Rd node.

## Value

The alias, or `NA` for a link to another package.
