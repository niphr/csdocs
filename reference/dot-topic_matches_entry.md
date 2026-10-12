# Report whether a topic matches one `contents:` entry of `_pkgdown.yml`

An entry matches the topic name or one of its aliases. The supported
selectors are `starts_with("x")`, `ends_with("x")` and `matches("x")`.

## Usage

``` r
.topic_matches_entry(topic, entry)
```

## Arguments

- topic:

  A parsed topic list.

- entry:

  One `contents:` entry, as a string.

## Value

`TRUE` or `FALSE`.
