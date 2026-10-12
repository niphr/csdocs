# Extract the destinations of the inline Markdown links in one line

A destination follows CommonMark in one of two forms:

## Usage

``` r
.md_link_destinations(line)
```

## Arguments

- line:

  One line of Markdown, with code already removed.

## Value

A character vector of destinations, possibly empty.

## Details

- `<...>`, which MAY hold spaces and MUST NOT hold `<` or `>`.

- A run without spaces, which MAY hold balanced parentheses, for example
  `a(b).md`.

An optional title in quotes or parentheses MAY follow the destination.
The function removes the backslash from each backslash escape.
