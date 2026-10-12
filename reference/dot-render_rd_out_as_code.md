# Render an `\\out{}` node's raw HTML as a fenced Markdown code block

Strips HTML tags and decodes common entities rather than attempting to
actually parse the HTML - good enough to turn e.g.
`<div class="sourceCode r">mutate(x) #&gt; result</div>` into readable
```` ```r mutate(x) #> result ``` ```` , not pixel-perfect HTML
rendering (which Markdown can't do anyway).

## Usage

``` r
.render_rd_out_as_code(out_node)
```

## Arguments

- out_node:

  An `\\out{}` Rd node.

## Value

A fenced Markdown code block, or `NULL` if it has no content once HTML
tags are stripped (a pure wrapper tag, not real code).

## Details

roxygen2's Markdown fenced-code support compiles a single fenced block
into *three* separate top-level nodes: an opening
`\\if{html}{\out{<div class="sourceCode r">}}`, the actual code as a
plain `\\preformatted{}` (portable across all output formats, already
handled by
[`.render_rd_preformatted()`](https://niphr.github.io/csdocs/reference/dot-render_rd_preformatted.md)),
and a closing `\\if{html}{\out{</div>}}`. The opening/closing wrapper
nodes have no real content once their tags are stripped - returning
`NULL` instead of an empty fence for those lets the caller skip them
entirely rather than emitting spurious empty ```` ``` ```` blocks around
the real one.
