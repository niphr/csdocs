# Run the static-checks job of niphr/cstemplate r-package.yml on this machine.
#
# Usage, from the package root:
#   Rscript dev/static.R
#
# The four step functions below are the R code of that job, copied from
# cstemplate main at 9ce2b9ba47f55549ba57769357bd2fc8ceac16c7. Do not edit
# them here. Copy them again when the job changes.
#
# This script changes three things, and only these:
#   1. It sets the job inputs as environment variables. The values are the
#      r-package.yml defaults, because .github/workflows/check.yml overrides
#      none of them. Both allowlists are empty.
#   2. It runs the install step only when the gate library lacks the pinned
#      org commit or the pinned lintr and cyclocomp versions. When that step
#      fails, it runs install_fallback(). pak builds org from source, and on
#      Windows that needs Rtools for the running R version, even though org
#      has no compiled code. remotes builds org without Rtools.
#   3. It runs the code-line step and the lint step even when the other one
#      fails, prints "LINTS <n>", and exits 1 when either step fails.
#
# The gate library is separate from the user library, so the gate packages
# never shadow the packages of a normal R session.

Sys.setenv(
  GATE_LIB = file.path(
    tools::R_user_dir("csdocs", "cache"),
    "static-checks-library"
  ),
  CODE_FILES = tempfile("code-files-", fileext = ".txt"),
  MAX_LOC = "1000",
  LOC_ALLOWLIST = "",
  MAX_CYCLOCOMP = "15",
  LINT_ALLOWLIST = "",
  LINTR_VERSION = "3.4.0",
  CYCLOCOMP_VERSION = "1.1.2"
)
org_sha <- "33f76369f6eceb9fcb1eb7734500e52450e27384"
gate <- new.env()
gate$lints <- NA_integer_

gate_ready <- function() {
  lib <- Sys.getenv("GATE_LIB")
  want <- c(
    lintr = Sys.getenv("LINTR_VERSION"),
    cyclocomp = Sys.getenv("CYCLOCOMP_VERSION")
  )
  have <- function(p) {
    return(nzchar(system.file(package = p, lib.loc = lib)))
  }
  if (!all(vapply(c("org", names(want)), have, logical(1)))) {
    return(FALSE)
  }
  got <- vapply(
    names(want),
    function(p) as.character(utils::packageVersion(p, lib.loc = lib)),
    character(1)
  )
  sha <- utils::packageDescription("org", lib.loc = lib)$RemoteSha
  return(identical(unname(got), unname(want)) && identical(sha, org_sha))
}

install_fallback <- function() {
  lib <- Sys.getenv("GATE_LIB")
  .libPaths(c(lib, .libPaths()))
  pak::pak(c("remotes", "lintr", "cyclocomp"), lib = lib, ask = FALSE)
  remotes::install_github(
    paste0("raubreywhite/org@", org_sha),
    lib = lib,
    upgrade = "never",
    dependencies = NA
  )
  if (!gate_ready()) {
    stop("The gate library still lacks the pinned packages.", call. = FALSE)
  }
  return(invisible(TRUE))
}

run_step <- function(name, step) {
  ok <- tryCatch(
    {
      step()
      TRUE
    },
    error = function(e) {
      message("FAILED: ", name, "\n", conditionMessage(e))
      return(FALSE)
    }
  )
  return(ok)
}

# Step "Install the gate packages", copied verbatim.
install_step <- function() {
  lib <- Sys.getenv("GATE_LIB")
  dir.create(lib, recursive = TRUE, showWarnings = FALSE)
  install.packages(
    "pak",
    lib = lib,
    repos = sprintf(
      "https://r-lib.github.io/p/pak/stable/%s/%s/%s",
      .Platform$pkgType,
      R.version$os,
      R.version$arch
    )
  )
  .libPaths(c(lib, .libPaths()))
  pak::pak(
    c(
      "raubreywhite/org@33f76369f6eceb9fcb1eb7734500e52450e27384",
      "lintr",
      "cyclocomp"
    ),
    lib = lib,
    ask = FALSE
  )

  # pak accepts pkg@version for a CRAN package and then installs the
  # repository's current version anyway, with no error and no warning.
  # Measured on pak 0.9.0: pkg_deps("cran::lintr@99.0.0") returned
  # 3.3.0-1. So step the version here, and assert it below. Never
  # trust the ref syntax alone.
  want <- c(
    lintr = Sys.getenv("LINTR_VERSION"),
    cyclocomp = Sys.getenv("CYCLOCOMP_VERSION")
  )
  for (p in names(want)) {
    got <- as.character(utils::packageVersion(p, lib.loc = lib))
    if (!identical(got, want[[p]])) {
      remotes::install_version(
        p,
        version = want[[p]],
        lib = lib,
        dependencies = FALSE,
        upgrade = "never"
      )
    }
  }

  got <- vapply(
    names(want),
    function(p) as.character(utils::packageVersion(p, lib.loc = lib)),
    character(1)
  )
  if (!identical(unname(got), unname(want))) {
    stop(
      "The gate needs these versions:\n",
      paste0("  ", names(want), " ", want, collapse = "\n"),
      "\nIt installed these:\n",
      paste0("  ", names(got), " ", got, collapse = "\n"),
      "\nRe-measure the package, then change lintr-version or",
      " cyclocomp-version.",
      call. = FALSE
    )
  }
  cat(
    "Gate packages: ",
    paste0(names(got), " ", got, collapse = ", "),
    "\n",
    sep = ""
  )
}

# Step "Select the package code files", copied verbatim.
select_step <- function() {
  # R collates every file in R/ whose extension is in
  # tools:::.make_file_exts("code"). Sys.glob("R/*.R") saw one of the
  # five, so a file named `.r` was invisible to this gate.
  code_exts <- c("R", "r", "S", "s", "q")

  # Fail loudly if a future R adds a sixth, rather than check fewer
  # files than R loads.
  if (
    exists(".make_file_exts", envir = asNamespace("tools"), inherits = FALSE)
  ) {
    r_exts <- tools:::.make_file_exts("code")
    if (!setequal(r_exts, code_exts)) {
      stop(
        "R collates these code extensions: ",
        paste(r_exts, collapse = " "),
        "\nThis gate checks: ",
        paste(code_exts, collapse = " "),
        "\nUpdate code_exts in the workflow.",
        call. = FALSE
      )
    }
  }

  # grep() over the listing, never a glob. Sys.glob() hands the match
  # to the OS. A case-insensitive filesystem then matches foo.r
  # against "R/*.R", so a union of five globs counts one file five
  # times. list.files() returns each entry once and grep() decides in
  # R, case-sensitively. This mirrors tools::list_files_with_exts().
  pattern <- paste0("\\.(", paste(code_exts, collapse = "|"), ")$")

  # R also collates an OS subdirectory of R/, so a file there is
  # package code that no listing of R/ alone can see.
  #
  # Check both, not the runner's OS alone. R CMD INSTALL collates the
  # runner's subdirectory only, but R CMD check reads both on either
  # platform: tools:::.check_package_code_syntax() passes
  # OS_subdirs = c("unix", "windows"). Every job here runs on
  # ubuntu-latest, so a runner-OS gate never looks in R/windows/. It
  # also rejects a loc-allowlist entry for a file there, calling it
  # stale, which leaves that file no way to be exempted.
  #
  # R collates these three directories and no others. R/helpers/ is
  # not package code, so this loop must not recurse. list.files()
  # returns nothing for a directory that does not exist, so a package
  # without R/unix/ needs no guard here.
  files <- character()
  for (d in c("R", "R/unix", "R/windows")) {
    found <- list.files(d, all.files = FALSE)
    files <- c(files, file.path(d, grep(pattern, found, value = TRUE)))
  }
  files <- sort(files)

  # A selection that matches nothing must fail, not pass as compliance.
  if (length(files) == 0) {
    stop(
      "Found no code file in R/ with an extension R collates (",
      paste0(".", code_exts, collapse = ", "),
      "), so the limit checked nothing.",
      call. = FALSE
    )
  }
  writeLines(files, Sys.getenv("CODE_FILES"))
  cat("Selected ", length(files), " code files.\n", sep = "")
}

# Step "Check the code lines in every code file", copied verbatim.
loc_step <- function() {
  .libPaths(c(Sys.getenv("GATE_LIB"), .libPaths()))
  files <- readLines(Sys.getenv("CODE_FILES"))

  # An empty list would pass as compliance. The selection step already
  # stops on it, so reaching here empty means the list did not survive
  # to this step.
  if (length(files) == 0) {
    stop(
      "The code file list is empty, so this gate checked nothing.",
      call. = FALSE
    )
  }
  max_loc <- suppressWarnings(as.numeric(Sys.getenv("MAX_LOC")))
  if (is.na(max_loc)) {
    stop(
      "max-loc must be one number. It arrived as: ",
      Sys.getenv("MAX_LOC"),
      call. = FALSE
    )
  }

  allowlist <- strsplit(Sys.getenv("LOC_ALLOWLIST"), "\n", fixed = TRUE)[[1]]
  allowlist <- trimws(allowlist)
  allowlist <- allowlist[nzchar(allowlist)]

  # A stale entry that silently does nothing is how an allowlist
  # outlives its reason.
  stale <- setdiff(allowlist, files)
  if (length(stale) > 0) {
    stop(
      "These loc-allowlist entries name no file in R/:\n",
      paste0("  ", stale, collapse = "\n"),
      "\nRemove them from loc-allowlist.",
      call. = FALSE
    )
  }

  counts <- org::loc_per_file(files)
  over <- counts[counts > max_loc & !names(counts) %in% allowlist]
  if (length(over) > 0) {
    stop(
      "These files hold more than ",
      max_loc,
      " code lines:\n",
      paste0("  ", names(over), " (", over, ")", collapse = "\n"),
      "\nSplit them, or add them to loc-allowlist.",
      call. = FALSE
    )
  }

  cat(
    "Checked ",
    length(files),
    " files against a limit of ",
    max_loc,
    ". The maximum is ",
    max(counts),
    ".\n",
    sep = ""
  )
}

# Step "Lint every code file", copied verbatim.
lint_step <- function() {
  .libPaths(c(Sys.getenv("GATE_LIB"), .libPaths()))
  files <- readLines(Sys.getenv("CODE_FILES"))
  if (length(files) == 0) {
    stop(
      "The code file list is empty, so this gate checked nothing.",
      call. = FALSE
    )
  }

  max_cyclocomp <- suppressWarnings(as.integer(Sys.getenv("MAX_CYCLOCOMP")))
  if (is.na(max_cyclocomp)) {
    stop(
      "max-cyclocomp must be one whole number. It arrived as: ",
      Sys.getenv("MAX_CYCLOCOMP"),
      call. = FALSE
    )
  }

  # lintr drops cyclocomp_linter() when cyclocomp is absent. The gate
  # would then check one thing less and still report success.
  if (!requireNamespace("cyclocomp", quietly = TRUE)) {
    stop(
      "cyclocomp is not installed, so cyclocomp_linter() would check nothing.",
      call. = FALSE
    )
  }

  # An explicit list, never lintr::default_linters. A lintr release
  # adds new default linters, so a defaults-based gate turns red on a
  # package that did not change. That is why r-version is pinned too.
  linters <- list(
    cyclocomp_linter = lintr::cyclocomp_linter(max_cyclocomp),
    seq_linter = lintr::seq_linter(),
    vector_logic_linter = lintr::vector_logic_linter(),
    T_and_F_symbol_linter = lintr::T_and_F_symbol_linter(),
    condition_call_linter = lintr::condition_call_linter(),
    # The house style is an explicit return(). org is written that way
    # and most of the fleet is not, so this linter is what makes them
    # agree.
    return_linter = lintr::return_linter(return_style = "explicit"),
    # The house rules that no other tool checks.
    undesirable_function_linter = lintr::undesirable_function_linter(
      fun = c(
        sapply = "use vapply(), which pins the return type",
        setwd = "use the paths org::project gives you",
        attach = "never; it hides where a name came from",
        saveRDS = "use qs2::qs_save()",
        readRDS = "use qs2::qs_read()"
      )
    )
  )

  # parse_settings = FALSE, so a .lintr file inside a package cannot
  # weaken the shared gate. Exemptions go through lint-allowlist, which
  # this step checks for staleness.
  found <- do.call(
    rbind,
    lapply(files, function(f) {
      l <- lintr::lint(f, linters = linters, parse_settings = FALSE)
      if (length(l) == 0) {
        return(NULL)
      }
      # Carry the path from the selection list, not lintr's own
      # filename. lintr returns an absolute path, and lint-allowlist
      # entries are repo-relative, so matching on lintr's path would
      # make every allowlist entry look unused.
      data.frame(
        file = f,
        line = vapply(l, function(x) x$line_number, integer(1)),
        linter = vapply(l, function(x) x$linter, character(1)),
        message = vapply(l, function(x) x$message, character(1)),
        stringsAsFactors = FALSE
      )
    })
  )
  if (is.null(found)) {
    found <- data.frame(
      file = character(),
      line = integer(),
      linter = character(),
      message = character(),
      stringsAsFactors = FALSE
    )
  }

  allowlist <- strsplit(Sys.getenv("LINT_ALLOWLIST"), "\n", fixed = TRUE)[[1]]
  allowlist <- trimws(allowlist)
  allowlist <- allowlist[nzchar(allowlist)]

  malformed <- allowlist[!grepl("^[^:]+:[A-Za-z0-9._]+$", allowlist)]
  if (length(malformed) > 0) {
    stop(
      "These lint-allowlist entries are not <path>:<linter>:\n",
      paste0("  ", malformed, collapse = "\n"),
      call. = FALSE
    )
  }

  # Two staleness checks, because an entry can go stale two ways. The
  # file can disappear, and the lint can be fixed while the entry stays.
  entry_file <- sub(":[^:]*$", "", allowlist)
  stale_file <- allowlist[!entry_file %in% files]
  if (length(stale_file) > 0) {
    stop(
      "These lint-allowlist entries name no file this gate checks:\n",
      paste0("  ", stale_file, collapse = "\n"),
      "\nRemove them from lint-allowlist.",
      call. = FALSE
    )
  }

  # recycle0 = TRUE, or paste0() returns ":" for a package with no
  # lints, and a length-1 key indexes the empty data frame into one row
  # of NA. The gate then fails on exactly the packages that are clean.
  key <- paste0(found$file, ":", found$linter, recycle0 = TRUE)
  unused <- setdiff(allowlist, key)
  if (length(unused) > 0) {
    stop(
      "These lint-allowlist entries suppress no lint:\n",
      paste0("  ", unused, collapse = "\n"),
      "\nRemove them from lint-allowlist.",
      call. = FALSE
    )
  }

  over <- found[!key %in% allowlist, , drop = FALSE]
  # dev/static.R only: record the count for the LINTS line.
  gate$lints <- nrow(over)
  # Print the lints, then stop with a short message. stop() cuts its
  # message at getOption("warning.length"), which is 1000 bytes by
  # default and 8170 at most. A run with 106 lints ended mid-line and
  # hid the rest.
  if (nrow(over) > 0) {
    writeLines(c(
      "These lints must be fixed:",
      paste0(
        "  ",
        over$file,
        ":",
        over$line,
        "  ",
        over$linter,
        "  ",
        over$message
      )
    ))
    stop(
      nrow(over),
      " lints must be fixed. The list is above.",
      "\nFix them, or add <path>:<linter> to lint-allowlist.",
      call. = FALSE
    )
  }

  cat(
    "Linted ",
    length(files),
    " files with ",
    length(linters),
    " linters. No findings.\n",
    sep = ""
  )
}

if (
  !gate_ready() &&
    !run_step("Install the gate packages", install_step) &&
    !run_step("Install the gate packages without Rtools", install_fallback)
) {
  quit(status = 1)
}
if (!run_step("Select the package code files", select_step)) {
  quit(status = 1)
}
loc_ok <- run_step("Check the code lines in every code file", loc_step)
lint_ok <- run_step("Lint every code file", lint_step)
cat("LINTS", gate$lints, "\n")
if (!loc_ok || !lint_ok) {
  quit(status = 1)
}
