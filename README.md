# pkgmd

**Markdown reference documentation for any R package — no HTML, no build
step, no browser.**

`pkgmd` reads the Rd documentation of an R package and renders it as plain
Markdown: one file per topic, a navigable index, and a single bundled file
ready to hand to an LLM as context. Think of it as a `pkgdown` alternative
for teams who live in the GitHub/Gitea browser UI (or in Claude Code)
rather than a hosted HTML site.

```r
pkgmd::build_reference("dplyr", output_dir = "docs/reference")
```

Two functions cover the whole API: `build_reference()` writes the files
above to disk, and [`get_documentation()`](#in-memory-for-agents) returns
that same reference as a single string, in memory — handy for handing a
package's reference straight to an LLM agent as context.

## Why

- **Zero build step.** No Pandoc, no HTML, nothing to host. The output
  *is* the documentation — open it on GitHub/Gitea and it just renders.
- **Works on packages you haven't installed.** Point it at a local
  source checkout and get a reference straight from `man/*.Rd`, even
  mid-development, before you've ever run `install.packages()`.
- **Built for LLM context.** `_full_reference.md` bundles every topic
  into one file, meant to be dropped straight into a prompt (e.g.
  `@docs/reference/_full_reference.md` in Claude Code) — or skip the file
  entirely and call `get_documentation()` for the same content in memory.
- **One dependency-light call.** No `path` argument to remember, no
  config file to write first. `build_reference(package, output_dir)` and
  you're done.

## Quick start

```r
# An installed package:
pkgmd::build_reference("dplyr", output_dir = "docs/reference")

# A package you're actively developing, not installed anywhere:
pkgmd::build_reference(".", output_dir = "docs/reference")
pkgmd::build_reference("../myotherpkg", output_dir = "docs/reference")
```

`package` is a single, smart parameter: pass an installed package's name,
or a path to a local package source directory (detected by the presence
of a `DESCRIPTION` file). No separate flag needed to switch modes.

This produces:

```
docs/reference/
├── README.md            # index: every topic, one row each, with links
├── mutate.md
├── filter.md
├── ...
└── _full_reference.md   # every topic in one file, for LLM context
```

pkgmd dogfoods itself: [`md-docs/`](https://github.com/peterczerner/pkgmd/tree/main/md-docs)
in this repo is pkgmd's own reference, built from its own source by
`build_reference(".")` — a live example of the output above.

### In-memory, for agents

```r
docs <- pkgmd::get_documentation("dplyr")
```

Same content as `_full_reference.md`, returned as a string instead of
written to disk — no `output_dir` to pick, nothing left behind on the
filesystem. Defaults to the public API only (`include_private = FALSE`),
the opposite default from `build_reference()`, since the usual caller
here is an LLM agent that wants a package's reference, not its internals.

## Features

### Output that just works in GitHub/Gitea

- One `.md` file per topic, linked from a generated `README.md` index —
  no anchor links, which Gitea in particular doesn't render reliably.
- Special characters in topic names (`%>%`, `[<-`, ...) are safely
  URL-encoded for the filename without breaking the link text.
- Long example blocks collapse into a `<details>` disclosure so a
  topic page stays scannable.
- Fenced code blocks and inline code spans automatically widen their
  backtick delimiters when the content itself contains backticks (even
  a documented topic that discusses the backtick character itself,
  like base R's `` ?Quotes ``, renders correctly instead of breaking the
  page).
- Table cells (arguments, `\tabular{}`) escape literal `|` characters so
  a stray pipe in a description can't corrupt the table.

### Faithful to what the Rd source actually says

Beyond the basics (title, description, usage, arguments, value, examples,
see also), `pkgmd` renders the parts of Rd that simpler tools tend to
drop on the floor:

- Multiple `\section{}{}` blocks per topic, each as its own heading.
- `\format{}`, `\note{}`, `\source{}`, `\references{}`, and `\author{}` —
  the parts that make dataset documentation (`\format{}` describing each
  column) actually useful, not just a bare `\usage{}` stub.
- `\describe{}` term/description lists, `\itemize{}`/`\enumerate{}`,
  nested `\subsection{}{}`, `\tabular{}` tables, and `\preformatted{}` /
  fenced-code blocks — all rendered as real, structured Markdown rather
  than flattened prose.
- A topic's heading only gets `()` appended when it's actually callable
  (checked against its `\usage{}`) — a dataset like `starwars` renders as
  `` `starwars` ``, not the misleading `` `starwars()` ``. A topic that
  documents more than one function at once (like base's `` ?lead-lag ``
  style topics) shows every callable name: `` `lag()` · `lead()` ``.
- Aliases that aren't already visible in the heading (S3 method names,
  alternate spellings) are still surfaced — as a line in the topic file
  and as their own column in the index — so they stay findable even
  without a page of their own.

### Handles internal/private functions, on purpose

Documented-but-unexported helpers (`@keywords internal`, no `@export`)
are included by default and clearly marked:

```
# `internal_helper()` — Does the fiddly bit _(private)_
```

Set `include_private = FALSE` to generate a public-API-only reference
instead. Export status is resolved correctly regardless of package
size or `NAMESPACE` complexity (`getNamespaceExports()` for installed
packages), and datasets are never mistaken for private helpers just
because data objects aren't in `NAMESPACE`'s `export()` list either.

```r
pkgmd::build_reference("dplyr", output_dir = "docs/reference", include_private = FALSE)
```

### Two sources, one code path

- **Installed packages** are read via `tools::Rd_db()` — works for any
  package on your library path, with or without source access.
- **Development packages** are read straight from `man/*.Rd` if it's
  been rendered at least once (`devtools::document()`), or parsed live
  via `roxygen2::parse_package()` (an optional `Suggests` dependency,
  loaded only when actually needed) if it hasn't.

Both paths converge on the same internal representation, so every
feature above works identically no matter where the documentation came
from.

### Safe to run again and again

- `overwrite = TRUE` (the default) clears out `.md` files from a
  previous run before writing the new set, so a topic that got renamed
  or removed from the package doesn't leave a stale orphan file behind.
  `overwrite = FALSE` aborts instead, if you'd rather not touch an
  existing `output_dir`.
- Topic names that would collide on the filesystem — two topics
  differing only in case on a case-insensitive filesystem, or a topic
  literally named `README`/`_full_reference` — are caught with a clear
  error instead of silently overwriting each other or pkgmd's own
  generated files.
- Output is written as UTF-8 explicitly, regardless of the platform's
  native locale.

## Example

Running `pkgmd` against a minimal `mutate()`-like function produces:

````markdown
# `mutate()` — Add or modify columns

**Package:** demo · **Version:** 0.1.0

Add or modify columns

## Usage

```r
mutate(.data, ...)
```

## Arguments

| Argument | Description |
|----------|-------------|
| `.data` | A data frame. |
| `...` | Name-value pairs of expressions. |

## Value

A data frame with modified/added columns.

---
*Generated by [pkgmd](../../pkgmd/) · [Back to index](README.md)*
````

Run it against `base` or `dplyr` and you get the same thing, at scale —
`pkgmd` is exercised against `base` (446 topics) and `dplyr` (115 topics)
in its own test suite, alongside 260+ unit tests covering the renderer
directly.

## Installation

```r
install.packages("pkgmd")
```

Development version, from GitHub:

```r
# pak
pak::pkg_install("peterczerner/pkgmd")

# or devtools
devtools::install_github("peterczerner/pkgmd")
```

Requires R ≥ 4.1.0 (uses the native pipe internally). No Pandoc, no
`rmarkdown`, no browser.

## Development

```r
devtools::load_all()
devtools::test()
devtools::document()
```

`roxygen2` is a `Suggests` dependency, not `Imports` — it's only loaded
as a fallback for development packages that haven't rendered `man/` yet.
The main code paths (installed packages, or dev packages with `man/`
already present) never need it.

## License

MIT © Peter Czerner
