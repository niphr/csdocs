#' Read the `reference:` sections of a source package's `_pkgdown.yml`
#'
#' Returns `NULL` when the index MUST fall back to `\\concept` grouping. That
#' is the case for an installed package, a source package without
#' `_pkgdown.yml`, a file without `reference:` sections, and a session
#' without the `yaml` package.
#'
#' @param package Name of an installed package, or a path to a local
#'   package source directory.
#' @return A list of `list(title, desc, contents)` in declared order, or
#'   `NULL`.
#' @keywords internal
.read_pkgdown_sections <- function(package) {
  if (!.is_source_path(package)) {
    return(NULL)
  }
  path <- fs::path(package, "_pkgdown.yml")
  if (!fs::file_exists(path) || !.yaml_available()) {
    return(NULL)
  }
  reference <- yaml::read_yaml(path)$reference
  # A section without a title, e.g. a lone `subtitle:` entry, gives no
  # heading. Its topics fall through to a later section or to "Other".
  reference <- purrr::keep(reference, \(section) {
    return(is.character(section$title) && length(section$title) == 1)
  })
  if (length(reference) == 0) {
    return(NULL)
  }
  return(purrr::map(reference, \(section) {
    return(list(
      title = section$title,
      desc = section$desc %||% "",
      contents = as.character(unlist(section$contents))
    ))
  }))
}

#' Report whether the `yaml` package is available
#'
#' `yaml` is in Suggests. A separate function lets the tests simulate a
#' session without it.
#'
#' @return `TRUE` or `FALSE`.
#' @keywords internal
.yaml_available <- function() {
  return(requireNamespace("yaml", quietly = TRUE))
}

#' Report whether a topic matches one `contents:` entry of `_pkgdown.yml`
#'
#' An entry matches the topic name or one of its aliases. The supported
#' selectors are `starts_with("x")`, `ends_with("x")` and `matches("x")`.
#'
#' @param topic A parsed topic list.
#' @param entry One `contents:` entry, as a string.
#' @return `TRUE` or `FALSE`.
#' @keywords internal
.topic_matches_entry <- function(topic, entry) {
  names <- unique(c(topic$name, topic$aliases %||% character(0)))
  selector <- regmatches(
    entry,
    regexec(
      "^\\s*(starts_with|ends_with|matches)\\(\\s*[\"'](.*?)[\"']\\s*(,.*)?\\)\\s*$",
      entry,
      perl = TRUE
    )
  )[[1]]
  if (length(selector) == 0) {
    # Any other selector, e.g. has_concept(), lacks_concepts() or a
    # "-name" exclusion, matches nothing. A plain entry is a name or alias.
    is_selector <- grepl("(", entry, fixed = TRUE) || startsWith(entry, "-")
    return(!is_selector && entry %in% names)
  }
  value <- selector[3]
  hits <- switch(
    selector[2],
    starts_with = startsWith(names, value),
    ends_with = endsWith(names, value),
    matches = grepl(value, names, perl = TRUE)
  )
  return(any(hits))
}

#' Assign every topic of the index to one group
#'
#' With `sections`, the groups are the `_pkgdown.yml` sections in declared
#' order, and a topic goes in the first section that matches it. Without
#' `sections`, the groups are the `\\concept` values in alphabetical order,
#' and a topic goes under its alphabetically first concept. Topics in no
#' group go in a final "Other" group. A group without topics is dropped.
#'
#' @param topics List of parsed topic lists.
#' @param sections Result of [.read_pkgdown_sections()], or `NULL`.
#' @return A list of `list(title, desc, topics)`.
#' @keywords internal
.group_index_topics <- function(topics, sections = NULL) {
  if (is.null(sections)) {
    sections <- .concept_sections(topics)
    key <- purrr::map_chr(topics, \(topic) {
      return(.sort_alpha(topic$concepts %||% character(0))[1])
    })
    index <- match(key, purrr::map_chr(sections, "title"))
  } else {
    index <- purrr::map_int(topics, \(topic) {
      hit <- purrr::detect_index(sections, \(section) {
        return(any(purrr::map_lgl(section$contents, \(entry) {
          return(.topic_matches_entry(topic, entry))
        })))
      })
      return(if (hit == 0) NA_integer_ else hit)
    })
  }
  groups <- purrr::imap(sections, \(section, i) {
    section$topics <- topics[which(index == i)]
    return(section)
  })
  other <- list(title = "Other", desc = "", topics = topics[is.na(index)])
  groups <- c(groups, list(other))
  return(purrr::keep(groups, \(group) length(group$topics) > 0))
}

#' Build one section per `\\concept` value, in alphabetical order
#'
#' @param topics List of parsed topic lists.
#' @return A list of `list(title, desc, contents)`.
#' @keywords internal
.concept_sections <- function(topics) {
  concepts <- unique(unlist(purrr::map(topics, "concepts")))
  return(purrr::map(.sort_alpha(concepts), \(concept) {
    return(list(title = concept, desc = "", contents = character(0)))
  }))
}

#' Sort strings alphabetically, ignoring case, independent of the locale
#'
#' @param x Character vector.
#' @return `x`, sorted.
#' @keywords internal
.sort_alpha <- function(x) {
  x <- as.character(x)
  return(x[order(tolower(x), x, method = "radix")])
}
