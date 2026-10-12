.index_fixture <- function() {
  return(testthat::test_path("fixtures", "indexpkg"))
}

# Build the index of a copy of the fixture package and return its lines.
.build_index_lines <- function(keep_pkgdown = TRUE, include_private = TRUE) {
  pkg_dir <- withr::local_tempdir(.local_envir = parent.frame())
  fs::dir_copy(.index_fixture(), pkg_dir, overwrite = TRUE)
  if (!keep_pkgdown) {
    fs::file_delete(fs::path(pkg_dir, "_pkgdown.yml"))
  }
  out_dir <- withr::local_tempdir(.local_envir = parent.frame())
  suppressMessages(build_reference(
    pkg_dir,
    output_dir = out_dir,
    include_private = include_private
  ))
  return(readLines(fs::path(out_dir, "README.md"), encoding = "UTF-8"))
}

# One row per topic link in the index, with the `##` heading above it.
.index_assignment <- function(lines) {
  heading <- NA_character_
  rows <- list()
  for (line in lines) {
    if (startsWith(line, "## ")) {
      heading <- substring(line, 4)
    }
    file <- regmatches(
      line,
      regexpr("(?<=\\]\\()[^)]+(?=\\.md\\))", line, perl = TRUE)
    )
    if (startsWith(line, "| [") && length(file) == 1) {
      rows[[length(rows) + 1]] <- data.frame(topic = file, heading = heading)
    }
  }
  out <- do.call(rbind, rows)
  return(out[order(out$topic), , drop = FALSE])
}

.index_headings <- function(lines) {
  return(substring(grep("^## ", lines, value = TRUE), 4))
}

.expected_assignment <- function(x) {
  out <- data.frame(topic = names(x), heading = unname(x))
  out <- out[order(out$topic), , drop = FALSE]
  return(out)
}

test_that("index headings follow the _pkgdown.yml sections in declared order", {
  lines <- .build_index_lines()
  expect_identical(
    .index_headings(lines),
    c("Setup", "Readers", "Overlap", "Other")
  )
})

test_that("index puts each fixture topic under its expected _pkgdown.yml heading", {
  lines <- .build_index_lines()
  expected <- .expected_assignment(c(
    csv_reader = "Readers",
    load_config = "Setup",
    load_data = "Setup",
    multi_alias = "Readers",
    overlap_only = "Overlap",
    parse_line = "Readers",
    private_fun = "Setup",
    setup_run = "Setup",
    stray_fun = "Other"
  ))
  expect_identical(.index_assignment(lines), expected, ignore_attr = TRUE)
})

test_that("a topic matching two _pkgdown.yml sections appears once, under the first", {
  lines <- .build_index_lines()
  assignment <- .index_assignment(lines)
  expect_identical(assignment$heading[assignment$topic == "load_data"], "Setup")
  expect_identical(sum(grepl("](load_data.md)", lines, fixed = TRUE)), 1L)
})

test_that("index puts the section desc as a paragraph under its heading", {
  lines <- .build_index_lines()
  at <- match("## Setup", lines)
  expect_identical(lines[at + 2], "Functions that start a session")
  expect_identical(
    lines[match("## Readers", lines) + 2],
    "| Topic | Description | Aliases |"
  )
})

test_that("index groups by \\concept in alphabetical order without _pkgdown.yml", {
  lines <- .build_index_lines(keep_pkgdown = FALSE)
  expect_identical(
    .index_headings(lines),
    c("Alpha family", "alpha lower", "Beta family", "Zeta family", "Other")
  )
  expected <- .expected_assignment(c(
    csv_reader = "Beta family",
    load_config = "Other",
    load_data = "Alpha family",
    multi_alias = "Other",
    overlap_only = "Zeta family",
    parse_line = "alpha lower",
    private_fun = "Beta family",
    setup_run = "Beta family",
    stray_fun = "Beta family"
  ))
  expect_identical(.index_assignment(lines), expected, ignore_attr = TRUE)
})

test_that("index falls back to \\concept grouping when yaml is unavailable", {
  local_mocked_bindings(.yaml_available = function() FALSE)
  lines <- .build_index_lines()
  expect_identical(
    .index_headings(lines),
    c("Alpha family", "alpha lower", "Beta family", "Zeta family", "Other")
  )
})

test_that("index applies include_private = FALSE before grouping", {
  lines <- .build_index_lines(include_private = FALSE)
  assignment <- .index_assignment(lines)
  expect_false("private_fun" %in% assignment$topic)
  expect_identical(nrow(assignment), 8L)
  expect_identical(
    .index_headings(lines),
    c("Setup", "Readers", "Overlap", "Other")
  )
})

test_that("index of an installed package has no _pkgdown.yml sections", {
  expect_null(.read_pkgdown_sections("stats"))
})

test_that("unsupported _pkgdown.yml selectors match nothing", {
  topic <- list(name = "load_data", aliases = c("load_data", "ld"))
  expect_true(.topic_matches_entry(topic, "load_data"))
  expect_true(.topic_matches_entry(topic, "ld"))
  expect_true(.topic_matches_entry(topic, "starts_with('load')"))
  expect_true(.topic_matches_entry(topic, "ends_with(\"_data\")"))
  expect_true(.topic_matches_entry(topic, "matches(\"^l.*a$\")"))
  expect_false(.topic_matches_entry(topic, "starts_with(\"data\")"))
  expect_false(.topic_matches_entry(topic, "has_concept(\"load_data\")"))
  expect_false(.topic_matches_entry(topic, "-load_data"))
})

test_that("index links stay relative and resolve to topic files", {
  pkg_dir <- withr::local_tempdir()
  fs::dir_copy(.index_fixture(), pkg_dir, overwrite = TRUE)
  out_dir <- withr::local_tempdir()
  suppressMessages(build_reference(pkg_dir, output_dir = out_dir))
  dead <- .find_dead_links(out_dir)
  expect_identical(sum(dead$kind == "file"), 0L)
})
