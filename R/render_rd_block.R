#' Render a list of Rd block-level children as multi-paragraph Markdown
#'
#' This is "Tier 3" of csdocs's text extraction (see [.rd_to_text()] for
#' Tier 2 and [.rd_to_raw_text()] for Tier 1): unlike those, which produce
#' single-line-safe text, `.rd_to_block_md()` walks Rd content and produces
#' real multi-line Markdown — paragraphs, bullet/numbered lists, nested
#' subsection headings, and fenced code blocks — instead of flattening
#' everything to a single run of prose. Use it for `\\description{}` and
#' `\\details{}`, which commonly contain `\\itemize{}`, `\\enumerate{}`,
#' `\\subsection{}{}`, and `\\preformatted{}`. It also renders the
#' top-level `\\item{name}{desc}` nodes of `\\value{}` as a list.
#'
#' `rd` is expected to already be a plain list of block-level children
#' (e.g. from [.first_rd_tag_children()] or, for a `\\subsection{}{}`
#' body, `subsection_node[[2]]` directly) — not wrapped in an outer
#' singleton list the way [.get_rd_tag()] returns matches.
#'
#' @param rd A list of Rd fragments.
#' @param heading_level Heading depth for any `\\subsection{}{}` found at
#'   this level (e.g. `3` renders `### Title`). Nested subsections
#'   increase this by 1 per level.
#' @return A single Markdown string with blank lines between block
#'   segments.
#' @keywords internal
.rd_to_block_md <- function(rd, heading_level = 3) {
  if (is.null(rd) || length(rd) == 0) {
    return("")
  }

  pieces <- lapply(rd, .rd_block_piece, heading_level = heading_level)
  kinds <- vapply(pieces, \(piece) piece$kind, character(1))
  # Whitespace after an \item{}{} belongs to the item list.
  for (i in seq_along(kinds)[-1]) {
    if (kinds[i - 1] == "item" && .is_blank_rd_text(rd[[i]])) {
      kinds[i] <- "item"
    }
  }
  starts <- c(TRUE, kinds[-1] != kinds[-length(kinds)] | kinds[-1] == "block")
  runs <- split(seq_along(pieces), cumsum(starts))
  segments <- lapply(runs, \(idx) .render_block_run(pieces[idx], kinds[idx[1]]))

  return(paste(unlist(segments), collapse = "\n\n"))
}

#' Classify one Rd child of a block for [.rd_to_block_md()]
#'
#' @param child One Rd node.
#' @param heading_level As in [.rd_to_block_md()].
#' @return A list. `kind` is `"block"` or `"item"`, with the Markdown in
#'   `md`, or `"inline"`, with the Rd node in `node`.
#' @keywords internal
.rd_block_piece <- function(child, heading_level) {
  tag <- attr(child, "Rd_tag")
  # An R6 anchor or "Inherited methods" block, see .if_out_html_block().
  html_block <- .if_out_html_block(child)
  if (!is.null(html_block)) {
    return(list(kind = "block", md = html_block))
  }
  renderer <- .rd_block_renderer(tag, heading_level)
  if (!is.null(renderer)) {
    return(list(kind = "block", md = renderer(child)))
  }
  # \item{name}{desc} at the top level, as in \value{}.
  if (identical(tag, "\\item") && length(child) >= 2) {
    return(list(kind = "item", md = .render_rd_named_item(child)))
  }
  return(list(kind = "inline", node = child))
}

#' Render one run of pieces of the same kind
#'
#' @param pieces A list of pieces from [.rd_block_piece()].
#' @param kind The `kind` of the run.
#' @return A Markdown string, or `NULL` when an inline run has no text.
#' @keywords internal
.render_block_run <- function(pieces, kind) {
  if (kind == "block") {
    return(pieces[[1]]$md)
  }
  if (kind == "item") {
    return(paste(unlist(lapply(pieces, \(piece) piece$md)), collapse = "\n"))
  }
  nodes <- lapply(pieces, \(piece) piece$node)
  text <- .normalize_block_whitespace(.rd_to_text(nodes))
  if (!nzchar(text)) {
    return(NULL)
  }
  return(text)
}

#' Find the renderer for a block-level Rd tag
#'
#' [.rd_to_block_md()] renders six block-level tags, each with its own
#' renderer. A tag matches only when it is [identical()] to one of them.
#'
#' @param tag The `Rd_tag` attribute of one Rd child node, or `NULL`.
#' @param heading_level As in [.rd_to_block_md()]. Only the
#'   `\\subsection{}{}` renderer uses it.
#' @return A function of one Rd node that returns a Markdown string, or
#'   `NULL` when `tag` is not a block-level tag.
#' @keywords internal
.rd_block_renderer <- function(tag, heading_level) {
  renderers <- list(
    "\\itemize" = .render_rd_itemize,
    "\\enumerate" = .render_rd_enumerate,
    "\\describe" = .render_rd_describe,
    "\\subsection" = \(node) .render_rd_subsection(node, heading_level),
    "\\preformatted" = .render_rd_preformatted,
    "\\tabular" = .render_rd_tabular
  )
  for (name in names(renderers)) {
    if (identical(tag, name)) {
      return(renderers[[name]])
    }
  }
  return(NULL)
}

#' Collapse a block of prose to paragraphs, preserving paragraph breaks
#'
#' Rd source hard-wraps prose at some column width for source readability
#' (see [.collapse_whitespace()] for the single-line equivalent used in
#' table cells) - those line breaks aren't semantically meaningful and are
#' joined back into flowing text. A blank line in the source (2+
#' consecutive newlines), however, *is* a meaningful paragraph break and is
#' preserved as exactly one blank line.
#'
#' @param text A string, typically already passed through [.rd_to_text()].
#' @return `text` with hard-wrapped single newlines joined into spaces and
#'   paragraph breaks normalized to a single blank line, trimmed.
#' @keywords internal
.normalize_block_whitespace <- function(text) {
  text <- gsub("\r\n", "\n", text)
  text <- gsub("\n[ \t]*\n([ \t]*\n)*", "\n\n", text)
  text <- gsub("(?<!\n)\n(?!\n)", " ", text, perl = TRUE)
  return(trimws(text))
}

#' Split the children of an `\\itemize{}`/`\\enumerate{}` node into items
#'
#' Unlike `\\arguments{}`'s `\\item{name}{description}` (a proper 2-child
#' container), `\\itemize{}`/`\\enumerate{}`'s `\\item` is a bare marker
#' with no children of its own — an item's actual content is its
#' *following sibling nodes*, up to the next `\\item` marker (or the end
#' of the list). Content before the first `\\item` (leading whitespace) is
#' discarded.
#'
#' @param children The children of an `\\itemize{}`/`\\enumerate{}` node.
#' @return A list of items, each itself a list of Rd fragments.
#' @keywords internal
.split_rd_items <- function(children) {
  items <- list()
  current <- list()
  seen_item <- FALSE

  for (child in children) {
    if (identical(attr(child, "Rd_tag"), "\\item")) {
      if (seen_item) {
        items[[length(items) + 1]] <- current
      }
      current <- list()
      seen_item <- TRUE
    } else if (seen_item) {
      current[[length(current) + 1]] <- child
    }
  }
  if (seen_item) {
    items[[length(items) + 1]] <- current
  }

  return(items)
}

#' Render an `\\itemize{}` node as a Markdown bullet list
#'
#' Each item is collapsed to a single line via [.collapse_whitespace()],
#' same as a table cell. Rd source hard-wraps item text across lines for
#' readability; left as raw newlines, a continuation line isn't reliably
#' recognized as part of the same list item across Markdown renderers (and
#' can be actively misread as a new block - a line that happens to start
#' with a digit and `. `, or contains something like `<table>`, is
#' ambiguous or gets parsed as literal HTML). GitHub/Gitea compatibility
#' requires each bullet to be self-contained on one line.
#'
#' @param x An `\\itemize{}` Rd node.
#' @return A Markdown string, one `- item` line per item.
#' @keywords internal
.render_rd_itemize <- function(x) {
  items <- .split_rd_items(x)
  lines <- purrr::map_chr(items, \(item) {
    return(paste0("- ", .collapse_whitespace(.rd_to_text(item))))
  })
  return(paste(lines, collapse = "\n"))
}

#' Render an `\\enumerate{}` node as a Markdown numbered list
#'
#' Each item is collapsed to a single line - see [.render_rd_itemize()]
#' for why.
#'
#' @param x An `\\enumerate{}` Rd node.
#' @return A Markdown string, one `N. item` line per item.
#' @keywords internal
.render_rd_enumerate <- function(x) {
  items <- .split_rd_items(x)
  lines <- purrr::imap_chr(items, \(item, i) {
    return(paste0(i, ". ", .collapse_whitespace(.rd_to_text(item))))
  })
  return(paste(lines, collapse = "\n"))
}

#' Render a `\\describe{}` node as a Markdown definition-style bullet list
#'
#' Unlike `\\itemize{}`/`\\enumerate{}`, whose `\\item` is a bare marker,
#' `\\describe{}`'s `\\item{term}{description}` is a proper 2-child
#' container - the same shape as `\\arguments{}`'s `\\item{name}{desc}`.
#' Markdown has no widely-supported definition-list syntax on GitHub/Gitea,
#' so each entry is rendered as `- **term**: description`.
#'
#' @param x A `\\describe{}` Rd node.
#' @return A Markdown string, one `- **term**: description` line per item.
#' @keywords internal
.render_rd_describe <- function(x) {
  items <- purrr::keep(x, \(child) identical(attr(child, "Rd_tag"), "\\item"))
  lines <- purrr::map_chr(items, \(item) {
    if (length(item) < 2) {
      return(paste0("- **", .collapse_whitespace(.rd_to_text(item)), "**"))
    }
    term <- .collapse_whitespace(.rd_to_text(item[[1]]))
    desc <- .collapse_whitespace(.rd_to_text(item[[2]]))
    return(paste0("- **", term, "**: ", desc))
  })
  return(paste(lines, collapse = "\n"))
}

#' Render one top-level `\\item{name}{desc}` node as a Markdown list item
#'
#' roxygen2 writes a named list in `\\value{}` as `\\item{name}{desc}`
#' nodes with no list container around them.
#'
#' @param x An `\\item{}{}` Rd node with 2 children.
#' @return One line, `` - **`name`**: desc ``.
#' @keywords internal
.render_rd_named_item <- function(x) {
  name <- .collapse_whitespace(.rd_to_text(x[[1]], in_code = TRUE))
  desc <- .collapse_whitespace(.rd_to_text(x[[2]]))
  return(paste0("- **", .inline_code_span(name), "**: ", desc))
}

#' Test whether an Rd node is text that holds only whitespace
#' @param x An Rd node.
#' @return `TRUE` or `FALSE`.
#' @keywords internal
.is_blank_rd_text <- function(x) {
  return(
    identical(attr(x, "Rd_tag"), "TEXT") &&
      !grepl("\\S", paste(as.character(x), collapse = ""))
  )
}

#' Render a `\\subsection{title}{body}` node as a Markdown heading + body
#'
#' The title is collapsed to a single line via [.collapse_whitespace()] -
#' an ATX heading (`### Title`) can't contain a literal newline either.
#'
#' @param x A `\\subsection{}{}` Rd node (2 children: title, body).
#' @param heading_level Heading depth for this subsection's own title.
#' @return A Markdown string: the heading, a blank line, then the
#'   recursively rendered body (nested subsections increase
#'   `heading_level` by 1).
#' @keywords internal
.render_rd_subsection <- function(x, heading_level) {
  title <- .collapse_whitespace(.rd_to_text(x[[1]]))
  heading <- paste0(strrep("#", heading_level), " ", title)
  body <- .rd_to_block_md(x[[2]], heading_level = heading_level + 1)
  return(paste(c(heading, body), collapse = "\n\n"))
}

#' Render a `\\preformatted{}` node as a fenced Markdown code block
#'
#' Uses [.rd_to_raw_text()] (Tier 1) rather than [.rd_to_text()], since
#' preformatted content's exact spacing/indentation must be preserved
#' verbatim. No language tag is added to the fence, since preformatted
#' content isn't necessarily R code.
#'
#' @param x A `\\preformatted{}` Rd node.
#' @return A fenced (` ``` `) Markdown code block.
#' @keywords internal
.render_rd_preformatted <- function(x) {
  code <- trimws(.rd_to_raw_text(x))
  fence <- .code_fence(code)
  return(paste0(fence, "\n", code, "\n", fence))
}

#' Render a block-level `\\if{html}{\\out{...}}` node, if `x` is one
#'
#' `\\if{html}{...}` and `\\ifelse{html}{...}{...}` are usually inline
#' conditionals, which [.rd_inline_piece()] handles. roxygen2 writes R6
#' method anchors and the "Inherited methods" block as an `\\if` node whose
#' `html` branch has an `\\out{}` node as a direct child.
#' [.render_rd_out_as_code()] renders that `\\out{}` node.
#'
#' @param x An Rd node (only `\\if`/`\\ifelse`-tagged nodes can match).
#' @return A Markdown string, or `NULL` when `x` is not this shape or when
#'   [.render_rd_out_as_code()] drops the HTML. The caller then treats `x`
#'   as inline content.
#' @keywords internal
.if_out_html_block <- function(x) {
  tag <- attr(x, "Rd_tag")

  html_branch <- NULL
  if (identical(tag, "\\if") && length(x) == 2) {
    if (identical(.collapse_whitespace(.rd_to_text(x[[1]])), "html")) {
      html_branch <- x[[2]]
    }
  } else if (identical(tag, "\\ifelse") && length(x) == 3) {
    if (identical(.collapse_whitespace(.rd_to_text(x[[1]])), "html")) {
      html_branch <- x[[2]]
    }
  }
  if (is.null(html_branch)) {
    return(NULL)
  }

  out_node <- Filter(\(ch) identical(attr(ch, "Rd_tag"), "\\out"), html_branch)
  if (length(out_node) == 0) {
    return(NULL)
  }

  return(.render_rd_out_as_code(out_node[[1]]))
}

#' Render the raw HTML of an `\\out{}` node as Markdown
#'
#' The function keeps two shapes of R6 class HTML and drops all other HTML.
#'
#' - An anchor `<a id="X"></a>` becomes `<a id="x"></a>` on its own line.
#'   The id is lowercase, because GitHub lowercases an `id` and does not
#'   change an `href`. [.rd_inline_link_piece()] lowercases the in-page
#'   `\\href{#X}` fragment to match.
#' - The "Inherited methods" block becomes a Markdown list of code spans,
#'   with no links. See [.render_inherited_methods()].
#'
#' roxygen2 writes a fenced code block as `\\preformatted{}` between two
#' `\\out{}` wrappers. [.render_rd_preformatted()] renders the code, so
#' the wrappers carry nothing to keep.
#'
#' @param out_node An `\\out{}` Rd node.
#' @return A Markdown string, or `NULL` when the function drops the HTML.
#' @keywords internal
.render_rd_out_as_code <- function(out_node) {
  raw_html <- .rd_to_raw_text(out_node)
  anchor <- regmatches(
    raw_html,
    regexec(
      "^\\s*<a\\s+id\\s*=\\s*[\"']([^\"']+)[\"']\\s*>\\s*</a>\\s*$",
      raw_html
    )
  )[[1]]
  if (length(anchor) == 2) {
    return(paste0("<a id=\"", tolower(anchor[2]), "\"></a>"))
  }
  return(.render_inherited_methods(raw_html))
}

#' Render the R6 "Inherited methods" HTML block as a Markdown list
#'
#' roxygen2 7 writes each method as a `<span>` with the attributes
#' `data-topic="C"` and `data-id="m"`. roxygen2 8 writes `<code>C$m()</code>`.
#' Each method becomes one list item `` `C$m()` ``. The list has no links,
#' because the HTML links point at the HTML help pages of other packages.
#'
#' @param html Raw HTML string of one `\\out{}` node.
#' @return A Markdown list, or `NULL` when `html` is not this block.
#' @keywords internal
.render_inherited_methods <- function(html) {
  if (!grepl("<summary>\\s*Inherited methods\\s*</summary>", html)) {
    return(NULL)
  }
  span <- regmatches(
    html,
    gregexpr("data-topic=\"([^\"]+)\"\\s+data-id=\"([^\"]+)\"", html)
  )[[1]]
  if (length(span) > 0) {
    topic <- sub("^data-topic=\"([^\"]+)\".*$", "\\1", span)
    id <- sub("^.*data-id=\"([^\"]+)\"$", "\\1", span)
    methods <- paste0(topic, "$", id, "()")
  } else {
    code <- regmatches(html, gregexpr("<code>[^<]*</code>", html))[[1]]
    methods <- .decode_html_entities(.strip_html_tags(code))
  }
  if (length(methods) == 0) {
    return(NULL)
  }
  items <- paste0("- ", vapply(methods, .inline_code_span, character(1)))
  return(paste(c("Inherited methods:", "", items), collapse = "\n"))
}

#' Detect a `class="sourceCode <lang>"` marker in raw HTML, if present
#' @param html Raw HTML string.
#' @return The language string (e.g. `"r"`), or `NULL` if not found.
#' @keywords internal
.detect_source_code_lang <- function(html) {
  match <- regmatches(
    html,
    regexec('class="sourceCode\\s+([a-zA-Z0-9_+-]+)"', html, perl = TRUE)
  )[[1]]
  if (length(match) < 2) {
    return(NULL)
  }
  return(match[2])
}

#' Strip HTML tags from a string
#' @param html Raw HTML string.
#' @return `html` with every `<...>` tag removed.
#' @keywords internal
.strip_html_tags <- function(html) {
  return(gsub("<[^>]*>", "", html))
}

#' Decode the handful of HTML entities that show up in Rd `\\out{}` blocks
#'
#' Not a general HTML-entity decoder - just the small set that appears in
#' practice (roxygen2/pandoc-generated `#&gt;` output markers and escaped
#' quotes/ampersands). `&amp;` is decoded last so a literal `&amp;lt;` in
#' the source doesn't get double-decoded into `<`.
#'
#' @param text A string.
#' @return `text` with entities decoded.
#' @keywords internal
.decode_html_entities <- function(text) {
  text <- gsub("&lt;", "<", text, fixed = TRUE)
  text <- gsub("&gt;", ">", text, fixed = TRUE)
  text <- gsub("&quot;", "\"", text, fixed = TRUE)
  text <- gsub("&#39;", "'", text, fixed = TRUE)
  text <- gsub("&apos;", "'", text, fixed = TRUE)
  text <- gsub("&amp;", "&", text, fixed = TRUE)
  return(text)
}

#' Split the children of a `\\tabular{}{}` node's body into rows
#'
#' Like [.split_rd_items()] for `\\itemize{}`, `\\cr` is a bare row-separator
#' marker (0 children of its own) rather than a container. Unlike
#' `\\item`, content *before* the first `\\cr` is significant (it's the
#' first row's content, not discardable leading whitespace) - `\\tabular{}`
#' has no separate per-row start marker the way `\\itemize{}`'s `\\item`
#' doubles as both.
#'
#' @param children The children of a `\\tabular{}{}` node's body (its
#'   second argument).
#' @return A list of rows, each itself a list of Rd fragments (to be
#'   further split into cells by [.split_rd_table_cells()]).
#' @keywords internal
.split_rd_table_rows <- function(children) {
  rows <- list()
  current <- list()
  for (child in children) {
    if (identical(attr(child, "Rd_tag"), "\\cr")) {
      rows[[length(rows) + 1]] <- current
      current <- list()
    } else {
      current[[length(current) + 1]] <- child
    }
  }
  rows[[length(rows) + 1]] <- current
  return(rows)
}

#' Split one table row's children into cells
#' @param row_children One row from [.split_rd_table_rows()].
#' @return A list of cells, each itself a list of Rd fragments.
#' @keywords internal
.split_rd_table_cells <- function(row_children) {
  cells <- list()
  current <- list()
  for (child in row_children) {
    if (identical(attr(child, "Rd_tag"), "\\tab")) {
      cells[[length(cells) + 1]] <- current
      current <- list()
    } else {
      current[[length(current) + 1]] <- child
    }
  }
  cells[[length(cells) + 1]] <- current
  return(cells)
}

#' Render a `\\tabular{spec}{body}` node as a Markdown table
#'
#' `spec` is a column-alignment string like `"ll"` (2 left-aligned
#' columns) or `"lcr"` (left, center, right) - `l`/`c`/`r` map to the
#' corresponding Markdown table alignment marker; anything else defaults
#' to left. `spec` is filtered down to `[lcr]` characters before use, since
#' the raw Rd source can carry stray whitespace/newlines around the spec
#' that would otherwise shift the character-to-column mapping. Cell text
#' is also pipe-escaped (see [.escape_table_pipe()]) - a literal `|` in
#' cell content would otherwise break the row. Rows that are entirely
#' blank once collapsed (e.g. a spacer
#' `\\cr` with nothing between it and the next, or trailing whitespace
#' after the last real row) are dropped. The first surviving row becomes
#' the Markdown table's header, since GFM tables require one and Rd's
#' `\\tabular{}` doesn't distinguish a header row - this matches how such
#' tables are typically authored in practice (a label row followed by
#' data rows).
#'
#' @param x A `\\tabular{}{}` Rd node (2 children: alignment spec, body).
#' @return A Markdown table string, or `""` if the table has no non-blank
#'   rows.
#' @keywords internal
.render_rd_tabular <- function(x) {
  align_spec <- .leaf_or_list_raw_text(x[[1]])
  align_chars <- Filter(
    \(ch) ch %in% c("l", "c", "r"),
    strsplit(align_spec, "")[[1]]
  )

  rows <- .split_rd_table_rows(x[[2]])
  row_texts <- purrr::map(rows, \(row) {
    return(purrr::map_chr(
      .split_rd_table_cells(row),
      \(cell) .escape_table_pipe(.collapse_whitespace(.rd_to_text(cell)))
    ))
  })
  row_texts <- purrr::keep(row_texts, \(texts) any(nzchar(texts)))
  if (length(row_texts) == 0) {
    return("")
  }

  n_cols <- max(purrr::map_int(row_texts, length))
  pad_row <- \(texts) {
    if (length(texts) < n_cols) {
      return(c(texts, rep("", n_cols - length(texts))))
    } else {
      return(texts)
    }
  }
  render_row <- \(texts) {
    return(paste0("| ", paste(pad_row(texts), collapse = " | "), " |"))
  }

  align_marker <- \(ch) switch(ch, c = ":---:", r = "---:", "---")
  separator_cells <- purrr::map_chr(seq_len(n_cols), \(i) {
    return(align_marker(if (i <= length(align_chars)) align_chars[i] else "l"))
  })
  separator <- paste0("| ", paste(separator_cells, collapse = " | "), " |")

  body_rows <- if (length(row_texts) > 1) {
    purrr::map_chr(row_texts[-1], render_row)
  } else {
    character(0)
  }

  return(paste(
    c(render_row(row_texts[[1]]), separator, body_rows),
    collapse = "\n"
  ))
}
