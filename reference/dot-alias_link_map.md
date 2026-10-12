# Map every alias of a set of topics to the file of its topic

The file name is the one that
[`build_reference()`](https://niphr.github.io/csdocs/reference/build_reference.md)
writes for the topic:
[`.safe_filename()`](https://niphr.github.io/csdocs/reference/dot-safe_filename.md)
of the topic name, plus `.md`. When two topics share an alias, the first
topic in `topics` owns it.

## Usage

``` r
.alias_link_map(topics)
```

## Arguments

- topics:

  List of parsed topic lists.

## Value

A character vector of file names, named by alias.
