# pkgmd — Full Reference

**Version:** 0.1 · 83 functions

---

# `.build_topics()` — Parse every entry of an Rd database into topic lists _(private)_

**Package:** pkgmd · **Version:** 0.1

Topics without a name (e.g. purely internal Rd fragments) are dropped; the result is sorted alphabetically by `name` so that the index and _full_reference.md have a stable order.

## Usage

```r
.build_topics(db, package, exported_names = NULL)
```

## Arguments

| Argument | Description |
|----------|-------------|
| `db` | Result of `.read_rd_db()`. |
| `package` | Package name. |
| `exported_names` | Character vector of the package's exported names, or `NULL` if unknown - see `.read_exported_names()` and `.compute_is_private()`. |

## Value

List of parsed topic lists, sorted by `name`.


# `.callable_candidates()` — Determine which of a topic's name/aliases actually look callable _(private)_

**Package:** pkgmd · **Version:** 0.1

A name/alias "looks callable" if it appears followed by `(` in the topic's \\usage{} text - e.g. `mutate.Rd` has usage `mutate(.data, ...)`, so `"mutate"` qualifies. Infix operators (e.g. %||%, %>%) are never followed by `(` in \\usage{} - they're invoked as `x %op% y`, not %op%(x, y) - so they get a second check: an operator-shaped name (^%.+%$) qualifies if it appears anywhere in a non-empty usage, which is safe precisely because that syntax is unambiguous (never a dataset or concept-page name). Datasets and concept pages (\\usage{} is just a bare name, or empty) never qualify either way. A single Rd topic can document several callables at once (e.g. `lead-lag.Rd` documents both `lead()` and `lag()`, with topic name `"lead-lag"` matching neither) - hence this returns a vector, not a single yes/no. Fixed-string matching (not regex) is used for the name( check deliberately: Rd names can contain regex metacharacters (%>%, [<-, ...).

## Usage

```r
.callable_candidates(name, aliases, usage)
```

## Arguments

| Argument | Description |
|----------|-------------|
| `name` | Topic name. |
| `aliases` | Character vector of the topic's aliases (possibly empty). |
| `usage` | The topic's \\usage{} text (possibly `""`). |

## Details

Shared by `.render_topic_heading()` in `render_md.R` (decides whether to append () to the heading) and `.compute_is_private()` in `parse_rd.R` (a topic whose usage is a bare name - a dataset - is never flagged private just because datasets aren't in `NAMESPACE`'s `export()` list the way functions are; an operator, unlike a dataset, still needs to be checkable against `NAMESPACE`, which is exactly what this second branch enables).

## Value

Character vector of callable names (possibly empty).


# `.callable_names()` — Determine which of a topic's name/aliases are actually callable _(private)_

**Package:** pkgmd · **Version:** 0.1

A topic is "callable" for heading purposes if its own name (or one of its aliases) literally appears followed by `(` in its \\usage{} block

- e.g. `mutate.Rd` has usage `mutate(.data, ...)`, so `"mutate"` qualifies. Datasets and concept pages (\\usage{} is just a bare name, or empty) never qualify. A single Rd topic can document several callables at once (e.g. `lead-lag.Rd` documents both `lead()` and `lag()`, with topic name `"lead-lag"` matching neither) - hence this returns a vector, not a single yes/no.

## Usage

```r
.callable_names(topic)
```

## Arguments

| Argument | Description |
|----------|-------------|
| `topic` | Parsed topic list. |

## Value

Character vector of callable names (possibly empty).


# `.check_existing_output()` — Abort if `output_dir` already contains `.md` files _(private)_

**Package:** pkgmd · **Version:** 0.1

Abort if `output_dir` already contains `.md` files

## Usage

```r
.check_existing_output(output_dir, overwrite)
```

## Arguments

| Argument | Description |
|----------|-------------|
| `output_dir` | Target directory. |
| `overwrite` | Whether existing files may be overwritten. |

## Value

`NULL`, invisibly. Aborts via `cli::cli_abort()` if needed.


# `.check_topic_name_collisions()` — Abort if two topics would collide on the filesystem _(private)_

**Package:** pkgmd · **Version:** 0.1

Two distinct failure modes: (1) a topic whose name is `README` or _full_reference (case-insensitive) would silently overwrite one of pkgmd's own generated meta files; (2) two topics whose names differ only in letter case (e.g. `Foo`/`foo`) write to the same path on a case-insensitive filesystem (macOS/Windows default), so the second write silently clobbers the first. Both are rare but corrupt the output silently if left unchecked, so they abort the whole build with a clear message rather than producing an incomplete reference.

## Usage

```r
.check_topic_name_collisions(topics)
```

## Arguments

| Argument | Description |
|----------|-------------|
| `topics` | List of parsed topic lists. |

## Value

`NULL`, invisibly. Aborts via `cli::cli_abort()` if needed.


# `.clear_generated_output()` — Remove every `.md` file already in `output_dir` _(private)_

**Package:** pkgmd · **Version:** 0.1

Called before (re-)writing a build's output when `overwrite = TRUE`, so that a topic renamed or removed from the package since the last build doesn't leave a stale, orphaned `.md` file behind - without this, the directory only ever grows and drifts from what the current package actually documents.

## Usage

```r
.clear_generated_output(output_dir)
```

## Arguments

| Argument | Description |
|----------|-------------|
| `output_dir` | Target directory. |

## Value

`NULL`, invisibly.


# `.code_fence()` — Pick a backtick fence long enough to safely wrap some code _(private)_

**Package:** pkgmd · **Version:** 0.1

A fixed ``` fence breaks if the code itself contains a run of 3+ backticks (e.g. code that documents Markdown syntax, or nested code blocks) - the fence closes prematurely at the first embedded run. Per CommonMark, a fence must be _longer_ than the longest backtick run appearing in its content.

## Usage

```r
.code_fence(code)
```

## Arguments

| Argument | Description |
|----------|-------------|
| `code` | The code the fence will wrap. |

## Value

A string of backticks, at least 3 and at least one longer than the longest backtick run found in `code`.


# `.collapse_whitespace()` — Collapse a prose string to a single line _(private)_

**Package:** pkgmd · **Version:** 0.1

Rd source hard-wraps prose (\\description{}, \\item{}{} descriptions, etc.) at some column width for source readability - those line breaks aren't semantically meaningful. Left in place, they break Markdown tables, since a table cell can't contain a literal newline: text after the break renders as plain content outside the table and everything below it in the same table is broken too. Use this on prose fields only - never on \\usage{}/\\examples{} content, where newlines are real code line breaks that must be preserved.

## Usage

```r
.collapse_whitespace(text)
```

## Arguments

| Argument | Description |
|----------|-------------|
| `text` | A string, typically already passed through `.rd_to_text()`. |

## Value

`text` with all runs of whitespace (including newlines) collapsed to a single space, trimmed.


# `.compute_is_private()` — Decide whether a topic counts as "private" (not part of the public API) _(private)_

**Package:** pkgmd · **Version:** 0.1

A topic is private when it has at least one callable name (see `.callable_candidates()` - this excludes datasets/concept pages, which aren't in `NAMESPACE`'s `export()` list either but aren't private helpers) and _none_ of its callable names are in `exported_names`. When `exported_names` is `NULL` (export status couldn't be determined - see `.read_exported_names()`), every topic is treated as public, matching behavior from before this feature existed.

## Usage

```r
.compute_is_private(name, aliases, usage, exported_names)
```

## Arguments

| Argument | Description |
|----------|-------------|
| `name` | Topic name. |
| `aliases` | Character vector of the topic's aliases. |
| `usage` | The topic's \\usage{} text. |
| `exported_names` | Character vector of the package's exported names, or `NULL` if unknown. |

## Value

`TRUE`/`FALSE`.


# `.decode_html_entities()` — Decode the handful of HTML entities that show up in Rd \\out{} blocks _(private)_

**Package:** pkgmd · **Version:** 0.1

Not a general HTML-entity decoder - just the small set that appears in practice (roxygen2/pandoc-generated #&gt; output markers and escaped quotes/ampersands). &amp; is decoded last so a literal &amp;lt; in the source doesn't get double-decoded into `<`.

## Usage

```r
.decode_html_entities(text)
```

## Arguments

| Argument | Description |
|----------|-------------|
| `text` | A string. |

## Value

`text` with entities decoded.


# `.detect_source_code_lang()` — Detect a `class="sourceCode <lang>"` marker in raw HTML, if present _(private)_

**Package:** pkgmd · **Version:** 0.1

Detect a `class="sourceCode <lang>"` marker in raw HTML, if present

## Usage

```r
.detect_source_code_lang(html)
```

## Arguments

| Argument | Description |
|----------|-------------|
| `html` | Raw HTML string. |

## Value

The language string (e.g. `"r"`), or `NULL` if not found.


# `.escape_table_pipe()` — Escape literal pipe characters for use in a GFM table cell _(private)_

**Package:** pkgmd · **Version:** 0.1

A raw `|` inside a table cell terminates the cell early and shifts every column after it - breaks the whole row (and often the rows after it, if the shift produces an odd number of remaining `|`s). Rd prose can contain a literal `|` (e.g. documenting an OR condition or \\tabular{} cell content), so cell-rendering call sites must escape it before interpolating into a | cell | cell | row.

## Usage

```r
.escape_table_pipe(text)
```

## Arguments

| Argument | Description |
|----------|-------------|
| `text` | A string destined for a table cell. |

## Value

`text` with every `|` replaced by \\|.


# `.first_rd_tag_children()` — Get the children of the first Rd node matching a tag _(private)_

**Package:** pkgmd · **Version:** 0.1

A convenience wrapper around `.get_rd_tag()` for the common case of a singleton top-level tag (e.g. a topic's one \\description{} block): unwraps the match and returns _its_ children directly, ready to hand to a renderer like `.rd_to_block_md()`. Contrast with `.get_rd_tag()` itself, which returns the matching node(s), not their contents.

## Usage

```r
.first_rd_tag_children(rd, tag)
```

## Arguments

| Argument | Description |
|----------|-------------|
| `rd` | An `Rd` object or a list of Rd fragments. |
| `tag` | Tag name including the leading backslash, e.g. `"\\description"`. |

## Value

The children of the first match, or an empty list if there is no match.


# `.get_rd_tag()` — Extract all child tags of a given type from an Rd object _(private)_

**Package:** pkgmd · **Version:** 0.1

`tools::Rd_db()` (and `tools::parse_Rd()`) return objects of class `Rd` whose elements carry a `Rd_tag` attribute (e.g. `"\\arguments"`, `"\\description"`). This helper will filter an Rd object (or a list of Rd fragments) down to the direct children matching a given tag.

## Usage

```r
.get_rd_tag(rd, tag)
```

## Arguments

| Argument | Description |
|----------|-------------|
| `rd` | An `Rd` object or a list of Rd fragments. |
| `tag` | Tag name including the leading backslash, e.g. `"\\item"`. |

## Value

List of matching Rd fragments (possibly empty).


# `.if_out_html_block()` — Detect a block-level \\if{html}{\out{...}} HTML code block, if `x` is one _(private)_

**Package:** pkgmd · **Version:** 0.1

\\if{html}{...} / \\ifelse{html}{...}{...} are usually simple inline conditionals (handled by `.rd_inline_piece()`), but roxygen2's Markdown support compiles fenced code blocks (```r) into \\if{html}{\out{<div class="sourceCode r">...}} - a real multi-line code block authored as raw HTML passthrough, which needs block-level handling (a fenced Markdown code block), not inline text. This detects that specific shape: an \\if/\\ifelse node whose `html`-condition branch has an \\out{} node as a direct child.

## Usage

```r
.if_out_html_block(x)
```

## Arguments

| Argument | Description |
|----------|-------------|
| `x` | An Rd node (only \\if/\\ifelse-tagged nodes can match). |

## Value

The rendered fenced code block (a string), or `NULL` if `x` isn't this specific shape (the caller should treat it as ordinary inline/other content instead).


# `.inline_code_span()` — Wrap text in an inline code span, widening delimiters to avoid collision _(private)_

**Package:** pkgmd · **Version:** 0.1

A single backtick pair (`` `x` ``) breaks if `x` itself contains a backtick - e.g. base's `Quotes` topic documents the backtick character itself as an alias, and naively wrapping it as ` produces a bare 3-backtick run that reads as a fence, not a code span (the same failure mode `.code_fence()` guards against for fenced blocks). Per CommonMark, an inline code span's delimiter must be longer than the longest backtick run in its content, and content starting or ending with a backtick needs a single space of padding on that side so the delimiter doesn't visually fuse with it.

## Usage

```r
.inline_code_span(text)
```

## Arguments

| Argument | Description |
|----------|-------------|
| `text` | The text to wrap (typically an alias, name, or other short Rd-sourced token, not a full code block - see `.code_fence()` for that). |

## Value

A single string: `text` wrapped in backticks.


# `.is_source_path()` — Detect whether `package` refers to a local package source directory _(private)_

**Package:** pkgmd · **Version:** 0.1

Used to dispatch between the installed-package path (`tools::Rd_db()`) and the development-package path (reading man/*.Rd directly, or falling back to a live `roxygen2::parse_package()` parse). A path is treated as a package source directory if it exists on disk and contains a `DESCRIPTION` file.

## Usage

```r
.is_source_path(package)
```

## Arguments

| Argument | Description |
|----------|-------------|
| `package` | Value passed by the caller to `build_reference()` - either an installed package name or a path to a package source directory. |

## Value

`TRUE` if `package` is a local source directory, `FALSE` otherwise (i.e. it should be treated as an installed package name).


# `.leaf_or_list_raw_text()` — Render one Rd child that may be a bare leaf or a list, as raw text _(private)_

**Package:** pkgmd · **Version:** 0.1

Render one Rd child that may be a bare leaf or a list, as raw text

## Usage

```r
.leaf_or_list_raw_text(part)
```

## Arguments

| Argument | Description |
|----------|-------------|
| `part` | An Rd child - a bare character leaf or a list. |

## Value

A string.


# `.leaf_or_list_text()` — Render one Rd child that may be a bare leaf or a list, as inline text _(private)_

**Package:** pkgmd · **Version:** 0.1

Render one Rd child that may be a bare leaf or a list, as inline text

## Usage

```r
.leaf_or_list_text(part)
```

## Arguments

| Argument | Description |
|----------|-------------|
| `part` | An Rd child - a bare character leaf (e.g. one argument of \\method{}{} or \\tabular{}{}'s format spec), or a list. |

## Value

A string.


# `.leaf_rd_text()` — Coerce a single (non-list) Rd node to a scalar string _(private)_

**Package:** pkgmd · **Version:** 0.1

Almost always `as.character(x)` already returns a length-1 string. The exception is `"USERMACRO"`-tagged nodes (from Rd macros like \\I{}), whose value is a placeholder token (`"#1"`) followed by the macro's substituted argument (e.g. `c("#1", "bar")`). `tools::parse_Rd()` already duplicates that substituted text into the _following_ sibling `TEXT` node as a fallback for consumers that don't understand `USERMACRO` (verified against `tools::Rd2txt()`'s own output) - so a `USERMACRO` node contributes nothing here to avoid rendering the text twice. Any other, unanticipated multi-value leaf is collapsed rather than erroring.

## Usage

```r
.leaf_rd_text(x)
```

## Arguments

| Argument | Description |
|----------|-------------|
| `x` | A non-list Rd leaf node. |

## Value

A single string.


# `.looks_callable()` — Decide whether one name looks callable given a topic's usage text _(private)_

**Package:** pkgmd · **Version:** 0.1

Decide whether one name looks callable given a topic's usage text

## Usage

```r
.looks_callable(name, usage)
```

## Arguments

| Argument | Description |
|----------|-------------|
| `name` | A single candidate name. |
| `usage` | The topic's non-empty \\usage{} text. |

## Value

`TRUE`/`FALSE`.


# `.normalize_block_whitespace()` — Collapse a block of prose to paragraphs, preserving paragraph breaks _(private)_

**Package:** pkgmd · **Version:** 0.1

Rd source hard-wraps prose at some column width for source readability (see `.collapse_whitespace()` for the single-line equivalent used in table cells) - those line breaks aren't semantically meaningful and are joined back into flowing text. A blank line in the source (2+ consecutive newlines), however, _is_ a meaningful paragraph break and is preserved as exactly one blank line.

## Usage

```r
.normalize_block_whitespace(text)
```

## Arguments

| Argument | Description |
|----------|-------------|
| `text` | A string, typically already passed through `.rd_to_text()`. |

## Value

`text` with hard-wrapped single newlines joined into spaces and paragraph breaks normalized to a single blank line, trimmed.


# `.parse_namespace_exports()` — Parse `export(...)` directives out of a `NAMESPACE` file _(private)_

**Package:** pkgmd · **Version:** 0.1

Parse `export(...)` directives out of a `NAMESPACE` file

## Usage

```r
.parse_namespace_exports(ns_file)
```

## Arguments

| Argument | Description |
|----------|-------------|
| `ns_file` | Path to a `NAMESPACE` file. |

## Value

Character vector of exported names (possibly empty), with surrounding quotes/backticks stripped (`export("[<-.foo")`, ``export(`%>%`)``).


# `.parse_rd_aliases()` — Extract all \\alias{} entries of an Rd object _(private)_

**Package:** pkgmd · **Version:** 0.1

Extract all \\alias{} entries of an Rd object

## Usage

```r
.parse_rd_aliases(rd)
```

## Arguments

| Argument | Description |
|----------|-------------|
| `rd` | An `Rd` object. |

## Value

Character vector of aliases.


# `.parse_rd_arguments()` — Extract \\arguments{} as a list of name/description pairs _(private)_

**Package:** pkgmd · **Version:** 0.1

Each \\item{name}{description} inside \\arguments{} becomes one row in the rendered arguments table. A well-formed \\item always has 2 children (name, description); one with fewer is malformed Rd, but skipped rather than erroring out the whole topic - a rendering gap for one argument shouldn't take down documentation for everything else.

## Usage

```r
.parse_rd_arguments(rd)
```

## Arguments

| Argument | Description |
|----------|-------------|
| `rd` | An `Rd` object. |

## Value

List of lists with fields `name`, `description`.


# `.parse_rd_examples()` — Extract the \\examples{} block as a code string _(private)_

**Package:** pkgmd · **Version:** 0.1

Uses `.rd_to_raw_text()` (Tier 1), not `.rd_to_text()` - examples are R code, so exact spacing/indentation must be preserved verbatim rather than collapsed.

## Usage

```r
.parse_rd_examples(rd)
```

## Arguments

| Argument | Description |
|----------|-------------|
| `rd` | An `Rd` object. |

## Value

String with the example code (no backtick fence), empty if no examples are present.


# `.parse_rd_from_roxygen_topic()` — Parse one in-memory roxygen2 `RdFile` topic into an `Rd` object _(private)_

**Package:** pkgmd · **Version:** 0.1

`format(topic)` renders the `RdFile` back to `.Rd` source text, which `tools::parse_Rd()` only accepts from a connection, not a plain string - hence the `textConnection()` round-trip. The connection is explicitly closed afterwards; left open, each call leaks one and eventually surfaces as an R "closing unused connection" warning once the finalizer runs.

## Usage

```r
.parse_rd_from_roxygen_topic(topic)
```

## Arguments

| Argument | Description |
|----------|-------------|
| `topic` | A single roxygen2 `RdFile` object. |

## Value

An `Rd` object, as `tools::parse_Rd()` would return for a file on disk.


# `.parse_rd_name()` — Resolve a topic's name, preferring its \\name{} tag _(private)_

**Package:** pkgmd · **Version:** 0.1

The Rd database's list name (`rd_name`, typically `"function_name.Rd"`) is usually identical to the topic's own \\name{} tag, but not always - e.g. dplyr's `group_by_prepare.Rd` declares \\name{distinct_prepare}. The \\name{} tag is what `?topic` and cross-references actually resolve against, so it takes priority; the filename-derived name is only a fallback for the (invalid, but not worth hard-failing on) case where \\name{} is missing.

## Usage

```r
.parse_rd_name(rd, rd_name)
```

## Arguments

| Argument | Description |
|----------|-------------|
| `rd` | An `Rd` object. |
| `rd_name` | Name of the Rd entry (list name from the Rd database). |

## Value

A single string.


# `.parse_rd_sections()` — Extract all \\section{title}{body} blocks of an Rd object _(private)_

**Package:** pkgmd · **Version:** 0.1

Unlike the other top-level tags (\\details{}, \\value{}, ...), \\section{} can appear multiple times per topic, each with its own title - e.g. dplyr's `mutate.Rd` has separate "Useful mutate functions", "Grouped tibbles", and "Methods" sections.

## Usage

```r
.parse_rd_sections(rd)
```

## Arguments

| Argument | Description |
|----------|-------------|
| `rd` | An `Rd` object. |

## Value

A list of `list(title, body)` pairs, `body` rendered as Tier 3 Markdown via `.rd_to_block_md()`.


# `.parse_rd_topic()` — Parse a single Rd object into an internal list _(private)_

**Package:** pkgmd · **Version:** 0.1

Converts an `Rd` object (from either `tools::Rd_db()` or `tools::parse_Rd()`) into a flat list consumable by `render_md.R`. `title`/arguments[].name/arguments[].description/`value`/`seealso` are single-line-safe text via `.rd_to_text()` (Tier 2 - table cells and the page title can't contain a literal newline). `description`/ `details`/`format`/`note`/`source`/`references`/`author`/each section's body are full multi-paragraph Markdown via `.rd_to_block_md()` (Tier 3), since they commonly contain \\itemize{}, \\describe{}, \\subsection{}{}, etc. that Tier 2 would flatten into unreadable prose.

## Usage

```r
.parse_rd_topic(rd, rd_name, package, exported_names = NULL)
```

## Arguments

| Argument | Description |
|----------|-------------|
| `rd` | A single `Rd` object. |
| `rd_name` | Name of the Rd entry (list name from the Rd database, typically `"function_name.Rd"`). |
| `package` | Name of the package this topic belongs to. |
| `exported_names` | Character vector of the package's exported names (see `.read_exported_names()`), or `NULL` if unknown. Drives `is_private` (see `.compute_is_private()`); has no other effect. |

## Value

A list with fields `name`, `package`, `aliases`, `is_private`, `title`, `description`, `usage`, `arguments`, `details`, `sections`, `format`, `value`, `examples`, `seealso`, `note`, `source`, `references`, `author`.


# `.parse_rd_usage()` — Extract the \\usage{} block as preformatted code _(private)_

**Package:** pkgmd · **Version:** 0.1

Uses `.rd_to_raw_text()` (Tier 1), not `.rd_to_text()` - usage is R code, so exact spacing/indentation (e.g. across multi-line signatures) must be preserved verbatim rather than collapsed.

## Usage

```r
.parse_rd_usage(rd)
```

## Arguments

| Argument | Description |
|----------|-------------|
| `rd` | An `Rd` object. |

## Value

String with the usage code (no backtick fence).


# `.rd_inline_piece()` — Render one Rd child node as an inline Markdown piece _(private)_

**Package:** pkgmd · **Version:** 0.1

Dispatches to `.leaf_rd_text()` for non-list (leaf) nodes; special-cases \\method{generic}{class} (rendered as `generic.class`, the convention used in \\usage{} for S3 method signatures) and the common inline formatting tags (\\code, \\emph, \\href, ...). Nodes that are lists but not a recognized tag (e.g. \\item, or an unnamed wrapper list) are treated as transparent containers via a plain recursive `.rd_to_text()` call.

## Usage

```r
.rd_inline_piece(x, in_code = FALSE)
```

## Arguments

| Argument | Description |
|----------|-------------|
| `x` | A single Rd child node (leaf or list). |
| `in_code` | Whether `x` is already nested inside a code-styled wrapper - see `.rd_to_text()`. |

## Value

A string fragment.


# `.rd_raw_piece()` — Render one Rd child node as raw text (no whitespace/inline formatting) _(private)_

**Package:** pkgmd · **Version:** 0.1

Render one Rd child node as raw text (no whitespace/inline formatting)

## Usage

```r
.rd_raw_piece(x)
```

## Arguments

| Argument | Description |
|----------|-------------|
| `x` | A single Rd child node (leaf or list). |

## Value

A string fragment.


# `.rd_to_block_md()` — Render a list of Rd block-level children as multi-paragraph Markdown _(private)_

**Package:** pkgmd · **Version:** 0.1

This is "Tier 3" of pkgmd's text extraction (see `.rd_to_text()` for Tier 2 and `.rd_to_raw_text()` for Tier 1): unlike those, which produce single-line-safe text, `.rd_to_block_md()` walks Rd content and produces real multi-line Markdown — paragraphs, bullet/numbered lists, nested subsection headings, and fenced code blocks — instead of flattening everything to a single run of prose. Use it for \\description{} and \\details{}, which commonly contain \\itemize{}, \\enumerate{}, \\subsection{}{}, and \\preformatted{}.

## Usage

```r
.rd_to_block_md(rd, heading_level = 3)
```

## Arguments

| Argument | Description |
|----------|-------------|
| `rd` | A list of Rd fragments. |
| `heading_level` | Heading depth for any \\subsection{}{} found at this level (e.g. `3` renders ### Title). Nested subsections increase this by 1 per level. |

## Details

`rd` is expected to already be a plain list of block-level children (e.g. from `.first_rd_tag_children()` or, for a \\subsection{}{} body, `subsection_node[[2]]` directly) — not wrapped in an outer singleton list the way `.get_rd_tag()` returns matches.

## Value

A single Markdown string with blank lines between block segments.


# `.rd_to_raw_text()` — Flatten an Rd fragment to raw, unnormalized text _(private)_

**Package:** pkgmd · **Version:** 0.1

Like `.rd_to_text()`, but performs **no** whitespace normalization (beyond the `.leaf_rd_text()` `USERMACRO` handling) and applies no inline Markdown formatting. This is "Tier 1" of pkgmd's text extraction: use it for code content (\\usage{}, \\examples{}, \\preformatted{}) where exact spacing and indentation must survive verbatim. Callers should `trimws()` the result themselves to drop leading/trailing edges without touching internal formatting.

## Usage

```r
.rd_to_raw_text(rd)
```

## Arguments

| Argument | Description |
|----------|-------------|
| `rd` | An Rd fragment or a list of Rd fragments. |

## Details

Also special-cases \\method{generic}{class} the same way `.rd_inline_piece()` does (rendered as `generic.class`) - \\usage{} is the main place this construct appears, and it's Tier 1 content.

## Value

A single string with internal whitespace untouched.


# `.rd_to_text()` — Flatten an Rd text fragment into a single string, with inline Markdown _(private)_

**Package:** pkgmd · **Version:** 0.1

Rd fragments are themselves nested lists of text and tag nodes (e.g. for \\code{} or \\link{}). `.rd_to_text()` recursively reduces a fragment to a single-line-safe string, normalizing horizontal whitespace, and renders common _inline_ Rd tags as their Markdown equivalent (\\code{} -> `` `x` ``, \\emph{} -> _x_, \\href{}{} -> [text](url), etc. - see `.rd_inline_piece()`) rather than silently stripping them to plain text.

## Usage

```r
.rd_to_text(rd, in_code = FALSE)
```

## Arguments

| Argument | Description |
|----------|-------------|
| `rd` | An Rd fragment or a list of Rd fragments. |
| `in_code` | Whether this call is already nested inside a code-styled wrapper (\\code{}/\\command{}/\\link{}). Threaded through recursion so that e.g. \\code{\link{x}} (an extremely common pattern) renders as a single `` `x` `` instead of doubly-wrapped x - each nested code-styled tag only adds backticks when it isn't already inside one. |

## Details

Some Rd macros (e.g. \\I{}) are parsed into a leaf node tagged `"USERMACRO"` whose value is a character vector like `c("#1", "bar")` - a #N placeholder token followed by the actual substituted text, rather than a plain scalar. Placeholder tokens are dropped so the substituted text is used (see `.leaf_rd_text()`).

This is "Tier 2" of pkgmd's text extraction (single-line inline). Use `.rd_to_raw_text()` ("Tier 1") instead for code content (\\usage{}/\\examples{}/\\preformatted{}) where exact whitespace must survive, and `.rd_to_block_md()` ("Tier 3", in `render_rd_block.R`) for rich multi-paragraph content (\\description{}/\\details{}) that may contain lists, subsections, or code blocks.

## Value

A single, trimmed string.


# `.read_exported_names()` — Determine a package's exported names, for flagging private topics _(private)_

**Package:** pkgmd · **Version:** 0.1

Dispatches based on `.is_source_path()`, mirroring `.read_rd_db()`.

## Usage

```r
.read_exported_names(package)
```

## Arguments

| Argument | Description |
|----------|-------------|
| `package` | Name of an installed package, or a path to a local package source directory. |

## Value

Character vector of exported names, or `NULL` if export status couldn't be determined (see the installed/source variants for when that happens) - callers should treat `NULL` as "unknown", not as "no exports".


# `.read_exported_names_installed()` — Determine an installed package's exported names via its namespace _(private)_

**Package:** pkgmd · **Version:** 0.1

`getNamespaceExports()` is the only fully correct way to get this list - it's what R itself resolves `export()`/`exportPattern()`/etc. down to, so hand-parsing the `NAMESPACE` file here would mean reimplementing that resolution (including regex `exportPattern()` matching against the namespace's actual contents). The cost is that it loads the package's namespace if not already loaded - unlike `.read_rd_db_installed()`'s existence check, this is unavoidable here since the actual export list can only come from the loaded namespace itself. Wrapped in `tryCatch()` so a package that fails to load degrades to "unknown" (`NULL`) rather than aborting the whole reference build - `include_private` simply has nothing to filter on in that case, same as before this feature existed.

## Usage

```r
.read_exported_names_installed(package)
```

## Arguments

| Argument | Description |
|----------|-------------|
| `package` | Name of an installed package. |

## Value

Character vector of exported names, or `NULL` if the namespace couldn't be loaded.


# `.read_exported_names_source()` — Determine a source package's exported names from its `NAMESPACE` file _(private)_

**Package:** pkgmd · **Version:** 0.1

Parses explicit `export(name)` directives (line-per-symbol, the convention `roxygen2::document()` writes) rather than loading the package - a dev package is often not in a loadable state. Doesn't resolve `exportPattern()` regexes (rare in roxygen2-generated `NAMESPACE` files; common only in hand-written classic ones) - a topic exported only via such a pattern would be misflagged as private, a known, minor limitation.

## Usage

```r
.read_exported_names_source(path)
```

## Arguments

| Argument | Description |
|----------|-------------|
| `path` | Path to a local package source directory. |

## Value

Character vector of exported names, or `NULL` if no `NAMESPACE` file exists yet (e.g. a dev package that has never run `devtools::document()`) - export status is simply unknown then, not "nothing is exported".


# `.read_package_metadata()` — Resolve package name and version, for either an installed or a source package _(private)_

**Package:** pkgmd · **Version:** 0.1

For an installed package, name/version come from `utils::packageVersion()`. For a development package, they are read from the `DESCRIPTION` file in the source directory via `read.dcf()` - this deliberately avoids requiring installation.

## Usage

```r
.read_package_metadata(package)
```

## Arguments

| Argument | Description |
|----------|-------------|
| `package` | Name of an installed package, or a path to a local package source directory. |

## Value

A list with fields `name`, `version`.


# `.read_rd_db()` — Read the Rd documentation of a package, installed or in development _(private)_

**Package:** pkgmd · **Version:** 0.1

Dispatches based on `.is_source_path()`: an installed package name goes through `.read_rd_db_installed()`, while a path to a local package source directory goes through `.read_rd_db_source()`.

## Usage

```r
.read_rd_db(package)
```

## Arguments

| Argument | Description |
|----------|-------------|
| `package` | Name of an installed package, or a path to a local package source directory (detected via a `DESCRIPTION` file at that path). |

## Value

A named list of `Rd` objects (one entry per documented topic).


# `.read_rd_db_installed()` — Read the Rd database of an installed package _(private)_

**Package:** pkgmd · **Version:** 0.1

Thin wrapper around `tools::Rd_db()` that checks the package is actually installed first and raises a helpful error otherwise.

## Usage

```r
.read_rd_db_installed(package)
```

## Arguments

| Argument | Description |
|----------|-------------|
| `package` | Name of an installed package, e.g. `"dplyr"`. |

## Value

A named list of `Rd` objects, as returned by `tools::Rd_db()`.


# `.read_rd_db_source()` — Read the Rd documentation of a package straight from its source tree _(private)_

**Package:** pkgmd · **Version:** 0.1

Used for development packages that have not been installed. Reads every man/*.Rd file in `path` via `tools::parse_Rd()`. If man/ is missing or empty, falls back to a live, in-memory parse via `roxygen2::parse_package(path)` — only attempted if the `roxygen2` namespace is available; otherwise raises an error pointing the user at `devtools::document()`.

## Usage

```r
.read_rd_db_source(path)
```

## Arguments

| Argument | Description |
|----------|-------------|
| `path` | Path to a local package source directory (contains a `DESCRIPTION` file). |

## Value

A named list of `Rd` objects, in the same shape as `tools::Rd_db()` would return for an installed package.


# `.render_aliases_line()` — Render a compact "Aliases:" line for aliases not already in the heading _(private)_

**Package:** pkgmd · **Version:** 0.1

`topic$aliases` commonly includes the topic's own name plus every name already surfaced via `.render_topic_heading()` (e.g. S3 method aliases, or the callable names of a multi-function topic) - repeating those here would be redundant. Only genuinely additional aliases are listed, so e.g. `lag()` stays findable even though the topic file itself is named `lead-lag.md`.

## Usage

```r
.render_aliases_line(topic)
```

## Arguments

| Argument | Description |
|----------|-------------|
| `topic` | Parsed topic list. |

## Value

Markdown string, possibly empty.


# `.render_arguments_section()` — Render the arguments table, if present _(private)_

**Package:** pkgmd · **Version:** 0.1

Cell content is escaped via `.escape_table_pipe()` - argument descriptions are free-form prose that may legitimately contain a literal `|` (e.g. "TRUE or FALSE"), which would otherwise terminate the cell early and break the rest of the table.

## Usage

```r
.render_arguments_section(topic)
```

## Arguments

| Argument | Description |
|----------|-------------|
| `topic` | Parsed topic list. |

## Value

Markdown string, possibly empty.


# `.render_author_section()` — Render the author section, if present _(private)_

**Package:** pkgmd · **Version:** 0.1

Render the author section, if present

## Usage

```r
.render_author_section(topic)
```

## Arguments

| Argument | Description |
|----------|-------------|
| `topic` | Parsed topic list. |

## Value

Markdown string, possibly empty.


# `.render_description_section()` — Render the description section, if present _(private)_

**Package:** pkgmd · **Version:** 0.1

Render the description section, if present

## Usage

```r
.render_description_section(topic)
```

## Arguments

| Argument | Description |
|----------|-------------|
| `topic` | Parsed topic list. |

## Value

Markdown string, possibly empty.


# `.render_details_section()` — Render the details section, if present _(private)_

**Package:** pkgmd · **Version:** 0.1

`topic$details` is already multi-paragraph Markdown produced by `.rd_to_block_md()` (lists, subsections, code blocks may all be present), so it's interpolated as-is rather than wrapped as a single line.

## Usage

```r
.render_details_section(topic)
```

## Arguments

| Argument | Description |
|----------|-------------|
| `topic` | Parsed topic list. |

## Value

Markdown string, possibly empty.


# `.render_examples_section()` — Render the examples section as a <details> block, if present _(private)_

**Package:** pkgmd · **Version:** 0.1

Render the examples section as a <details> block, if present

## Usage

```r
.render_examples_section(topic)
```

## Arguments

| Argument | Description |
|----------|-------------|
| `topic` | Parsed topic list. |

## Value

Markdown string, possibly empty.


# `.render_format_section()` — Render the format section, if present _(private)_

**Package:** pkgmd · **Version:** 0.1

\\format{} is where dataset topics (e.g. `starwars`, `storms`) describe their variables - almost always via \\describe{}, handled as Tier 3 Markdown like \\details{}.

## Usage

```r
.render_format_section(topic)
```

## Arguments

| Argument | Description |
|----------|-------------|
| `topic` | Parsed topic list. |

## Value

Markdown string, possibly empty.


# `.render_full_reference_md()` — Render every topic into a single Markdown string _(private)_

**Package:** pkgmd · **Version:** 0.1

The shared core of _full_reference.md (written by `.write_full_reference_file()`) and `get_documentation()` (returned directly, no file written) - both want the exact same content, one to disk and one in memory.

## Usage

```r
.render_full_reference_md(topics, package, version)
```

## Arguments

| Argument | Description |
|----------|-------------|
| `topics` | List of parsed topic lists. |
| `package` | Package name. |
| `version` | Package version. |

## Value

A single Markdown string.


# `.render_index_md()` — Render the `README.md` index file for a reference output directory _(private)_

**Package:** pkgmd · **Version:** 0.1

Each row's "Topic" cell uses the same heading identifier as the topic's own file (see `.render_topic_heading()`) - callable names get (), datasets/concept pages don't - plus the same _(private)_ marker (see `.render_private_badge()`) if applicable. Aliases beyond that (e.g. `lag()` alongside a `lead-lag` topic named after both) get their own column so they stay findable even though they don't have their own file/row - see `.render_aliases_line()` for the same logic applied to the topic file itself. Title and alias cells are pipe-escaped (see `.escape_table_pipe()`) since both are free-form text that could contain a literal `|`.

## Usage

```r
.render_index_md(topics, package, version)
```

## Arguments

| Argument | Description |
|----------|-------------|
| `topics` | List of parsed topic lists. |
| `package` | Package name. |
| `version` | Package version. |

## Value

A single Markdown string (contents of `README.md`).


# `.render_note_section()` — Render the note section, if present _(private)_

**Package:** pkgmd · **Version:** 0.1

Render the note section, if present

## Usage

```r
.render_note_section(topic)
```

## Arguments

| Argument | Description |
|----------|-------------|
| `topic` | Parsed topic list. |

## Value

Markdown string, possibly empty.


# `.render_private_badge()` — Render a _(private)_ marker for topics outside the public API _(private)_

**Package:** pkgmd · **Version:** 0.1

Render a _(private)_ marker for topics outside the public API

## Usage

```r
.render_private_badge(topic)
```

## Arguments

| Argument | Description |
|----------|-------------|
| `topic` | Parsed topic list. |

## Value

`" _(private)_"`, or `""` if `topic$is_private` isn't `TRUE`.


# `.render_rd_describe()` — Render a \\describe{} node as a Markdown definition-style bullet list _(private)_

**Package:** pkgmd · **Version:** 0.1

Unlike \\itemize{}/\\enumerate{}, whose \\item is a bare marker, \\describe{}'s \\item{term}{description} is a proper 2-child container - the same shape as \\arguments{}'s \\item{name}{desc}. Markdown has no widely-supported definition-list syntax on GitHub/Gitea, so each entry is rendered as - **term**: description.

## Usage

```r
.render_rd_describe(x)
```

## Arguments

| Argument | Description |
|----------|-------------|
| `x` | A \\describe{} Rd node. |

## Value

A Markdown string, one - **term**: description line per item.


# `.render_rd_enumerate()` — Render an \\enumerate{} node as a Markdown numbered list _(private)_

**Package:** pkgmd · **Version:** 0.1

Each item is collapsed to a single line - see `.render_rd_itemize()` for why.

## Usage

```r
.render_rd_enumerate(x)
```

## Arguments

| Argument | Description |
|----------|-------------|
| `x` | An \\enumerate{} Rd node. |

## Value

A Markdown string, one N. item line per item.


# `.render_rd_figure_alt()` — Render one \\figure{file}{options} node as its alt text, if any _(private)_

**Package:** pkgmd · **Version:** 0.1

We can't usefully embed a remote image in Markdown output meant to render in GitHub/Gitea, so \\figure{} is reduced to whatever alt text its `options` argument specifies (`options: alt='...'`), or dropped entirely if there is none. In practice \\figure{} is almost always reached through \\ifelse{html}{\figure{...}}{...} (e.g. lifecycle badges), where the "no" branch already supplies a clean plain-text fallback and this function is never called - it exists for the rarer case of a bare \\figure{} with no such alternative.

## Usage

```r
.render_rd_figure_alt(x)
```

## Arguments

| Argument | Description |
|----------|-------------|
| `x` | A \\figure{} Rd node. |

## Value

The alt text, or `""`.


# `.render_rd_itemize()` — Render an \\itemize{} node as a Markdown bullet list _(private)_

**Package:** pkgmd · **Version:** 0.1

Each item is collapsed to a single line via `.collapse_whitespace()`, same as a table cell. Rd source hard-wraps item text across lines for readability; left as raw newlines, a continuation line isn't reliably recognized as part of the same list item across Markdown renderers (and can be actively misread as a new block - a line that happens to start with a digit and `.`, or contains something like <table>, is ambiguous or gets parsed as literal HTML). GitHub/Gitea compatibility requires each bullet to be self-contained on one line.

## Usage

```r
.render_rd_itemize(x)
```

## Arguments

| Argument | Description |
|----------|-------------|
| `x` | An \\itemize{} Rd node. |

## Value

A Markdown string, one `- item` line per item.


# `.render_rd_out_as_code()` — Render an \\out{} node's raw HTML as a fenced Markdown code block _(private)_

**Package:** pkgmd · **Version:** 0.1

Strips HTML tags and decodes common entities rather than attempting to actually parse the HTML - good enough to turn e.g. <div class="sourceCode r">mutate(x) #&gt; result</div> into readable ```r mutate(x) #> result ``` , not pixel-perfect HTML rendering (which Markdown can't do anyway).

## Usage

```r
.render_rd_out_as_code(out_node)
```

## Arguments

| Argument | Description |
|----------|-------------|
| `out_node` | An \\out{} Rd node. |

## Details

roxygen2's Markdown fenced-code support compiles a single fenced block into _three_ separate top-level nodes: an opening \\if{html}{\out{<div class="sourceCode r">}}, the actual code as a plain \\preformatted{} (portable across all output formats, already handled by `.render_rd_preformatted()`), and a closing \\if{html}{\out{</div>}}. The opening/closing wrapper nodes have no real content once their tags are stripped - returning `NULL` instead of an empty fence for those lets the caller skip them entirely rather than emitting spurious empty ``` blocks around the real one.

## Value

A fenced Markdown code block, or `NULL` if it has no content once HTML tags are stripped (a pure wrapper tag, not real code).


# `.render_rd_preformatted()` — Render a \\preformatted{} node as a fenced Markdown code block _(private)_

**Package:** pkgmd · **Version:** 0.1

Uses `.rd_to_raw_text()` (Tier 1) rather than `.rd_to_text()`, since preformatted content's exact spacing/indentation must be preserved verbatim. No language tag is added to the fence, since preformatted content isn't necessarily R code.

## Usage

```r
.render_rd_preformatted(x)
```

## Arguments

| Argument | Description |
|----------|-------------|
| `x` | A \\preformatted{} Rd node. |

## Value

A fenced (```) Markdown code block.


# `.render_rd_subsection()` — Render a \\subsection{title}{body} node as a Markdown heading + body _(private)_

**Package:** pkgmd · **Version:** 0.1

The title is collapsed to a single line via `.collapse_whitespace()` - an ATX heading (### Title) can't contain a literal newline either.

## Usage

```r
.render_rd_subsection(x, heading_level)
```

## Arguments

| Argument | Description |
|----------|-------------|
| `x` | A \\subsection{}{} Rd node (2 children: title, body). |
| `heading_level` | Heading depth for this subsection's own title. |

## Value

A Markdown string: the heading, a blank line, then the recursively rendered body (nested subsections increase `heading_level` by 1).


# `.render_rd_tabular()` — Render a \\tabular{spec}{body} node as a Markdown table _(private)_

**Package:** pkgmd · **Version:** 0.1

`spec` is a column-alignment string like `"ll"` (2 left-aligned columns) or `"lcr"` (left, center, right) - `l`/`c`/`r` map to the corresponding Markdown table alignment marker; anything else defaults to left. `spec` is filtered down to [lcr] characters before use, since the raw Rd source can carry stray whitespace/newlines around the spec that would otherwise shift the character-to-column mapping. Cell text is also pipe-escaped (see `.escape_table_pipe()`) - a literal `|` in cell content would otherwise break the row. Rows that are entirely blank once collapsed (e.g. a spacer \\cr with nothing between it and the next, or trailing whitespace after the last real row) are dropped. The first surviving row becomes the Markdown table's header, since GFM tables require one and Rd's \\tabular{} doesn't distinguish a header row - this matches how such tables are typically authored in practice (a label row followed by data rows).

## Usage

```r
.render_rd_tabular(x)
```

## Arguments

| Argument | Description |
|----------|-------------|
| `x` | A \\tabular{}{} Rd node (2 children: alignment spec, body). |

## Value

A Markdown table string, or `""` if the table has no non-blank rows.


# `.render_references_section()` — Render the references section, if present _(private)_

**Package:** pkgmd · **Version:** 0.1

Render the references section, if present

## Usage

```r
.render_references_section(topic)
```

## Arguments

| Argument | Description |
|----------|-------------|
| `topic` | Parsed topic list. |

## Value

Markdown string, possibly empty.


# `.render_sections()` — Render every \\section{title}{body} block, if any _(private)_

**Package:** pkgmd · **Version:** 0.1

A topic can have any number of these (see `.parse_rd_sections()`), each with its own title - e.g. dplyr's `mutate.Rd` has "Useful mutate functions", "Grouped tibbles", and "Methods". Each renders as its own ## Title heading, in source order.

## Usage

```r
.render_sections(topic)
```

## Arguments

| Argument | Description |
|----------|-------------|
| `topic` | Parsed topic list. |

## Value

Markdown string, possibly empty.


# `.render_seealso_section()` — Render the related-functions section, if present _(private)_

**Package:** pkgmd · **Version:** 0.1

Render the related-functions section, if present

## Usage

```r
.render_seealso_section(topic)
```

## Arguments

| Argument | Description |
|----------|-------------|
| `topic` | Parsed topic list. |

## Value

Markdown string, possibly empty.


# `.render_source_section()` — Render the source section, if present _(private)_

**Package:** pkgmd · **Version:** 0.1

Render the source section, if present

## Usage

```r
.render_source_section(topic)
```

## Arguments

| Argument | Description |
|----------|-------------|
| `topic` | Parsed topic list. |

## Value

Markdown string, possibly empty.


# `.render_topic_heading()` — Render a topic's heading identifier (the part before " - Title") _(private)_

**Package:** pkgmd · **Version:** 0.1

Renders callable names as `` `name()` `` (joined with a middle dot when a topic documents more than one, e.g. `lead()` / `lag()`), or the bare topic name with no parentheses for non-callable topics (datasets, concept/package-overview pages) - see `.callable_names()`.

## Usage

```r
.render_topic_heading(topic)
```

## Arguments

| Argument | Description |
|----------|-------------|
| `topic` | Parsed topic list. |

## Value

A Markdown string fragment.


# `.render_topic_md()` — Render a parsed Rd topic as a Markdown string _(private)_

**Package:** pkgmd · **Version:** 0.1

Produces the full contents of a single function's `.md` file, following the output format defined in `CLAUDE.md` (title line, arguments table, return value, collapsible examples, related functions, footer). Both the R code (comments, roxygen docs) and the rendered Markdown output are in English, per project convention.

## Usage

```r
.render_topic_md(topic, version, footer = TRUE)
```

## Arguments

| Argument | Description |
|----------|-------------|
| `topic` | A parsed topic list, as produced by `.parse_rd_topic()`. |
| `version` | Version string of the documented package. |
| `footer` | Whether to append the "Generated by pkgmd" footer with its relative links. Set to `FALSE` when concatenating many topics into _full_reference.md, where per-topic footers would repeat the same boilerplate dozens of times and the relative links don't resolve usefully anyway. |

## Value

A single Markdown string (the complete file contents).


# `.render_usage_section()` — Render the usage section, if present _(private)_

**Package:** pkgmd · **Version:** 0.1

Render the usage section, if present

## Usage

```r
.render_usage_section(topic)
```

## Arguments

| Argument | Description |
|----------|-------------|
| `topic` | Parsed topic list. |

## Value

Markdown string, possibly empty.


# `.render_value_section()` — Render the return-value section, if present _(private)_

**Package:** pkgmd · **Version:** 0.1

Render the return-value section, if present

## Usage

```r
.render_value_section(topic)
```

## Arguments

| Argument | Description |
|----------|-------------|
| `topic` | Parsed topic list. |

## Value

Markdown string, possibly empty.


# `.resolve_output_dir()` — Resolve `output_dir`, applying the source-package-only default _(private)_

**Package:** pkgmd · **Version:** 0.1

`"md-docs"` is a reasonable default location next to a package's own source (the common `build_reference(".")` workflow), but there's no similarly obvious spot for an installed package's output - defaulting there too could scatter generated docs into an unexpected/unwanted location relative to whatever directory the user happened to be in. So the default only applies when `package` resolves to a local source directory; otherwise a missing `output_dir` is a clear, actionable error rather than a surprising write location.

## Usage

```r
.resolve_output_dir(package, output_dir)
```

## Arguments

| Argument | Description |
|----------|-------------|
| `package` | As passed to `build_reference()`. |
| `output_dir` | As passed to `build_reference()` - `NULL` if the caller didn't supply one. |

## Value

The resolved `output_dir` string.


# `.safe_filename()` — Make a function/topic name safe for use as a filename _(private)_

**Package:** pkgmd · **Version:** 0.1

Replaces characters that are problematic in filenames (e.g. %, <-, `/`) with URL encoding. A leading `.` - the standard R convention for internal helpers (`.get_rd_tag`, `.rd_to_text`, ...), and exactly what `include_private` surfaces - gets a dot- prefix instead (mirroring `roxygen2::document()`'s own man/dot-*.Rd convention): a literal leading dot makes the file invisible to `list.files()` (default `all.files = FALSE`), Finder, and plain `ls`, which would make a documented-and-correctly-flagged-private topic file _look_ undocumented even though it exists on disk. Otherwise-plain alphanumeric names (including any remaining internal `.`/_) are returned unchanged.

## Usage

```r
.safe_filename(name)
```

## Arguments

| Argument | Description |
|----------|-------------|
| `name` | Topic or function name. |

## Value

Filesystem-safe string without file extension.


# `.split_rd_items()` — Split the children of an \\itemize{}/\\enumerate{} node into items _(private)_

**Package:** pkgmd · **Version:** 0.1

Unlike \\arguments{}'s \\item{name}{description} (a proper 2-child container), \\itemize{}/\\enumerate{}'s \\item is a bare marker with no children of its own — an item's actual content is its _following sibling nodes_, up to the next \\item marker (or the end of the list). Content before the first \\item (leading whitespace) is discarded.

## Usage

```r
.split_rd_items(children)
```

## Arguments

| Argument | Description |
|----------|-------------|
| `children` | The children of an \\itemize{}/\\enumerate{} node. |

## Value

A list of items, each itself a list of Rd fragments.


# `.split_rd_table_cells()` — Split one table row's children into cells _(private)_

**Package:** pkgmd · **Version:** 0.1

Split one table row's children into cells

## Usage

```r
.split_rd_table_cells(row_children)
```

## Arguments

| Argument | Description |
|----------|-------------|
| `row_children` | One row from `.split_rd_table_rows()`. |

## Value

A list of cells, each itself a list of Rd fragments.


# `.split_rd_table_rows()` — Split the children of a \\tabular{}{} node's body into rows _(private)_

**Package:** pkgmd · **Version:** 0.1

Like `.split_rd_items()` for \\itemize{}, \\cr is a bare row-separator marker (0 children of its own) rather than a container. Unlike \\item, content _before_ the first \\cr is significant (it's the first row's content, not discardable leading whitespace) - \\tabular{} has no separate per-row start marker the way \\itemize{}'s \\item doubles as both.

## Usage

```r
.split_rd_table_rows(children)
```

## Arguments

| Argument | Description |
|----------|-------------|
| `children` | The children of a \\tabular{}{} node's body (its second argument). |

## Value

A list of rows, each itself a list of Rd fragments (to be further split into cells by `.split_rd_table_cells()`).


# `.strip_html_tags()` — Strip HTML tags from a string _(private)_

**Package:** pkgmd · **Version:** 0.1

Strip HTML tags from a string

## Usage

```r
.strip_html_tags(html)
```

## Arguments

| Argument | Description |
|----------|-------------|
| `html` | Raw HTML string. |

## Value

`html` with every <...> tag removed.


# `.write_full_reference_file()` — Write _full_reference.md (every topic in a single file) _(private)_

**Package:** pkgmd · **Version:** 0.1

Meant for the Claude Code inject via @docs/reference/_full_reference.md. The underscore prefix sorts the file alphabetically to the top of the directory and signals that it is a generated meta file. Each topic section is rendered with `footer = FALSE` - the per-topic "Generated by pkgmd / Back to index" footer and its relative links only make sense in a standalone file, not repeated after every one of potentially hundreds of sections here.

## Usage

```r
.write_full_reference_file(topics, package, version, output_dir)
```

## Arguments

| Argument | Description |
|----------|-------------|
| `topics` | List of parsed topic lists. |
| `package` | Package name. |
| `version` | Package version. |
| `output_dir` | Target directory. |

## Value

Path to the written file, invisibly.


# `.write_index_file()` — Write the `README.md` index file _(private)_

**Package:** pkgmd · **Version:** 0.1

Write the `README.md` index file

## Usage

```r
.write_index_file(topics, package, version, output_dir)
```

## Arguments

| Argument | Description |
|----------|-------------|
| `topics` | List of parsed topic lists. |
| `package` | Package name. |
| `version` | Package version. |
| `output_dir` | Target directory. |

## Value

Path to the written file, invisibly.


# `.write_topic_file()` — Write the Markdown file for a single topic _(private)_

**Package:** pkgmd · **Version:** 0.1

Write the Markdown file for a single topic

## Usage

```r
.write_topic_file(topic, version, output_dir)
```

## Arguments

| Argument | Description |
|----------|-------------|
| `topic` | Parsed topic list. |
| `version` | Package version. |
| `output_dir` | Target directory. |

## Value

Path to the written file, invisibly.


# `.write_utf8_lines()` — Write text to a file as UTF-8, regardless of the platform's locale _(private)_

**Package:** pkgmd · **Version:** 0.1

Plain `writeLines(x, path, useBytes = TRUE)` relies on every string in `x` already carrying a UTF-8 marking that R's `useBytes` path preserves as-is - true on macOS/Linux where the native encoding already is UTF-8, but fragile on Windows locales where a non-UTF-8 native encoding can cause silent mis-encoding. Opening the connection in raw binary mode (`"wb"`) and explicitly marking the text as UTF-8 first (`enc2utf8()`) writes the intended bytes unconditionally, independent of the platform's native encoding, and also sidesteps any newline translation `"w"` mode would otherwise apply.

## Usage

```r
.write_utf8_lines(text, path)
```

## Arguments

| Argument | Description |
|----------|-------------|
| `text` | Character vector to write, one file line per element. |
| `path` | Destination file path. |

## Value

`path`, invisibly.


# `build_reference()` — Generate Markdown reference documentation for a package

**Package:** pkgmd · **Version:** 0.1

Reads the Rd documentation of a package - either installed, or a local development package that has not been installed - renders it as Markdown, and writes one `.md` file per function into `output_dir`. Also produces a `README.md` (index table of all functions) and a _full_reference.md (every function in one file, meant to be injected as LLM context, e.g. via @docs/reference/_full_reference.md in Claude Code).

## Usage

```r
build_reference(
  package = ".",
  output_dir = NULL,
  overwrite = TRUE,
  include_private = TRUE
)
```

## Arguments

| Argument | Description |
|----------|-------------|
| `package` | Name of an installed package, or a path to a local package source directory. Defaults to `"."` - the common case of running `build_reference()` from within the package you're documenting. |
| `output_dir` | Target directory for the generated `.md` files. Created if it does not exist. Defaults to `"md-docs"`, but only when `package` resolves to a local source directory - for an installed package (e.g. `"dplyr"`) there's no similarly obvious default location, so `output_dir` must be given explicitly. |
| `overwrite` | If `TRUE` (the default), any `.md` files already in `output_dir` are removed before writing the new set - this also clears stale files left behind by topics that were since renamed or removed from the package. If `FALSE`, aborts instead when `output_dir` already contains `.md` files, without touching them. |
| `include_private` | If `TRUE` (the default), documented topics that aren't part of the package's public API (i.e. not in its `NAMESPACE` exports - typically internal helpers documented with @keywords internal rather than @export) are included and marked _(private)_ next to their heading, in both the topic file and the index. If `FALSE`, such topics are left out of the output entirely. Datasets and other non-callable topics are never treated as private, even though they also aren't in `NAMESPACE`'s exports - see `.compute_is_private()`. When export status can't be determined at all (a dev package that has never run `devtools::document()`, so it has no `NAMESPACE` file yet), every topic is treated as public. |

## Details

`package` accepts two kinds of input:

- the name of an installed package, e.g. `"dplyr"` - Rd data is read via `tools::Rd_db()`;
- a path to a local package source directory, e.g. `"."` or `"../myotherpkg"` (detected by the presence of a `DESCRIPTION` file at that path) - Rd data is read directly from man/*.Rd, falling back to a live `roxygen2::parse_package()` parse if man/ is missing or empty. This mode does **not** require the package to be installed.

## Value

Invisibly, the path to `output_dir`.

## Examples

<details>
<summary>Show examples</summary>

```r
# Installed package:
pkgmd::build_reference("dplyr", output_dir = "docs/reference")

# Development package, not installed - "." and "md-docs" are both
# defaults, so this is equivalent to just build_reference():
pkgmd::build_reference(".", output_dir = "md-docs")

# Public API only, no internal helpers:
pkgmd::build_reference("dplyr", output_dir = "docs/reference", include_private = FALSE)
```

</details>


# `get_documentation()` — Get a package's full reference documentation as a single string

**Package:** pkgmd · **Version:** 0.1

Returns the same Markdown content that `build_reference()` writes to _full_reference.md - every topic rendered and concatenated into one string - without writing anything to disk. Meant for programmatic consumption, e.g. an LLM agent that wants a package's complete reference injected directly into its context in one call.

## Usage

```r
get_documentation(package = ".", include_private = FALSE)
```

## Arguments

| Argument | Description |
|----------|-------------|
| `package` | As in `build_reference()`. |
| `include_private` | If `TRUE`, documented topics that aren't part of the package's public API are included too - see `build_reference()`. Defaults to `FALSE` here (unlike `build_reference()`'s `TRUE`), since the primary use case - handing a package's reference to an LLM agent as context - usually wants the public API only. |

## Value

A single string: the package's full reference documentation in Markdown.

## Examples

<details>
<summary>Show examples</summary>

```r
# Installed package:
docs <- pkgmd::get_documentation("dplyr")

# Development package, not installed:
docs <- pkgmd::get_documentation(".")
```

</details>


# `%||%()` — Default for `NULL` values _(private)_

**Package:** pkgmd · **Version:** 0.1

Default for `NULL` values

## Usage

```r
x %||% y
```

## Arguments

| Argument | Description |
|----------|-------------|
| `x` | Value to check. |
| `y` | Fallback used when `x` is `NULL`. |

## Value

`x` if not `NULL`, otherwise `y`.


