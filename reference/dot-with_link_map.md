# Evaluate code with a link map active

Inline Rd rendering reads the map through
[`.rd_link_href()`](https://niphr.github.io/csdocs/reference/dot-rd_link_href.md).
The map is a dynamic setting, so the block renderer and the inline
renderer need no extra argument. The previous map comes back when `code`
returns or fails.

## Usage

``` r
.with_link_map(map, code)
```

## Arguments

- map:

  A named character vector from
  [`.alias_link_map()`](https://niphr.github.io/csdocs/reference/dot-alias_link_map.md),
  or `NULL`.

- code:

  The code to evaluate.

## Value

The value of `code`.
