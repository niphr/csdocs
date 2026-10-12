# List the fragment targets of a Markdown file, as GitHub renders them

GitHub lowercases every `id` and `name` attribute. It derives a heading
slug as follows:

## Usage

``` r
.md_fragment_targets(lines)
```

## Arguments

- lines:

  The lines of the Markdown file.

## Value

A character vector of targets.

## Details

1.  It lowercases the heading text.

2.  It drops every character that is not a letter, a digit, a space, `-`
    or `_`.

3.  It changes every space to `-`.

4.  It adds `-1`, `-2` and so on to a repeated slug.
