#' Build a Markdown site for a source package
#'
#' Writes the reference, every R Markdown vignette and a front page as
#' Markdown files that read as linked pages on github.com. The output has
#' this layout:
#' \itemize{
#'   \item `README.md`: the front page. It shows the package name, the
#'     version, the source commit when known, a list of articles and a link
#'     to the reference.
#'   \item `reference/`: the output of [build_reference()].
#'   \item `articles/`: one `<name>.md` file for each `vignettes/*.Rmd` file,
#'     with its figures in a folder beside it.
#' }
#'
#' `build_site()` copies the whole `vignettes/` folder to `articles/`, so
#' images and other assets stay beside the articles. It renders each `.Rmd`
#' file there with `rmarkdown::github_document(html_preview = FALSE)`, in a
#' new environment whose parent is the global environment. Then it deletes
#' the copied `.Rmd` files and any `.Rmd.orig` files.
#'
#' The front page lists each article under the `title` field of its YAML
#' header, or under its file name when the header has no title. The commit
#' comes from the `GITHUB_SHA` environment variable, else from
#' `git rev-parse HEAD` in `package`. The front page shows its first 7
#' characters. When neither source gives a commit, the front page omits it.
#'
#' Install the package before you call `build_site()` when a vignette
#' calls `library()` on it. The vignettes run against the installed
#' version, and the reference reads the source.
#'
#' `build_site()` does not render Quarto (`.qmd`) vignettes. It copies them
#' unrendered and gives a warning that names each one.
#'
#' @param package Path to a package source directory, which MUST contain a
#'   `DESCRIPTION` file. An installed package name is an error, because an
#'   installed package has no vignette sources.
#' @param output_dir Target directory. Created if it does not exist.
#' @param overwrite If `TRUE` (the default), `build_site()` deletes the
#'   `README.md` file and the `reference/` and `articles/` folders in
#'   `output_dir` before it writes the new set. If `FALSE`, it aborts when
#'   `output_dir` contains any file or folder.
#'
#' @return Invisibly, the path to `output_dir`.
#'
#' @examples
#' \dontrun{
#' csdocs::build_site(".", output_dir = "docs-build")
#' }
#'
#' @export
build_site <- function(package = ".", output_dir, overwrite = TRUE) {
  stopifnot(is.character(package), length(package) == 1)
  stopifnot(is.character(output_dir), length(output_dir) == 1)
  stopifnot(is.logical(overwrite), length(overwrite) == 1, !is.na(overwrite))
  .check_site_source(package)

  rmd <- .list_vignettes(package, "Rmd")
  .check_render_packages(rmd)

  fs::dir_create(output_dir)
  .prepare_site_dir(output_dir, overwrite)

  build_reference(
    package,
    output_dir = fs::path(output_dir, "reference"),
    overwrite = TRUE
  )
  titles <- .render_articles(package, output_dir)

  metadata <- .read_package_metadata(package)
  .write_utf8_lines(
    .render_site_index_md(
      metadata$name,
      metadata$version,
      .site_commit(package),
      titles
    ),
    fs::path(output_dir, "README.md")
  )
  cli::cli_alert_success(
    "{length(titles)} article(s) and the reference written to {.path {output_dir}}"
  )
  return(invisible(output_dir))
}

#' Abort unless `package` is a package source directory
#' @param package As passed to [build_site()].
#' @return `NULL`, invisibly. Aborts via `cli::cli_abort()` if needed.
#' @keywords internal
.check_site_source <- function(package) {
  if (!.is_source_path(package)) {
    cli::cli_abort(c(
      "{.arg package} must be a package source directory with a {.file DESCRIPTION} file.",
      "x" = "{.val {package}} is not one.",
      "i" = "An installed package has no vignette sources, so {.fn build_site} cannot use it."
    ))
  }
  return(invisible(NULL))
}

#' List the vignette files of one extension in a source package
#' @param package Path to a package source directory.
#' @param ext File extension without the dot, for example `"Rmd"`.
#' @return A character vector of file names, without the folder.
#' @keywords internal
.list_vignettes <- function(package, ext) {
  dir <- fs::path(package, "vignettes")
  if (!fs::dir_exists(dir)) {
    return(character())
  }
  return(sort(list.files(dir, pattern = paste0("\\.", ext, "$"))))
}

#' Abort when vignettes need rendering and rmarkdown or knitr is missing
#' @param rmd File names of the `.Rmd` vignettes.
#' @return `NULL`, invisibly. Aborts via `cli::cli_abort()` if needed.
#' @keywords internal
.check_render_packages <- function(rmd) {
  if (length(rmd) == 0) {
    return(invisible(NULL))
  }
  needed <- c("rmarkdown", "knitr")
  missing <- needed[
    !vapply(needed, requireNamespace, logical(1), quietly = TRUE)
  ]
  if (length(missing) > 0) {
    cli::cli_abort(c(
      "{.fn build_site} needs {.pkg {missing}} to render {length(rmd)} vignette(s).",
      "i" = "Install {.pkg {missing}} and run {.fn build_site} again."
    ))
  }
  return(invisible(NULL))
}

#' Check or clear the output folder of a site
#' @param output_dir Target directory. It MUST exist.
#' @param overwrite As passed to [build_site()].
#' @return `NULL`, invisibly. Aborts via `cli::cli_abort()` if needed.
#' @keywords internal
.prepare_site_dir <- function(output_dir, overwrite) {
  if (!overwrite) {
    existing <- fs::dir_ls(output_dir, all = TRUE)
    if (length(existing) > 0) {
      cli::cli_abort(c(
        "{.path {output_dir}} is not empty: it holds {length(existing)} file(s) or folder(s).",
        "i" = "Set {.code overwrite = TRUE} to replace the generated output."
      ))
    }
    return(invisible(NULL))
  }
  generated <- fs::path(output_dir, c("README.md", "reference", "articles"))
  unlink(generated, recursive = TRUE)
  return(invisible(NULL))
}

#' Copy the vignettes folder to `articles/` and render each `.Rmd` file
#'
#' Warns for each `.qmd` file, which stays unrendered.
#'
#' @param package Path to a package source directory.
#' @param output_dir Target directory of the site.
#' @return A character vector of article titles, named by the relative path
#'   of the `.md` file from `output_dir`.
#' @keywords internal
.render_articles <- function(package, output_dir) {
  source_dir <- fs::path(package, "vignettes")
  if (!fs::dir_exists(source_dir)) {
    return(character())
  }
  articles_dir <- fs::path(output_dir, "articles")
  fs::dir_copy(source_dir, articles_dir)

  qmd <- .list_vignettes(package, "qmd")
  if (length(qmd) > 0) {
    cli::cli_warn(
      "{.fn build_site} does not render Quarto vignettes. Copied unrendered: {.file {qmd}}."
    )
  }

  rmd <- .list_vignettes(package, "Rmd")
  titles <- vapply(
    rmd,
    \(file) .render_article(fs::path(articles_dir, file)),
    character(1)
  )
  names(titles) <- paste0("articles/", sub("\\.Rmd$", ".md", rmd))

  sources <- list.files(
    articles_dir,
    pattern = "\\.Rmd(\\.orig)?$",
    recursive = TRUE,
    full.names = TRUE
  )
  fs::file_delete(sources)
  return(titles)
}

#' Render one `.Rmd` file to GitHub Markdown beside it
#' @param path Path to the copied `.Rmd` file.
#' @return The title of the article.
#' @keywords internal
.render_article <- function(path) {
  rmarkdown::render(
    path,
    output_format = rmarkdown::github_document(html_preview = FALSE),
    envir = new.env(parent = globalenv()),
    quiet = TRUE
  )
  title <- rmarkdown::yaml_front_matter(path)$title
  if (!is.character(title) || length(title) != 1 || !nzchar(title)) {
    title <- sub("\\.Rmd$", "", basename(path))
  }
  return(title)
}

#' Find the commit that a site is built from
#'
#' Reads the `GITHUB_SHA` environment variable, else runs
#' `git -C <package> rev-parse HEAD`. A failure of git gives `NULL`.
#'
#' @param package Path to a package source directory.
#' @return The full commit hash, or `NULL` when no source gives one.
#' @keywords internal
.site_commit <- function(package) {
  sha <- Sys.getenv("GITHUB_SHA")
  if (!nzchar(sha)) {
    sha <- tryCatch(
      suppressWarnings(system2(
        "git",
        c("-C", shQuote(package), "rev-parse", "HEAD"),
        stdout = TRUE,
        stderr = FALSE
      )),
      error = function(e) character()
    )
    if (!is.null(attr(sha, "status")) || length(sha) != 1) {
      return(NULL)
    }
  }
  sha <- trimws(sha)
  if (!grepl("^[0-9a-fA-F]{7,64}$", sha)) {
    return(NULL)
  }
  return(sha)
}

#' Render the front page of a site
#' @param package Package name.
#' @param version Package version.
#' @param commit Full commit hash, or `NULL`.
#' @param titles Article titles, named by the relative path of each `.md`
#'   file, as from `.render_articles()`.
#' @return A character vector of Markdown lines.
#' @keywords internal
.render_site_index_md <- function(package, version, commit, titles) {
  lines <- c(paste0("# ", package, " ", version), "")
  if (!is.null(commit)) {
    lines <- c(
      lines,
      paste0("Built from commit `", substr(commit, 1, 7), "`."),
      ""
    )
  }
  if (length(titles) > 0) {
    label <- gsub("([][\\\\])", "\\\\\\1", unname(titles))
    lines <- c(
      lines,
      "## Articles",
      "",
      paste0("- [", label, "](", names(titles), ")"),
      ""
    )
  }
  return(c(
    lines,
    "## Reference",
    "",
    "- [Every function and object](reference/README.md)"
  ))
}
