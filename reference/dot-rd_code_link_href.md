# Find the file that a `\\code` node links to

Roxygen writes a link to a function as `\\code{\link[=x]{x()}}`. The
code span then links as a whole. A `\\code` node with no `\\link` child,
or with more than one, links to nothing.

## Usage

``` r
.rd_code_link_href(x)
```

## Arguments

- x:

  A `\\code` or `\\command` Rd node.

## Value

The relative file name, or `NULL`.
