#' Read the Rd documentation of a package, installed or in development
#'
#' Dispatches based on [.is_source_path()]: an installed package name goes
#' through [.read_rd_db_installed()], while a path to a local package
#' source directory goes through [.read_rd_db_source()].
#'
#' @param package Name of an installed package, or a path to a local
#'   package source directory (detected via a `DESCRIPTION` file at that
#'   path).
#' @return A named list of `Rd` objects (one entry per documented topic).
#' @keywords internal
.read_rd_db <- function(package) {
  if (.is_source_path(package)) {
    return(.read_rd_db_source(package))
  } else {
    return(.read_rd_db_installed(package))
  }
}

#' Read the Rd database of an installed package
#'
#' Thin wrapper around [tools::Rd_db()] that checks the package is actually
#' installed first and raises a helpful error otherwise.
#'
#' @param package Name of an installed package, e.g. `"dplyr"`.
#' @return A named list of `Rd` objects, as returned by [tools::Rd_db()].
#' @keywords internal
.read_rd_db_installed <- function(package) {
  if (length(find.package(package, quiet = TRUE)) == 0) {
    cli::cli_abort(c(
      "Package {.pkg {package}} is not installed.",
      "i" = "Install it first with {.code install.packages(\"{package}\")}."
    ))
  }

  db <- tools::Rd_db(package)

  if (length(db) == 0) {
    cli::cli_warn("Package {.pkg {package}} has no Rd documentation.")
  }

  return(db)
}

#' Read the Rd documentation of a package straight from its source tree
#'
#' Used for development packages that have not been installed. Reads every
#' `man/*.Rd` file in `path` via [tools::parse_Rd()]. If `man/` is missing
#' or empty, falls back to a live, in-memory parse via
#' `roxygen2::parse_package(path)` — only attempted if the `roxygen2`
#' namespace is available; otherwise raises an error pointing the user at
#' `devtools::document()`.
#'
#' @param path Path to a local package source directory (contains a
#'   `DESCRIPTION` file).
#' @return A named list of `Rd` objects, in the same shape as
#'   [tools::Rd_db()] would return for an installed package.
#' @keywords internal
.read_rd_db_source <- function(path) {
  man_dir <- fs::path(path, "man")
  rd_files <- if (fs::dir_exists(man_dir)) {
    fs::dir_ls(man_dir, glob = "*.Rd")
  } else {
    character(0)
  }

  if (length(rd_files) > 0) {
    db <- purrr::map(rd_files, tools::parse_Rd)
    names(db) <- fs::path_file(rd_files)
    return(db)
  }

  if (!requireNamespace("roxygen2", quietly = TRUE)) {
    cli::cli_abort(c(
      "No {.path man/*.Rd} files found in {.path {path}}, and {.pkg roxygen2} is not installed.",
      "i" = "Run {.code devtools::document()} first, or install {.pkg roxygen2} to parse roxygen comments directly."
    ))
  }

  topics <- suppressMessages({
    env <- roxygen2::env_package(path)
    blocks <- roxygen2::parse_package(path, env = env)
    roxygen2::roclet_process(
      roxygen2::rd_roclet(),
      blocks,
      env = env,
      base_path = path
    )
  })

  db <- purrr::map(topics, .parse_rd_from_roxygen_topic)
  if (is.null(names(db))) {
    names(db) <- paste0(seq_along(db), ".Rd")
  }
  return(db)
}

#' Determine a package's exported names, for flagging private topics
#'
#' Dispatches based on [.is_source_path()], mirroring [.read_rd_db()].
#'
#' @param package Name of an installed package, or a path to a local
#'   package source directory.
#' @return Character vector of exported names, or `NULL` if export status
#'   couldn't be determined (see the installed/source variants for when
#'   that happens) - callers should treat `NULL` as "unknown", not as "no
#'   exports".
#' @keywords internal
.read_exported_names <- function(package) {
  if (.is_source_path(package)) {
    return(.read_exported_names_source(package))
  } else {
    return(.read_exported_names_installed(package))
  }
}

#' Determine an installed package's exported names via its namespace
#'
#' `getNamespaceExports()` is the only fully correct way to get this list -
#' it's what R itself resolves `export()`/`exportPattern()`/etc. down to,
#' so hand-parsing the `NAMESPACE` file here would mean reimplementing
#' that resolution (including regex `exportPattern()` matching against the
#' namespace's actual contents). The cost is that it loads the package's
#' namespace if not already loaded - unlike [.read_rd_db_installed()]'s
#' existence check, this is unavoidable here since the actual export list
#' can only come from the loaded namespace itself. Wrapped in `tryCatch()`
#' so a package that fails to load degrades to "unknown" (`NULL`) rather
#' than aborting the whole reference build - `include_private` simply has
#' nothing to filter on in that case, same as before this feature existed.
#'
#' @param package Name of an installed package.
#' @return Character vector of exported names, or `NULL` if the namespace
#'   couldn't be loaded.
#' @keywords internal
.read_exported_names_installed <- function(package) {
  return(tryCatch(getNamespaceExports(package), error = function(e) NULL))
}

#' Determine a source package's exported names from its `NAMESPACE` file
#'
#' Parses explicit `export(name)` directives (line-per-symbol, the
#' convention `roxygen2::document()` writes) rather than loading the
#' package - a dev package is often not in a loadable state. Doesn't
#' resolve `exportPattern()` regexes (rare in roxygen2-generated
#' `NAMESPACE` files; common only in hand-written classic ones) - a topic
#' exported only via such a pattern would be misflagged as private, a
#' known, minor limitation.
#'
#' @param path Path to a local package source directory.
#' @return Character vector of exported names, or `NULL` if no
#'   `NAMESPACE` file exists yet (e.g. a dev package that has never run
#'   `devtools::document()`) - export status is simply unknown then, not
#'   "nothing is exported".
#' @keywords internal
.read_exported_names_source <- function(path) {
  ns_file <- fs::path(path, "NAMESPACE")
  if (!fs::file_exists(ns_file)) {
    return(NULL)
  }
  return(.parse_namespace_exports(ns_file))
}

#' Parse `export(...)` directives out of a `NAMESPACE` file
#'
#' @param ns_file Path to a `NAMESPACE` file.
#' @return Character vector of exported names (possibly empty), with
#'   surrounding quotes/backticks stripped (`export("[<-.foo")`,
#'   `` export(`%>%`) ``).
#' @keywords internal
.parse_namespace_exports <- function(ns_file) {
  lines <- readLines(ns_file, warn = FALSE)
  export_lines <- lines[grepl("^export\\(", lines)]
  inner <- sub("^export\\((.*)\\)\\s*$", "\\1", export_lines)
  names <- trimws(unlist(strsplit(inner, ",")))
  names <- gsub("^[`\"']+|[`\"']+$", "", names)
  return(names[nzchar(names)])
}

#' Decide whether a topic counts as "private" (not part of the public API)
#'
#' A topic is private when it has at least one callable name (see
#' [.callable_candidates()] - this excludes datasets/concept pages, which
#' aren't in `NAMESPACE`'s `export()` list either but aren't private
#' helpers) and *none* of its callable names are in `exported_names`. When
#' `exported_names` is `NULL` (export status couldn't be determined - see
#' [.read_exported_names()]), every topic is treated as public, matching
#' behavior from before this feature existed.
#'
#' @param name Topic name.
#' @param aliases Character vector of the topic's aliases.
#' @param usage The topic's `\\usage{}` text.
#' @param exported_names Character vector of the package's exported
#'   names, or `NULL` if unknown.
#' @return `TRUE`/`FALSE`.
#' @keywords internal
.compute_is_private <- function(name, aliases, usage, exported_names) {
  if (is.null(exported_names)) {
    return(FALSE)
  }
  callable <- .callable_candidates(name, aliases, usage)
  if (length(callable) == 0) {
    return(FALSE)
  }
  return(!any(callable %in% exported_names))
}

#' Parse one in-memory roxygen2 `RdFile` topic into an `Rd` object
#'
#' `format(topic)` renders the `RdFile` back to `.Rd` source text, which
#' [tools::parse_Rd()] only accepts from a connection, not a plain string -
#' hence the `textConnection()` round-trip. The connection is explicitly
#' closed afterwards; left open, each call leaks one and eventually
#' surfaces as an R "closing unused connection" warning once the
#' finalizer runs.
#'
#' @param topic A single roxygen2 `RdFile` object.
#' @return An `Rd` object, as [tools::parse_Rd()] would return for a file
#'   on disk.
#' @keywords internal
.parse_rd_from_roxygen_topic <- function(topic) {
  con <- textConnection(format(topic))
  on.exit(close(con))
  return(tools::parse_Rd(con))
}

#' Parse a single Rd object into an internal list
#'
#' Converts an `Rd` object (from either [tools::Rd_db()] or
#' [tools::parse_Rd()]) into a flat list consumable by `render_md.R`.
#' `title`/`arguments[].name`/`arguments[].description`/`value`/`seealso`
#' are single-line-safe text via [.rd_to_text()] (Tier 2 - table cells and
#' the page title can't contain a literal newline). `description`/
#' `details`/`format`/`note`/`source`/`references`/`author`/each section's
#' body are full multi-paragraph Markdown via [.rd_to_block_md()] (Tier 3),
#' since they commonly contain `\\itemize{}`, `\\describe{}`,
#' `\\subsection{}{}`, etc. that Tier 2 would flatten into unreadable prose.
#'
#' @param rd A single `Rd` object.
#' @param rd_name Name of the Rd entry (list name from the Rd database,
#'   typically `"function_name.Rd"`).
#' @param package Name of the package this topic belongs to.
#' @param exported_names Character vector of the package's exported
#'   names (see [.read_exported_names()]), or `NULL` if unknown. Drives
#'   `is_private` (see [.compute_is_private()]); has no other effect.
#' @return A list with fields `name`, `package`, `aliases`, `is_private`,
#'   `title`, `description`, `usage`, `arguments`, `details`, `sections`,
#'   `format`, `value`, `examples`, `seealso`, `note`, `source`,
#'   `references`, `author`.
#' @keywords internal
.parse_rd_topic <- function(rd, rd_name, package, exported_names = NULL) {
  name <- .parse_rd_name(rd, rd_name)
  aliases <- .parse_rd_aliases(rd)
  usage <- .parse_rd_usage(rd)

  return(list(
    name = name,
    package = package,
    aliases = aliases,
    is_private = .compute_is_private(name, aliases, usage, exported_names),
    title = .collapse_whitespace(.rd_to_text(.get_rd_tag(rd, "\\title"))),
    description = .rd_to_block_md(.first_rd_tag_children(rd, "\\description")),
    usage = usage,
    arguments = .parse_rd_arguments(rd),
    details = .rd_to_block_md(.first_rd_tag_children(rd, "\\details")),
    sections = .parse_rd_sections(rd),
    format = .rd_to_block_md(.first_rd_tag_children(rd, "\\format")),
    value = .collapse_whitespace(.rd_to_text(.get_rd_tag(rd, "\\value"))),
    examples = .parse_rd_examples(rd),
    seealso = .collapse_whitespace(.rd_to_text(.get_rd_tag(rd, "\\seealso"))),
    note = .rd_to_block_md(.first_rd_tag_children(rd, "\\note")),
    source = .rd_to_block_md(.first_rd_tag_children(rd, "\\source")),
    references = .rd_to_block_md(.first_rd_tag_children(rd, "\\references")),
    author = .rd_to_block_md(.first_rd_tag_children(rd, "\\author"))
  ))
}

#' Resolve a topic's name, preferring its `\\name{}` tag
#'
#' The Rd database's list name (`rd_name`, typically `"function_name.Rd"`)
#' is usually identical to the topic's own `\\name{}` tag, but not always -
#' e.g. dplyr's `group_by_prepare.Rd` declares `\\name{distinct_prepare}`.
#' The `\\name{}` tag is what `?topic` and cross-references actually
#' resolve against, so it takes priority; the filename-derived name is only
#' a fallback for the (invalid, but not worth hard-failing on) case where
#' `\\name{}` is missing.
#'
#' @param rd An `Rd` object.
#' @param rd_name Name of the Rd entry (list name from the Rd database).
#' @return A single string.
#' @keywords internal
.parse_rd_name <- function(rd, rd_name) {
  name <- .collapse_whitespace(.rd_to_text(.get_rd_tag(rd, "\\name")))
  if (nzchar(name)) {
    return(name)
  }
  return(sub("\\.Rd$", "", rd_name))
}

#' Extract all `\\section{title}{body}` blocks of an Rd object
#'
#' Unlike the other top-level tags (`\\details{}`, `\\value{}`, ...),
#' `\\section{}` can appear multiple times per topic, each with its own
#' title - e.g. dplyr's `mutate.Rd` has separate "Useful mutate functions",
#' "Grouped tibbles", and "Methods" sections.
#'
#' @param rd An `Rd` object.
#' @return A list of `list(title, body)` pairs, `body` rendered as Tier 3
#'   Markdown via [.rd_to_block_md()].
#' @keywords internal
.parse_rd_sections <- function(rd) {
  sections <- .get_rd_tag(rd, "\\section")
  return(purrr::map(sections, \(section) {
    return(list(
      title = .collapse_whitespace(.rd_to_text(section[[1]])),
      body = .rd_to_block_md(section[[2]])
    ))
  }))
}

#' Extract all `\\alias{}` entries of an Rd object
#'
#' @param rd An `Rd` object.
#' @return Character vector of aliases.
#' @keywords internal
.parse_rd_aliases <- function(rd) {
  aliases <- .get_rd_tag(rd, "\\alias")
  return(purrr::map_chr(aliases, .rd_to_text))
}

#' Extract the `\\usage{}` block as preformatted code
#'
#' Uses [.rd_to_raw_text()] (Tier 1), not [.rd_to_text()] - usage is R
#' code, so exact spacing/indentation (e.g. across multi-line signatures)
#' must be preserved verbatim rather than collapsed.
#'
#' @param rd An `Rd` object.
#' @return String with the usage code (no backtick fence).
#' @keywords internal
.parse_rd_usage <- function(rd) {
  usage <- .get_rd_tag(rd, "\\usage")
  if (length(usage) == 0) {
    return("")
  }
  return(trimws(.rd_to_raw_text(usage)))
}

#' Extract `\\arguments{}` as a list of name/description pairs
#'
#' Each `\\item{name}{description}` inside `\\arguments{}` becomes one row
#' in the rendered arguments table. A well-formed `\\item` always has 2
#' children (name, description); one with fewer is malformed Rd, but
#' skipped rather than erroring out the whole topic - a rendering gap for
#' one argument shouldn't take down documentation for everything else.
#'
#' @param rd An `Rd` object.
#' @return List of lists with fields `name`, `description`.
#' @keywords internal
.parse_rd_arguments <- function(rd) {
  arg_blocks <- .get_rd_tag(rd, "\\arguments")
  if (length(arg_blocks) == 0) {
    return(list())
  }

  items <- purrr::flatten(purrr::map(arg_blocks, .get_rd_tag, tag = "\\item"))
  items <- purrr::keep(items, \(item) length(item) >= 2)

  return(purrr::map(items, \(item) {
    return(list(
      name = .collapse_whitespace(.rd_to_text(item[[1]])),
      description = .collapse_whitespace(.rd_to_text(item[[2]]))
    ))
  }))
}

#' Extract the `\\examples{}` block as a code string
#'
#' Uses [.rd_to_raw_text()] (Tier 1), not [.rd_to_text()] - examples are R
#' code, so exact spacing/indentation must be preserved verbatim rather
#' than collapsed.
#'
#' @param rd An `Rd` object.
#' @return String with the example code (no backtick fence), empty if no
#'   examples are present.
#' @keywords internal
.parse_rd_examples <- function(rd) {
  examples <- .get_rd_tag(rd, "\\examples")
  if (length(examples) == 0) {
    return("")
  }
  return(trimws(.rd_to_raw_text(examples)))
}
