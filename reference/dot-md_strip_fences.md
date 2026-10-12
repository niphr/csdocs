# Remove the fenced code blocks from Markdown lines

A fence opens with three or more backticks or tildes, and closes with a
fence of the same character that is at least as long.

## Usage

``` r
.md_strip_fences(lines)
```

## Arguments

- lines:

  The lines of a Markdown file.

## Value

`lines`, with every line inside a fenced code block, and every fence
line, changed to `""`.
