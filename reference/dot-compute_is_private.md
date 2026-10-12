# Decide whether a topic counts as "private" (not part of the public API)

A topic is private when it has at least one callable name (see
[`.callable_candidates()`](https://niphr.github.io/csdocs/reference/dot-callable_candidates.md) -
this excludes datasets/concept pages, which aren't in `NAMESPACE`'s
`export()` list either but aren't private helpers) and *none* of its
callable names are in `exported_names`. When `exported_names` is `NULL`
(export status couldn't be determined - see
[`.read_exported_names()`](https://niphr.github.io/csdocs/reference/dot-read_exported_names.md)),
every topic is treated as public, matching behavior from before this
feature existed.

## Usage

``` r
.compute_is_private(name, aliases, usage, exported_names)
```

## Arguments

- name:

  Topic name.

- aliases:

  Character vector of the topic's aliases.

- usage:

  The topic's `\\usage{}` text.

- exported_names:

  Character vector of the package's exported names, or `NULL` if
  unknown.

## Value

`TRUE`/`FALSE`.
