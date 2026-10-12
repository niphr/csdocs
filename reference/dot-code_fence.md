# Pick a backtick fence long enough to safely wrap some code

A fixed ```` ``` ```` fence breaks if the code itself contains a run of
3+ backticks (e.g. code that documents Markdown syntax, or nested code
blocks) - the fence closes prematurely at the first embedded run. Per
CommonMark, a fence must be *longer* than the longest backtick run
appearing in its content.

## Usage

``` r
.code_fence(code)
```

## Arguments

- code:

  The code the fence will wrap.

## Value

A string of backticks, at least 3 and at least one longer than the
longest backtick run found in `code`.
