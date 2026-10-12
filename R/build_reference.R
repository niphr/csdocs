#' Generate Markdown reference documentation for a package
#'
#' Reads the Rd documentation of a package - either installed, or a local
#' development package that has not been installed - renders it as
#' Markdown, and writes one `.md` file per function into `output_dir`.
#' Also produces a `README.md` (index table of all functions) and a
#' `_full_reference.md` (every function in one file, meant to be injected
#' as LLM context, e.g. via `@docs/reference/_full_reference.md` in Claude
#' Code).
#'
#' `package` accepts two kinds of input:
#' \itemize{
#'   \item the name of an installed package, e.g. `"dplyr"` - Rd data is
#'     read via [tools::Rd_db()];
#'   \item a path to a local package source directory, e.g. `"."` or
#'     `"../myotherpkg"` (detected by the presence of a `DESCRIPTION` file
#'     at that path) - Rd data is read directly from `man/*.Rd`, falling
#'     back to a live `roxygen2::parse_package()` parse if `man/` is
#'     missing or empty. This mode does **not** require the package to be
#'     installed.
#' }
#'
#' @param package Name of an installed package, or a path to a local
#'   package source directory. Defaults to `"."` - the common case of
#'   running `build_reference()` from within the package you're
#'   documenting.
#' @param output_dir Target directory for the generated `.md` files.
#'   Created if it does not exist. Defaults to `"md-docs"`, but only when
#'   `package` resolves to a local source directory - for an installed
#'   package (e.g. `"dplyr"`) there's no similarly obvious default
#'   location, so `output_dir` must be given explicitly.
#' @param overwrite If `TRUE` (the default), any `.md` files already in
#'   `output_dir` are removed before writing the new set - this also
#'   clears stale files left behind by topics that were since renamed or
#'   removed from the package. If `FALSE`, aborts instead when
#'   `output_dir` already contains `.md` files, without touching them.
#' @param include_private If `TRUE` (the default), documented topics that
#'   aren't part of the package's public API (i.e. not in its `NAMESPACE`
#'   exports - typically internal helpers documented with
#'   `@keywords internal` rather than `@export`) are included and marked
#'   `_(private)_` next to their heading, in both the topic file and the
#'   index. If `FALSE`, such topics are left out of the output entirely.
#'   Datasets and other non-callable topics are never treated as private,
#'   even though they also aren't in `NAMESPACE`'s exports - see
#'   `.compute_is_private()`. When export status can't be determined at
#'   all (a dev package that has never run `devtools::document()`, so it
#'   has no `NAMESPACE` file yet), every topic is treated as public.
#'
#' @return Invisibly, the path to `output_dir`.
#'
#' @examples
#' \dontrun{
#' # Installed package:
#' csdocs::build_reference("dplyr", output_dir = "docs/reference")
#'
#' # Development package, not installed - "." and "md-docs" are both
#' # defaults, so this is equivalent to just build_reference():
#' csdocs::build_reference(".", output_dir = "md-docs")
#'
#' # Public API only, no internal helpers:
#' csdocs::build_reference("dplyr", output_dir = "docs/reference", include_private = FALSE)
#' }
#'
#' @export
build_reference <- function(
  package = ".",
  output_dir = NULL,
  overwrite = TRUE,
  include_private = TRUE
) {
  stopifnot(is.character(package), length(package) == 1)
  stopifnot(
    is.logical(include_private),
    length(include_private) == 1,
    !is.na(include_private)
  )

  output_dir <- .resolve_output_dir(package, output_dir)
  stopifnot(is.character(output_dir), length(output_dir) == 1)

  metadata <- .read_package_metadata(package)
  db <- .read_rd_db(package)
  exported_names <- .read_exported_names(package)
  topics <- .build_topics(db, metadata$name, exported_names)
  if (!include_private) {
    topics <- purrr::keep(topics, \(topic) !topic$is_private)
  }
  .check_topic_name_collisions(topics)

  fs::dir_create(output_dir)
  .check_existing_output(output_dir, overwrite)
  if (overwrite) {
    .clear_generated_output(output_dir)
  }

  progress_id <- cli::cli_progress_bar(
    "Rendering {metadata$name} reference",
    total = length(topics)
  )

  purrr::walk(topics, \(topic) {
    .write_topic_file(topic, metadata$version, output_dir)
    return(cli::cli_progress_update(id = progress_id))
  })

  .write_index_file(topics, metadata$name, metadata$version, output_dir)
  .write_full_reference_file(
    topics,
    metadata$name,
    metadata$version,
    output_dir
  )

  cli::cli_alert_success(
    "{length(topics)} functions documented in {.path {output_dir}}"
  )

  return(invisible(output_dir))
}

#' Resolve `output_dir`, applying the source-package-only default
#'
#' `"md-docs"` is a reasonable default location next to a package's own
#' source (the common `build_reference(".")` workflow), but there's no
#' similarly obvious spot for an installed package's output - defaulting
#' there too could scatter generated docs into an unexpected/unwanted
#' location relative to whatever directory the user happened to be in.
#' So the default only applies when `package` resolves to a local source
#' directory; otherwise a missing `output_dir` is a clear, actionable
#' error rather than a surprising write location.
#'
#' @param package As passed to `build_reference()`.
#' @param output_dir As passed to `build_reference()` - `NULL` if the
#'   caller didn't supply one.
#' @return The resolved `output_dir` string.
#' @keywords internal
.resolve_output_dir <- function(package, output_dir) {
  if (!is.null(output_dir)) {
    return(output_dir)
  }
  if (!.is_source_path(package)) {
    cli::cli_abort(c(
      "{.arg output_dir} must be provided when {.arg package} is an installed package name.",
      "i" = "The {.val md-docs} default only applies when {.arg package} is a local source directory (e.g. {.code build_reference(\".\")})."
    ))
  }
  return("md-docs")
}

#' Parse every entry of an Rd database into topic lists
#'
#' Topics without a name (e.g. purely internal Rd fragments) are dropped;
#' the result is sorted alphabetically by `name` so that the index and
#' `_full_reference.md` have a stable order.
#'
#' @param db Result of `.read_rd_db()`.
#' @param package Package name.
#' @param exported_names Character vector of the package's exported
#'   names, or `NULL` if unknown - see `.read_exported_names()` and
#'   `.compute_is_private()`.
#' @return List of parsed topic lists, sorted by `name`.
#' @keywords internal
.build_topics <- function(db, package, exported_names = NULL) {
  topics <- purrr::imap(db, \(rd, rd_name) {
    return(.parse_rd_topic(rd, rd_name, package, exported_names))
  })
  topics <- purrr::keep(topics, \(topic) nzchar(topic$name))
  return(topics[order(purrr::map_chr(topics, "name"))])
}

#' Abort if `output_dir` already contains `.md` files
#' @param output_dir Target directory.
#' @param overwrite Whether existing files may be overwritten.
#' @return `NULL`, invisibly. Aborts via `cli::cli_abort()` if needed.
#' @keywords internal
.check_existing_output <- function(output_dir, overwrite) {
  if (overwrite) {
    return(invisible(NULL))
  }
  existing <- fs::dir_ls(output_dir, glob = "*.md")
  if (length(existing) > 0) {
    cli::cli_abort(c(
      "{.path {output_dir}} already contains {length(existing)} .md file(s).",
      "i" = "Set {.code overwrite = TRUE} to overwrite them."
    ))
  }
  return(invisible(NULL))
}

#' Remove every `.md` file already in `output_dir`
#'
#' Called before (re-)writing a build's output when `overwrite = TRUE`, so
#' that a topic renamed or removed from the package since the last build
#' doesn't leave a stale, orphaned `.md` file behind - without this, the
#' directory only ever grows and drifts from what the current package
#' actually documents.
#'
#' @param output_dir Target directory.
#' @return `NULL`, invisibly.
#' @keywords internal
.clear_generated_output <- function(output_dir) {
  existing <- fs::dir_ls(output_dir, glob = "*.md")
  if (length(existing) > 0) {
    fs::file_delete(existing)
  }
  return(invisible(NULL))
}

#' Abort if two topics would collide on the filesystem
#'
#' Two distinct failure modes: (1) a topic whose name is `README` or
#' `_full_reference` (case-insensitive) would silently overwrite one of
#' csdocs's own generated meta files; (2) two topics whose names differ
#' only in letter case (e.g. `Foo`/`foo`) write to the same path on a
#' case-insensitive filesystem (macOS/Windows default), so the second
#' write silently clobbers the first. Both are rare but corrupt the output
#' silently if left unchecked, so they abort the whole build with a clear
#' message rather than producing an incomplete reference.
#'
#' @param topics List of parsed topic lists.
#' @return `NULL`, invisibly. Aborts via `cli::cli_abort()` if needed.
#' @keywords internal
.check_topic_name_collisions <- function(topics) {
  filenames <- purrr::map_chr(topics, \(topic) {
    return(paste0(.safe_filename(topic$name), ".md"))
  })
  lower <- tolower(filenames)

  reserved <- c("readme.md", "_full_reference.md")
  reserved_hits <- unique(filenames[lower %in% reserved])
  if (length(reserved_hits) > 0) {
    cli::cli_abort(
      "Topic name(s) collide with csdocs's generated files: {.val {reserved_hits}}."
    )
  }

  dupes <- unique(filenames[
    duplicated(lower) | duplicated(lower, fromLast = TRUE)
  ])
  if (length(dupes) > 0) {
    cli::cli_abort(
      "Topic name(s) differ only in letter case and would collide on a case-insensitive filesystem: {.val {dupes}}."
    )
  }

  return(invisible(NULL))
}

#' Write the Markdown file for a single topic
#' @param topic Parsed topic list.
#' @param version Package version.
#' @param output_dir Target directory.
#' @return Path to the written file, invisibly.
#' @keywords internal
.write_topic_file <- function(topic, version, output_dir) {
  path <- fs::path(output_dir, paste0(.safe_filename(topic$name), ".md"))
  return(.write_utf8_lines(.render_topic_md(topic, version), path))
}

#' Write the `README.md` index file
#' @param topics List of parsed topic lists.
#' @param package Package name.
#' @param version Package version.
#' @param output_dir Target directory.
#' @return Path to the written file, invisibly.
#' @keywords internal
.write_index_file <- function(topics, package, version, output_dir) {
  path <- fs::path(output_dir, "README.md")
  return(.write_utf8_lines(.render_index_md(topics, package, version), path))
}

#' Write `_full_reference.md` (every topic in a single file)
#'
#' Meant for the Claude Code inject via
#' `@docs/reference/_full_reference.md`. The underscore prefix sorts the
#' file alphabetically to the top of the directory and signals that it is
#' a generated meta file. Each topic section is rendered with
#' `footer = FALSE` - the per-topic "Generated by ... / Back to index"
#' footer and its relative links only make sense in a standalone file, not
#' repeated after every one of potentially hundreds of sections here.
#'
#' @param topics List of parsed topic lists.
#' @param package Package name.
#' @param version Package version.
#' @param output_dir Target directory.
#' @return Path to the written file, invisibly.
#' @keywords internal
.write_full_reference_file <- function(topics, package, version, output_dir) {
  content <- .render_full_reference_md(topics, package, version)
  path <- fs::path(output_dir, "_full_reference.md")
  return(.write_utf8_lines(content, path))
}

#' Render every topic into a single Markdown string
#'
#' The shared core of `_full_reference.md` (written by
#' `.write_full_reference_file()`) and `get_documentation()` (returned
#' directly, no file written) - both want the exact same content, one to
#' disk and one in memory.
#'
#' @param topics List of parsed topic lists.
#' @param package Package name.
#' @param version Package version.
#' @return A single Markdown string.
#' @keywords internal
.render_full_reference_md <- function(topics, package, version) {
  sections <- purrr::map_chr(topics, \(topic) {
    return(.render_topic_md(topic, version, footer = FALSE))
  })
  header <- glue::glue(
    "# {package} \u2014 Full Reference\n\n",
    "**Version:** {version} \u00b7 {length(topics)} functions\n\n",
    "---\n\n",
    .trim = FALSE
  )
  return(paste0(header, paste(sections, collapse = "\n")))
}

#' Get a package's full reference documentation as a single string
#'
#' Returns the same Markdown content that [build_reference()] writes to
#' `_full_reference.md` - every topic rendered and concatenated into one
#' string - without writing anything to disk. Meant for programmatic
#' consumption, e.g. an LLM agent that wants a package's complete
#' reference injected directly into its context in one call.
#'
#' @param package As in [build_reference()].
#' @param include_private If `TRUE`, documented topics that aren't part of
#'   the package's public API are included too - see [build_reference()].
#'   Defaults to `FALSE` here (unlike `build_reference()`'s `TRUE`), since
#'   the primary use case - handing a package's reference to an LLM agent
#'   as context - usually wants the public API only.
#'
#' @return A single string: the package's full reference documentation in
#'   Markdown.
#'
#' @examples
#' \dontrun{
#' # Installed package:
#' docs <- csdocs::get_documentation("dplyr")
#'
#' # Development package, not installed:
#' docs <- csdocs::get_documentation(".")
#' }
#'
#' @export
get_documentation <- function(package = ".", include_private = FALSE) {
  stopifnot(is.character(package), length(package) == 1)
  stopifnot(
    is.logical(include_private),
    length(include_private) == 1,
    !is.na(include_private)
  )

  metadata <- .read_package_metadata(package)
  db <- .read_rd_db(package)
  exported_names <- .read_exported_names(package)
  topics <- .build_topics(db, metadata$name, exported_names)
  if (!include_private) {
    topics <- purrr::keep(topics, \(topic) !topic$is_private)
  }

  return(.render_full_reference_md(topics, metadata$name, metadata$version))
}

#' Resolve package name and version, for either an installed or a source package
#'
#' For an installed package, name/version come from [utils::packageVersion()].
#' For a development package, they are read from the `DESCRIPTION` file in
#' the source directory via [read.dcf()] - this deliberately avoids
#' requiring installation.
#'
#' @param package Name of an installed package, or a path to a local
#'   package source directory.
#' @return A list with fields `name`, `version`.
#' @keywords internal
.read_package_metadata <- function(package) {
  if (.is_source_path(package)) {
    desc <- read.dcf(fs::path(package, "DESCRIPTION"))
    return(list(
      name = unname(desc[1, "Package"]),
      version = unname(desc[1, "Version"])
    ))
  } else {
    return(list(
      name = package,
      version = as.character(utils::packageVersion(package))
    ))
  }
}
