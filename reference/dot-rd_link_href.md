# Find the file that a `\\link` node points to under the active link map

Find the file that a `\\link` node points to under the active link map

## Usage

``` r
.rd_link_href(x)
```

## Arguments

- x:

  A `\\link` or `\\linkS4class` Rd node.

## Value

The relative file name, or `NULL` when no link map is active, when the
link points to another package, or when the map lacks the alias.
