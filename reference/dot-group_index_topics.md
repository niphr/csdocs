# Assign every topic of the index to one group

With `sections`, the groups are the `_pkgdown.yml` sections in declared
order, and a topic goes in the first section that matches it. Without
`sections`, the groups are the `\\concept` values in alphabetical order,
and a topic goes under its alphabetically first concept. Topics in no
group go in a final "Other" group. A group without topics is dropped.

## Usage

``` r
.group_index_topics(topics, sections = NULL)
```

## Arguments

- topics:

  List of parsed topic lists.

- sections:

  Result of
  [`.read_pkgdown_sections()`](https://niphr.github.io/csdocs/reference/dot-read_pkgdown_sections.md),
  or `NULL`.

## Value

A list of `list(title, desc, topics)`.
