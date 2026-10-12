# Decide whether one relative link is dead, and why

Decide whether one relative link is dead, and why

## Usage

``` r
.dead_link_kind(dir, file, link, target_cache)
```

## Arguments

- dir:

  Path to the folder that
  [`.find_dead_links()`](https://niphr.github.io/csdocs/reference/dot-find_dead_links.md)
  checks.

- file:

  The file that holds the link, relative to `dir`.

- link:

  The link target.

- target_cache:

  An environment that caches the targets per file.

## Value

`"file"`, `"fragment"`, or `NA` when the link is alive.
