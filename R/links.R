#' State of the active link map
#'
#' `map` holds the link map that [.with_link_map()] sets, or `NULL`. With
#' `NULL`, every `\\link` renders as a code span.
#'
#' @keywords internal
.link_state <- new.env(parent = emptyenv())

#' Evaluate code with a link map active
#'
#' Inline Rd rendering reads the map through [.rd_link_href()]. The map is
#' a dynamic setting, so the block renderer and the inline renderer need no
#' extra argument. The previous map comes back when `code` returns or fails.
#'
#' @param map A named character vector from [.alias_link_map()], or `NULL`.
#' @param code The code to evaluate.
#' @return The value of `code`.
#' @keywords internal
.with_link_map <- function(map, code) {
  old <- .link_state$map
  .link_state$map <- map
  on.exit(.link_state$map <- old)
  return(force(code))
}

#' Map every alias of a set of topics to the file of its topic
#'
#' The file name is the one that [build_reference()] writes for the topic:
#' [.safe_filename()] of the topic name, plus `.md`. When two topics share
#' an alias, the first topic in `topics` owns it.
#'
#' @param topics List of parsed topic lists.
#' @return A character vector of file names, named by alias.
#' @keywords internal
.alias_link_map <- function(topics) {
  files <- paste0(
    vapply(topics, \(topic) .safe_filename(topic$name), character(1)),
    ".md"
  )
  aliases <- lapply(topics, \(topic) unique(c(topic$aliases, topic$name)))
  map <- rep(files, lengths(aliases))
  names(map) <- as.character(unlist(aliases))
  return(map[!duplicated(names(map))])
}

#' Find the alias that a `\\link` or `\\linkS4class` node points to
#'
#' `\\link{x}` points to `x`, `\\link[=x]{text}` to `x`, and
#' `\\linkS4class{x}` to `x-class`. A link with a package option, such as
#' `\\link[pkg]{x}` or `\\link[pkg:x]{text}`, points to another package.
#'
#' @param x A `\\link` or `\\linkS4class` Rd node.
#' @return The alias, or `NA` for a link to another package.
#' @keywords internal
.rd_link_target <- function(x) {
  label <- .rd_to_text(x, in_code = TRUE)
  if (identical(attr(x, "Rd_tag"), "\\linkS4class")) {
    return(paste0(label, "-class"))
  }
  option <- attr(x, "Rd_option")
  if (is.null(option)) {
    return(label)
  }
  option <- .leaf_or_list_text(option)
  if (startsWith(option, "=")) {
    return(substring(option, 2))
  }
  return(NA_character_)
}

#' Find the file that a `\\link` node points to under the active link map
#'
#' @param x A `\\link` or `\\linkS4class` Rd node.
#' @return The relative file name, or `NULL` when no link map is active, when
#'   the link points to another package, or when the map lacks the alias.
#' @keywords internal
.rd_link_href <- function(x) {
  map <- .link_state$map
  if (is.null(map)) {
    return(NULL)
  }
  target <- .rd_link_target(x)
  if (is.na(target) || !target %in% names(map)) {
    return(NULL)
  }
  return(unname(map[[target]]))
}

#' Find the file that a `\\code` node links to
#'
#' Roxygen writes a link to a function as `\\code{\\link[=x]{x()}}`. The
#' code span then links as a whole. A `\\code` node with no `\\link` child,
#' or with more than one, links to nothing.
#'
#' @param x A `\\code` or `\\command` Rd node.
#' @return The relative file name, or `NULL`.
#' @keywords internal
.rd_code_link_href <- function(x) {
  tags <- vapply(x, \(child) attr(child, "Rd_tag") %||% "", character(1))
  links <- x[tags %in% c("\\link", "\\linkS4class")]
  if (length(links) != 1) {
    return(NULL)
  }
  return(.rd_link_href(links[[1]]))
}

#' Wrap Markdown text in a link, when there is a target
#'
#' @param text Markdown link text.
#' @param href The link target, or `NULL`.
#' @return `[text](href)`, or `text` when `href` is `NULL`.
#' @keywords internal
.wrap_link <- function(text, href) {
  if (is.null(href)) {
    return(text)
  }
  return(paste0("[", text, "](", href, ")"))
}

#' Find the dead relative links in a folder of Markdown files
#'
#' Reads every `.md` file under `dir` and checks every relative Markdown
#' link. A link is dead when its file does not exist, or when its
#' `#fragment` is not a target in the file it points to. A fragment on a
#' file that is not Markdown is always dead. A link of the form
#' `#x` points to the same file. The checker ignores links with a URL
#' scheme, such as `https:` or `mailto:`. It also ignores links and targets
#' inside fenced code blocks and inline code spans.
#'
#' The targets follow GitHub: see [.md_fragment_targets()]. The checker
#' compares a fragment with the targets exactly, because GitHub does too.
#'
#' @param dir Path to a folder.
#' @return A data.frame with the columns `file` (relative to `dir`), `link`
#'   and `kind`, which is `"file"` or `"fragment"`. It has one row per dead
#'   link.
#' @keywords internal
.find_dead_links <- function(dir) {
  links <- .md_relative_links(dir)
  if (nrow(links) == 0) {
    return(.dead_link_frame(character(), character(), character()))
  }
  target_cache <- new.env(parent = emptyenv())
  kind <- vapply(
    seq_len(nrow(links)),
    \(i) .dead_link_kind(dir, links$file[i], links$link[i], target_cache),
    character(1)
  )
  dead <- !is.na(kind)
  return(.dead_link_frame(links$file[dead], links$link[dead], kind[dead]))
}

#' Build a data.frame of dead links
#' @param file,link,kind Character vectors of equal length.
#' @return A data.frame with the columns `file`, `link` and `kind`.
#' @keywords internal
.dead_link_frame <- function(file, link, kind) {
  return(data.frame(
    file = file,
    link = link,
    kind = kind,
    stringsAsFactors = FALSE
  ))
}

#' List every relative Markdown link in a folder of Markdown files
#'
#' @param dir Path to a folder.
#' @return A data.frame with the columns `file` (relative to `dir`) and
#'   `link`, one row per link.
#' @keywords internal
.md_relative_links <- function(dir) {
  files <- sort(list.files(dir, pattern = "\\.md$", recursive = TRUE))
  rows <- lapply(files, \(file) {
    text <- .md_strip_code(.read_md_lines(file.path(dir, file)))
    link <- unlist(lapply(text, .md_link_destinations))
    link <- link[nzchar(link) & !grepl("^([A-Za-z][A-Za-z0-9+.-]*:|//)", link)]
    return(data.frame(
      file = rep(file, length(link)),
      link = link,
      stringsAsFactors = FALSE
    ))
  })
  if (length(rows) == 0) {
    return(data.frame(file = character(), link = character()))
  }
  return(do.call(rbind, rows))
}

#' Extract the destinations of the inline Markdown links in one line
#'
#' A destination follows CommonMark in one of two forms:
#'
#' - `<...>`, which MAY hold spaces and MUST NOT hold `<` or `>`.
#' - A run without spaces, which MAY hold balanced parentheses, for
#'   example `a(b).md`.
#'
#' An optional title in quotes or parentheses MAY follow the destination.
#' The function removes the backslash from each backslash escape.
#'
#' @param line One line of Markdown, with code already removed.
#' @return A character vector of destinations, possibly empty.
#' @keywords internal
.md_link_destinations <- function(line) {
  pattern <- paste0(
    "\\]\\(\\s*",
    "(?:<((?:[^<>\\n\\\\]|\\\\.)*)>",
    "|((?:[^\\s()\\\\]|\\\\.|\\((?2)\\))*))",
    "(?:\\s+(?:\"[^\"]*\"|'[^']*'|\\([^)]*\\)))?\\s*\\)"
  )
  match <- gregexpr(pattern, line, perl = TRUE)[[1]]
  if (match[1] == -1) {
    return(character())
  }
  start <- attr(match, "capture.start")
  len <- attr(match, "capture.length")
  angle <- start[, 1] > 0
  dest <- ifelse(
    angle,
    substring(line, start[, 1], start[, 1] + len[, 1] - 1),
    substring(line, start[, 2], start[, 2] + len[, 2] - 1)
  )
  return(gsub("\\\\([[:punct:]])", "\\1", dest))
}

#' Decide whether one relative link is dead, and why
#'
#' @param dir Path to the folder that [.find_dead_links()] checks.
#' @param file The file that holds the link, relative to `dir`.
#' @param link The link target.
#' @param target_cache An environment that caches the targets per file.
#' @return `"file"`, `"fragment"`, or `NA` when the link is alive.
#' @keywords internal
.dead_link_kind <- function(dir, file, link, target_cache) {
  hash <- regexpr("#", link, fixed = TRUE)
  path <- if (hash > 0) substring(link, 1, hash - 1) else link
  fragment <- if (hash > 0) substring(link, hash + 1) else ""
  path <- sub("\\?.*$", "", path)

  target <- if (nzchar(path)) {
    file.path(dirname(file), utils::URLdecode(path))
  } else {
    file
  }
  full <- file.path(dir, target)
  if (!file.exists(full)) {
    return("file")
  }
  if (!nzchar(fragment)) {
    return(NA_character_)
  }
  # A fragment on a file that is not Markdown has no target to find.
  if (!grepl("\\.md$", target) || dir.exists(full)) {
    return("fragment")
  }
  key <- normalizePath(full, winslash = "/")
  if (is.null(target_cache[[key]])) {
    target_cache[[key]] <- .md_fragment_targets(.read_md_lines(full))
  }
  if (utils::URLdecode(fragment) %in% target_cache[[key]]) {
    return(NA_character_)
  }
  return("fragment")
}

#' List the fragment targets of a Markdown file, as GitHub renders them
#'
#' GitHub lowercases every `id` and `name` attribute. It derives a heading
#' slug as follows:
#'
#' 1. It lowercases the heading text.
#' 2. It drops every character that is not a letter, a digit, a space, `-`
#'    or `_`.
#' 3. It changes every space to `-`.
#' 4. It adds `-1`, `-2` and so on to a repeated slug.
#'
#' @param lines The lines of the Markdown file.
#' @return A character vector of targets.
#' @keywords internal
.md_fragment_targets <- function(lines) {
  no_fences <- .md_strip_fences(lines)
  no_code <- .md_strip_code(lines)
  attrs <- regmatches(
    no_code,
    gregexpr("\\b(id|name)\\s*=\\s*(\"[^\"]*\"|'[^']*')", no_code, perl = TRUE)
  )
  ids <- sub("^[^=]*=\\s*[\"']", "", unlist(attrs), perl = TRUE)
  ids <- tolower(sub("[\"']$", "", ids))

  headings <- no_fences[grepl("^ {0,3}#{1,6}(\\s|$)", no_fences)]
  text <- sub("^ {0,3}#{1,6}\\s*", "", headings)
  text <- sub("\\s+#+\\s*$", "", text)
  text <- gsub("\\]\\([^)]*\\)", "]", text)
  slugs <- tolower(text)
  slugs <- gsub("[^\\p{L}\\p{N} _-]", "", slugs, perl = TRUE)
  slugs <- gsub(" ", "-", slugs, fixed = TRUE)
  repeat_n <- vapply(
    seq_along(slugs),
    \(i) sum(slugs[seq_len(i - 1)] == slugs[i]),
    integer(1)
  )
  slugs[repeat_n > 0] <- paste0(
    slugs[repeat_n > 0],
    "-",
    repeat_n[repeat_n > 0]
  )

  return(unique(c(ids, slugs)))
}

#' Read a Markdown file as UTF-8 lines
#' @param path Path to the file.
#' @return A character vector of lines.
#' @keywords internal
.read_md_lines <- function(path) {
  return(readLines(path, warn = FALSE, encoding = "UTF-8"))
}

#' Remove the fenced code blocks from Markdown lines
#'
#' A fence opens with three or more backticks or tildes, and closes with a
#' fence of the same character that is at least as long.
#'
#' @param lines The lines of a Markdown file.
#' @return `lines`, with every line inside a fenced code block, and every
#'   fence line, changed to `""`.
#' @keywords internal
.md_strip_fences <- function(lines) {
  open <- ""
  for (i in seq_along(lines)) {
    fence <- regmatches(lines[i], regexpr("^ {0,3}(`{3,}|~{3,})", lines[i]))
    fence <- trimws(fence)
    if (nzchar(open)) {
      if (
        length(fence) == 1 &&
          substr(fence, 1, 1) == substr(open, 1, 1) &&
          nchar(fence) >= nchar(open)
      ) {
        open <- ""
      }
      lines[i] <- ""
    } else if (length(fence) == 1) {
      open <- fence
      lines[i] <- ""
    }
  }
  return(lines)
}

#' Remove fenced code blocks and inline code spans from Markdown lines
#'
#' @param lines The lines of a Markdown file.
#' @return `lines`, with code removed.
#' @keywords internal
.md_strip_code <- function(lines) {
  lines <- .md_strip_fences(lines)
  return(gsub("(?<!`)(`+)(?!`).*?(?<!`)\\1(?!`)", "", lines, perl = TRUE))
}
