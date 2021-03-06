library(testthat)

local({
  # Install test packages, and set them up for removal, here in package name
  # =dirname format

  library(methods)
  library(unitizer)

  cat("setup packages\n")
  tmp.pkgs <- c(
    unitizerdummypkg1="unitizerdummypkg1",
    unitizerdummypkg2="unitizerdummypkg2",
    utzflm="flm0"
  )
  if(
    any(which.inst <- names(tmp.pkgs) %in% rownames(installed.packages()))
  ) {
    stop(
      "Packages\n",
      paste0(
        deparse(names(tmp.pkgs)[which.inst], width.cutoff=500), collapse=""
      ),
      "\nalready installed; cannot proceed with tests"
  ) }
  old.opt.1 <- options(useFancyQuotes=FALSE)
  on.exit({
    for(i in names(tmp.pkgs)) {
      try(detach(sprintf("package:%s", i)), silent=TRUE)
      try(unloadNamespace(i), silent=TRUE)
    }
    suppressWarnings(remove.packages(names(tmp.pkgs)))
    options(old.opt.1)
  })
  unitizer.dir <- system.file(package="unitizer")
  pkg.dirs <- file.path(unitizer.dir, "expkg", tmp.pkgs)

  pkg.inst <- try(
    for(pkg in pkg.dirs)
      devtools::install(pkg, quiet=TRUE, quick=TRUE, local=FALSE)
  )
  if(inherits(pkg.inst, "try-error")) stop("install error")
  cat("setup demos\n")

  # Setup the demo files used by a number of tests

  .unitizer.fastlm <- copy_fastlm_to_tmpdir()
  test.dir <- file.path(.unitizer.fastlm, "tests", "unitizer")
  .unitizer.test.file <- file.path(test.dir,  "fastlm1.R")
  .unitizer.test.store <- file.path(test.dir,  "fastlm1.unitizer")

  # Ensure same behavior interactive and non-interactive

  .old.err.call.opt <- if(isTRUE(getOption("showErrorCalls")))
     options(showErrorCalls=FALSE) else list()
  on.exit(
    {
      options(.old.err.call.opt)
      unitizer_cleanup_demo()
    },
    add=TRUE
  )
  # Run tests

  test.res <- test_dir(
    "testthat",
    env=environment(),
    filter=paste(sep="|",
      "browse",
      "capture",
      "change",
      "demo",
      "exec",
      "get",
      "global",
      "handledruns",
      "inpkg",
      "ischecks",
      "item",
      "list",
      "misc",
      "options",
      "parse",
      "prompt",
      "rename",
      "repairenvs",
      "search",
      "section",
      "shim",
      "state",
      "text",
      "translate",
      "unitize",
      "unitize2",
      "upgrade",
      "zzrunlast"
    )
  )

  # Check for failures and throw error if they exist since test_dir does not
  # do so on its own
  # Check for failures and throw error if they exist since test_dir does not
  # do so on its own

  with(
    as.data.frame(test.res), {
      fail <- sum(failed)
      err <- sum(error)
      if(fail != 0 || err) stop("Errors: ", err, " Failures: ", fail)
  })
})
