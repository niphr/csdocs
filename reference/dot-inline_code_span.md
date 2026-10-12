# Wrap text in an inline code span, widening delimiters to avoid collision

A single backtick pair (`` `x` ``) breaks if `x` itself contains a
backtick - e.g. base's `Quotes` topic documents the backtick character
itself as an alias, and naively wrapping it as ` ` \` ` ` produces a
bare 3-backtick run that reads as a fence, not a code span (the same
failure mode
[`.code_fence()`](https://niphr.github.io/csdocs/reference/dot-code_fence.md)
guards against for fenced blocks). Per CommonMark, an inline code span's
delimiter must be longer than the longest backtick run in its content,
and content starting or ending with a backtick needs a single space of
padding on that side so the delimiter doesn't visually fuse with it.

## Usage

``` r
.inline_code_span(text)
```

## Arguments

- text:

  The text to wrap (typically an alias, name, or other short Rd-sourced
  token, not a full code block - see
  [`.code_fence()`](https://niphr.github.io/csdocs/reference/dot-code_fence.md)
  for that).

## Value

A single string: `text` wrapped in backticks.
