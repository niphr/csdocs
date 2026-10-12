#' Default for `NULL` values
#'
#' @param x Value to check.
#' @param y Fallback used when `x` is `NULL`.
#' @return `x` if not `NULL`, otherwise `y`.
#' @name op-null-default
#' @keywords internal
`%||%` <- function(x, y) {
  if (is.null(x)) return(y) else return(x)
}

#' Extract all child tags of a given type from an Rd object
#'
#' `tools::Rd_db()` (and `tools::parse_Rd()`) return objects of class `Rd`
#' whose elements carry a `Rd_tag` attribute (e.g. `"\\arguments"`,
#' `"\\description"`). This helper will filter an Rd object (or a list of
#' Rd fragments) down to the direct children matching a given tag.
#'
#' @param rd An `Rd` object or a list of Rd fragments.
#' @param tag Tag name including the leading backslash, e.g. `"\\item"`.
#' @return List of matching Rd fragments (possibly empty).
#' @keywords internal
.get_rd_tag <- function(rd, tag) {
  return(purrr::keep(rd, \(x) identical(attr(x, "Rd_tag"), tag)))
}

#' Get the children of the first Rd node matching a tag
#'
#' A convenience wrapper around [.get_rd_tag()] for the common case of a
#' singleton top-level tag (e.g. a topic's one `\\description{}` block):
#' unwraps the match and returns *its* children directly, ready to hand to
#' a renderer like [.rd_to_block_md()]. Contrast with [.get_rd_tag()]
#' itself, which returns the matching node(s), not their contents.
#'
#' @param rd An `Rd` object or a list of Rd fragments.
#' @param tag Tag name including the leading backslash, e.g. `"\\description"`.
#' @return The children of the first match, or an empty list if there is
#'   no match.
#' @keywords internal
.first_rd_tag_children <- function(rd, tag) {
  matches <- .get_rd_tag(rd, tag)
  if (length(matches) == 0) {
    return(list())
  }
  return(matches[[1]])
}

#' Flatten an Rd text fragment into a single string, with inline Markdown
#'
#' Rd fragments are themselves nested lists of text and tag nodes (e.g. for
#' `\\code{}` or `\\link{}`). `.rd_to_text()` recursively reduces a fragment
#' to a single-line-safe string, normalizing horizontal whitespace, and
#' renders common *inline* Rd tags as their Markdown equivalent (`\\code{}`
#' -> `` `x` ``, `\\emph{}` -> `_x_`, `\\href{}{}` -> `[text](url)`, etc. -
#' see [.rd_inline_piece()]) rather than silently stripping them to plain
#' text.
#'
#' Some Rd macros (e.g. `\\I{}`) are parsed into a leaf node tagged
#' `"USERMACRO"` whose value is a character vector like `c("#1", "bar")` -
#' a `#N` placeholder token followed by the actual substituted text, rather
#' than a plain scalar. Placeholder tokens are dropped so the substituted
#' text is used (see [.leaf_rd_text()]).
#'
#' This is "Tier 2" of csdocs's text extraction (single-line inline). Use
#' [.rd_to_raw_text()] ("Tier 1") instead for code content
#' (`\\usage{}`/`\\examples{}`/`\\preformatted{}`) where exact whitespace
#' must survive, and [.rd_to_block_md()] ("Tier 3", in `render_rd_block.R`)
#' for rich multi-paragraph content (`\\description{}`/`\\details{}`) that
#' may contain lists, subsections, or code blocks.
#'
#' @param rd An Rd fragment or a list of Rd fragments.
#' @param in_code Whether this call is already nested inside a code-styled
#'   wrapper (`\\code{}`/`\\command{}`/`\\link{}`). Threaded through
#'   recursion so that e.g. `\\code{\\link{x}}` (an extremely common
#'   pattern) renders as a single `` `x` `` instead of doubly-wrapped
#'   `` ``x`` ``  -  each nested code-styled tag only adds backticks when
#'   it isn't already inside one.
#' @return A single, trimmed string.
#' @keywords internal
.rd_to_text <- function(rd, in_code = FALSE) {
  if (is.null(rd)) {
    return("")
  }

  pieces <- purrr::map_chr(rd, .rd_inline_piece, in_code = in_code)

  text <- paste(pieces, collapse = "")
  text <- gsub("[ \t]+", " ", text)
  return(trimws(text))
}

#' Render one Rd child node as an inline Markdown piece
#'
#' Dispatches to [.leaf_rd_text()] for non-list (leaf) nodes; special-cases
#' `\\method{generic}{class}` (rendered as `generic.class`, the convention
#' used in `\\usage{}` for S3 method signatures) and the common inline
#' formatting tags (`\\code`, `\\emph`, `\\href`, ...). Nodes that are
#' lists but not a recognized tag (e.g. `\\item`, or an unnamed wrapper
#' list) are treated as transparent containers via a plain recursive
#' [.rd_to_text()] call.
#'
#' @param x A single Rd child node (leaf or list).
#' @param in_code Whether `x` is already nested inside a code-styled
#'   wrapper - see [.rd_to_text()].
#' @return A string fragment.
#' @keywords internal
.rd_inline_piece <- function(x, in_code = FALSE) {
  if (!is.list(x)) {
    return(.leaf_rd_text(x))
  }

  tag <- attr(x, "Rd_tag") %||% ""

  # The four helpers match disjoint sets of tags, so their order does not
  # change the result. Each returns NULL for a tag it does not render.
  helpers <- list(
    .rd_inline_code_piece,
    .rd_inline_format_piece,
    .rd_inline_link_piece,
    .rd_inline_conditional_piece
  )
  for (helper in helpers) {
    piece <- helper(x, tag, in_code)
    if (!is.null(piece)) {
      return(piece)
    }
  }

  return(.rd_to_text(x, in_code = in_code))
}

#' Render an inline Rd node with a code-styled tag
#'
#' Renders `\\method{generic}{class}` as `generic.class`, and `\\code` and
#' `\\command` as a code span. A code span that holds one `\\link` becomes
#' the text of that link, for example ``[`x()`](x.md)``. A helper of
#' [.rd_inline_piece()].
#'
#' @param x A single Rd list node.
#' @param tag The `Rd_tag` of `x`, or `""`.
#' @param in_code As in [.rd_inline_piece()].
#' @return A string fragment, or `NULL` when `tag` is not one of these tags.
#' @keywords internal
.rd_inline_code_piece <- function(x, tag, in_code) {
  if (identical(tag, "\\method") && length(x) == 2) {
    return(paste0(.leaf_or_list_text(x[[1]]), ".", .leaf_or_list_text(x[[2]])))
  }
  if (tag %in% c("\\code", "\\command")) {
    inner <- .rd_to_text(x, in_code = TRUE)
    if (in_code) {
      return(inner)
    }
    return(.wrap_link(.inline_code_span(inner), .rd_code_link_href(x)))
  }
  return(NULL)
}

#' Render an inline Rd node with a text-formatting tag
#'
#' Renders `\\emph`, `\\strong`, `\\bold`, `\\dQuote` and `\\sQuote`. A
#' helper of [.rd_inline_piece()].
#'
#' @inheritParams .rd_inline_code_piece
#' @return A string fragment, or `NULL` when `tag` is not one of these tags.
#' @keywords internal
.rd_inline_format_piece <- function(x, tag, in_code) {
  if (identical(tag, "\\emph")) {
    return(paste0("_", .rd_to_text(x, in_code = in_code), "_"))
  }
  if (tag %in% c("\\strong", "\\bold")) {
    return(paste0("**", .rd_to_text(x, in_code = in_code), "**"))
  }
  if (identical(tag, "\\dQuote")) {
    return(paste0("\u201c", .rd_to_text(x, in_code = in_code), "\u201d"))
  }
  if (identical(tag, "\\sQuote")) {
    return(paste0("\u2018", .rd_to_text(x, in_code = in_code), "\u2019"))
  }
  return(NULL)
}

#' Render an inline Rd node with a link or figure tag
#'
#' Renders `\\link`, `\\linkS4class`, `\\href`, `\\url` and `\\figure`. A
#' `\\link` to a topic of the same package becomes a relative Markdown link
#' when a link map is active (see [.with_link_map()]), and a code span
#' otherwise. A helper of [.rd_inline_piece()]. An `\\href{#X}` to the same
#' page becomes a link to `#x`, in lowercase, because GitHub lowercases the
#' target `id` (see [.render_rd_out_as_code()]).
#'
#' @inheritParams .rd_inline_code_piece
#' @return A string fragment, or `NULL` when `tag` is not one of these tags.
#' @keywords internal
.rd_inline_link_piece <- function(x, tag, in_code) {
  if (tag %in% c("\\link", "\\linkS4class")) {
    label <- .rd_to_text(x, in_code = TRUE)
    if (in_code) {
      return(label)
    }
    return(.wrap_link(.inline_code_span(label), .rd_link_href(x)))
  }
  if (identical(tag, "\\href") && length(x) >= 2) {
    url <- .rd_to_text(x[[1]], in_code = in_code)
    if (startsWith(url, "#")) {
      url <- tolower(url)
    }
    label <- .rd_to_text(x[[2]], in_code = in_code)
    return(glue::glue("[{label}]({url})"))
  }
  if (identical(tag, "\\url")) {
    return(paste0("<", .rd_to_text(x, in_code = in_code), ">"))
  }
  if (identical(tag, "\\figure")) {
    return(.render_rd_figure_alt(x))
  }
  return(NULL)
}

#' Render an inline Rd node with a conditional tag
#'
#' Renders `\\ifelse{cond}{yes}{no}` and `\\if{cond}{body}`. A helper of
#' [.rd_inline_piece()].
#'
#' @inheritParams .rd_inline_code_piece
#' @return A string fragment, or `NULL` when `tag` is not one of these tags.
#' @keywords internal
.rd_inline_conditional_piece <- function(x, tag, in_code) {
  if (identical(tag, "\\ifelse") && length(x) == 3) {
    # \ifelse{cond}{yes}{no}: we render as text/Markdown, so prefer the
    # "yes" branch only for cond == "text" (or "markdown"); everything
    # else (typically "html", the common case for e.g. lifecycle badges)
    # uses the "no" branch, which by convention is the plain-text
    # fallback (e.g. \strong{[Experimental]} alongside an HTML \figure{}).
    cond <- .collapse_whitespace(.rd_to_text(x[[1]]))
    branch <- if (cond %in% c("text", "markdown")) x[[2]] else x[[3]]
    return(.rd_to_text(branch, in_code = in_code))
  }
  if (identical(tag, "\\if") && length(x) == 2) {
    # \if{cond}{body} has no "else" - render body only for a text-ish
    # cond, otherwise contribute nothing. (The \if{html}{\out{...}} code-
    # block pattern is handled separately, at the block level - see
    # render_rd_block.R - since it produces a fenced code block, not
    # inline text.)
    cond <- .collapse_whitespace(.rd_to_text(x[[1]]))
    if (cond %in% c("text", "markdown")) {
      return(.rd_to_text(x[[2]], in_code = in_code))
    }
    return("")
  }
  return(NULL)
}

#' Render one `\\figure{file}{options}` node as its alt text, if any
#'
#' We can't usefully embed a remote image in Markdown output meant to
#' render in GitHub/Gitea, so `\\figure{}` is reduced to whatever alt text
#' its `options` argument specifies (`options: alt='...'`), or dropped
#' entirely if there is none. In practice `\\figure{}` is almost always
#' reached through `\\ifelse{html}{\\figure{...}}{...}` (e.g. lifecycle
#' badges), where the "no" branch already supplies a clean plain-text
#' fallback and this function is never called - it exists for the rarer
#' case of a bare `\\figure{}` with no such alternative.
#'
#' @param x A `\\figure{}` Rd node.
#' @return The alt text, or `""`.
#' @keywords internal
.render_rd_figure_alt <- function(x) {
  if (length(x) < 2) {
    return("")
  }
  options_text <- .leaf_or_list_raw_text(x[[2]])
  match <- regmatches(
    options_text,
    regexec("alt=['\"]([^'\"]*)['\"]", options_text, perl = TRUE)
  )[[1]]
  if (length(match) < 2) {
    return("")
  }
  return(match[2])
}

#' Render one Rd child that may be a bare leaf or a list, as inline text
#' @param part An Rd child - a bare character leaf (e.g. one argument of
#'   `\\method{}{}` or `\\tabular{}{}`'s format spec), or a list.
#' @return A string.
#' @keywords internal
.leaf_or_list_text <- function(part) {
  if (is.list(part)) return(.rd_to_text(part)) else return(.leaf_rd_text(part))
}

#' Flatten an Rd fragment to raw, unnormalized text
#'
#' Like [.rd_to_text()], but performs **no** whitespace normalization
#' (beyond the [.leaf_rd_text()] `USERMACRO` handling) and applies no
#' inline Markdown formatting. This is "Tier 1" of csdocs's text
#' extraction: use it for code content (`\\usage{}`, `\\examples{}`,
#' `\\preformatted{}`) where exact spacing and indentation must survive
#' verbatim. Callers should `trimws()` the result themselves to drop
#' leading/trailing edges without touching internal formatting.
#'
#' Also special-cases `\\method{generic}{class}` the same way
#' [.rd_inline_piece()] does (rendered as `generic.class`) - `\\usage{}`
#' is the main place this construct appears, and it's Tier 1 content.
#'
#' @param rd An Rd fragment or a list of Rd fragments.
#' @return A single string with internal whitespace untouched.
#' @keywords internal
.rd_to_raw_text <- function(rd) {
  if (is.null(rd)) {
    return("")
  }

  pieces <- purrr::map_chr(rd, .rd_raw_piece)

  return(paste(pieces, collapse = ""))
}

#' Render one Rd child node as raw text (no whitespace/inline formatting)
#' @param x A single Rd child node (leaf or list).
#' @return A string fragment.
#' @keywords internal
.rd_raw_piece <- function(x) {
  if (!is.list(x)) {
    return(.leaf_rd_text(x))
  }
  if (identical(attr(x, "Rd_tag"), "\\method") && length(x) == 2) {
    return(paste0(
      .leaf_or_list_raw_text(x[[1]]),
      ".",
      .leaf_or_list_raw_text(x[[2]])
    ))
  }
  return(.rd_to_raw_text(x))
}

#' Render one Rd child that may be a bare leaf or a list, as raw text
#' @param part An Rd child - a bare character leaf or a list.
#' @return A string.
#' @keywords internal
.leaf_or_list_raw_text <- function(part) {
  if (is.list(part)) {
    return(.rd_to_raw_text(part))
  } else {
    return(.leaf_rd_text(part))
  }
}

#' Coerce a single (non-list) Rd node to a scalar string
#'
#' Almost always `as.character(x)` already returns a length-1 string. The
#' exception is `"USERMACRO"`-tagged nodes (from Rd macros like `\\I{}`),
#' whose value is a placeholder token (`"#1"`) followed by the macro's
#' substituted argument (e.g. `c("#1", "bar")`). `tools::parse_Rd()`
#' already duplicates that substituted text into the *following* sibling
#' `TEXT` node as a fallback for consumers that don't understand
#' `USERMACRO` (verified against `tools::Rd2txt()`'s own output) - so a
#' `USERMACRO` node contributes nothing here to avoid rendering the text
#' twice. Any other, unanticipated multi-value leaf is collapsed rather
#' than erroring.
#'
#' @param x A non-list Rd leaf node.
#' @return A single string.
#' @keywords internal
.leaf_rd_text <- function(x) {
  if (identical(attr(x, "Rd_tag"), "USERMACRO")) {
    return("")
  }
  return(paste(as.character(x), collapse = ""))
}

#' Collapse a prose string to a single line
#'
#' Rd source hard-wraps prose (`\\description{}`, `\\item{}{}` descriptions,
#' etc.) at some column width for source readability - those line breaks
#' aren't semantically meaningful. Left in place, they break Markdown
#' tables, since a table cell can't contain a literal newline: text after
#' the break renders as plain content outside the table and everything
#' below it in the same table is broken too. Use this on prose fields
#' only - never on `\\usage{}`/`\\examples{}` content, where newlines are
#' real code line breaks that must be preserved.
#'
#' @param text A string, typically already passed through [.rd_to_text()].
#' @return `text` with all runs of whitespace (including newlines)
#'   collapsed to a single space, trimmed.
#' @keywords internal
.collapse_whitespace <- function(text) {
  return(trimws(gsub("\\s+", " ", text)))
}

#' Determine which of a topic's name/aliases actually look callable
#'
#' A name/alias "looks callable" if it appears followed by `(` in the
#' topic's `\\usage{}` text - e.g. `mutate.Rd` has usage
#' `mutate(.data, ...)`, so `"mutate"` qualifies. Infix operators (e.g.
#' `%||%`, `%>%`) are never followed by `(` in `\\usage{}` - they're
#' invoked as `` x %op% y ``, not `` %op%(x, y) `` - so they get a second
#' check: an operator-shaped name (`^%.+%$`) qualifies if it appears
#' anywhere in a non-empty usage, which is safe precisely because that
#' syntax is unambiguous (never a dataset or concept-page name). Datasets
#' and concept pages (`\\usage{}` is just a bare name, or empty) never
#' qualify either way. A single Rd topic can document several callables
#' at once (e.g. `lead-lag.Rd` documents both `lead()` and `lag()`, with
#' topic name `"lead-lag"` matching neither) - hence this returns a
#' vector, not a single yes/no. Fixed-string matching (not regex) is used
#' for the `name(` check deliberately: Rd names can contain regex
#' metacharacters (`%>%`, `[<-`, ...).
#'
#' Shared by [.render_topic_heading()] in `render_md.R` (decides whether
#' to append `()` to the heading) and [.compute_is_private()] in
#' `parse_rd.R` (a topic whose usage is a bare name - a dataset - is never
#' flagged private just because datasets aren't in `NAMESPACE`'s
#' `export()` list the way functions are; an operator, unlike a dataset,
#' still needs to be checkable against `NAMESPACE`, which is exactly what
#' this second branch enables).
#'
#' @param name Topic name.
#' @param aliases Character vector of the topic's aliases (possibly
#'   empty).
#' @param usage The topic's `\\usage{}` text (possibly `""`).
#' @return Character vector of callable names (possibly empty).
#' @keywords internal
.callable_candidates <- function(name, aliases, usage) {
  usage <- usage %||% ""
  if (!nzchar(usage)) {
    return(character(0))
  }
  candidates <- unique(c(name, aliases %||% character(0)))
  return(purrr::keep(candidates, \(n) .looks_callable(n, usage)))
}

#' Decide whether one name looks callable given a topic's usage text
#' @param name A single candidate name.
#' @param usage The topic's non-empty `\\usage{}` text.
#' @return `TRUE`/`FALSE`.
#' @keywords internal
.looks_callable <- function(name, usage) {
  if (grepl(paste0(name, "("), usage, fixed = TRUE)) {
    return(TRUE)
  }
  return(grepl("^%.+%$", name) && grepl(name, usage, fixed = TRUE))
}

#' Escape literal pipe characters for use in a GFM table cell
#'
#' A raw `|` inside a table cell terminates the cell early and shifts every
#' column after it - breaks the whole row (and often the rows after it, if
#' the shift produces an odd number of remaining `|`s). Rd prose can
#' contain a literal `|` (e.g. documenting an OR condition or `\\tabular{}`
#' cell content), so cell-rendering call sites must escape it before
#' interpolating into a `| cell | cell |` row.
#'
#' @param text A string destined for a table cell.
#' @return `text` with every `|` replaced by `\\|`.
#' @keywords internal
.escape_table_pipe <- function(text) {
  return(gsub("|", "\\|", text, fixed = TRUE))
}

#' Wrap text in an inline code span, widening delimiters to avoid collision
#'
#' A single backtick pair (`` `x` ``) breaks if `x` itself contains a
#' backtick - e.g. base's `Quotes` topic documents the backtick character
#' itself as an alias, and naively wrapping it as `` `` ` `` `` produces a
#' bare 3-backtick run that reads as a fence, not a code span (the same
#' failure mode [.code_fence()] guards against for fenced blocks). Per
#' CommonMark, an inline code span's delimiter must be longer than the
#' longest backtick run in its content, and content starting or ending
#' with a backtick needs a single space of padding on that side so the
#' delimiter doesn't visually fuse with it.
#'
#' @param text The text to wrap (typically an alias, name, or other short
#'   Rd-sourced token, not a full code block - see [.code_fence()] for
#'   that).
#' @return A single string: `text` wrapped in backticks.
#' @keywords internal
.inline_code_span <- function(text) {
  runs <- gregexpr("`+", text, perl = TRUE)[[1]]
  run_lengths <- attr(runs, "match.length")
  longest_run <- if (identical(runs[1], -1L)) 0L else max(run_lengths)
  delim <- strrep("`", max(1L, longest_run + 1L))

  needs_padding <- identical(text, "") || grepl("^`", text) || grepl("`$", text)
  if (needs_padding) {
    return(paste0(delim, " ", text, " ", delim))
  } else {
    return(paste0(delim, text, delim))
  }
}

#' Pick a backtick fence long enough to safely wrap some code
#'
#' A fixed ` ``` ` fence breaks if the code itself contains a run of 3+
#' backticks (e.g. code that documents Markdown syntax, or nested code
#' blocks) - the fence closes prematurely at the first embedded run. Per
#' CommonMark, a fence must be *longer* than the longest backtick run
#' appearing in its content.
#'
#' @param code The code the fence will wrap.
#' @return A string of backticks, at least 3 and at least one longer than
#'   the longest backtick run found in `code`.
#' @keywords internal
.code_fence <- function(code) {
  runs <- gregexpr("`+", code, perl = TRUE)[[1]]
  run_lengths <- attr(runs, "match.length")
  longest_run <- if (identical(runs[1], -1L)) 0L else max(run_lengths)
  return(strrep("`", max(3L, longest_run + 1L)))
}

#' Make a function/topic name safe for use as a filename
#'
#' Replaces characters that are problematic in filenames (e.g. `%`, `<-`,
#' `/`) with URL encoding. A leading `.` - the standard R convention for
#' internal helpers (`.get_rd_tag`, `.rd_to_text`, ...), and exactly what
#' `include_private` surfaces - gets a `dot-` prefix instead (mirroring
#' `roxygen2::document()`'s own `man/dot-*.Rd` convention): a literal
#' leading dot makes the file invisible to `list.files()` (default
#' `all.files = FALSE`), Finder, and plain `ls`, which would make a
#' documented-and-correctly-flagged-private topic file *look* undocumented
#' even though it exists on disk. Otherwise-plain alphanumeric names
#' (including any remaining internal `.`/`_`) are returned unchanged.
#'
#' @param name Topic or function name.
#' @return Filesystem-safe string without file extension.
#' @keywords internal
.safe_filename <- function(name) {
  if (grepl("^\\.", name)) {
    name <- paste0("dot-", sub("^\\.+", "", name))
  }
  if (grepl("^[A-Za-z0-9._-]+$", name)) {
    return(name)
  }
  return(utils::URLencode(name, reserved = TRUE))
}

#' Write text to a file as UTF-8, regardless of the platform's locale
#'
#' Plain `writeLines(x, path, useBytes = TRUE)` relies on every string in
#' `x` already carrying a UTF-8 marking that R's `useBytes` path preserves
#' as-is - true on macOS/Linux where the native encoding already is UTF-8,
#' but fragile on Windows locales where a non-UTF-8 native encoding can
#' cause silent mis-encoding. Opening the connection in raw binary mode
#' (`"wb"`) and explicitly marking the text as UTF-8 first
#' (`enc2utf8()`) writes the intended bytes unconditionally, independent
#' of the platform's native encoding, and also sidesteps any newline
#' translation `"w"` mode would otherwise apply.
#'
#' @param text Character vector to write, one file line per element.
#' @param path Destination file path.
#' @return `path`, invisibly.
#' @keywords internal
.write_utf8_lines <- function(text, path) {
  con <- file(path, open = "wb")
  on.exit(close(con))
  writeLines(enc2utf8(text), con, useBytes = TRUE)
  return(invisible(path))
}

#' Detect whether `package` refers to a local package source directory
#'
#' Used to dispatch between the installed-package path (`tools::Rd_db()`)
#' and the development-package path (reading `man/*.Rd` directly, or
#' falling back to a live `roxygen2::parse_package()` parse). A path is
#' treated as a package source directory if it exists on disk and contains
#' a `DESCRIPTION` file.
#'
#' @param package Value passed by the caller to `build_reference()` -
#'   either an installed package name or a path to a package source
#'   directory.
#' @return `TRUE` if `package` is a local source directory, `FALSE`
#'   otherwise (i.e. it should be treated as an installed package name).
#' @keywords internal
.is_source_path <- function(package) {
  return(
    fs::dir_exists(package) && fs::file_exists(fs::path(package, "DESCRIPTION"))
  )
}
