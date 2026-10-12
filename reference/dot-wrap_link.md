# Wrap Markdown text in a link, when there is a target

Wrap Markdown text in a link, when there is a target

## Usage

``` r
.wrap_link(text, href)
```

## Arguments

- text:

  Markdown link text.

- href:

  The link target, or `NULL`.

## Value

`[text](href)`, or `text` when `href` is `NULL`.
