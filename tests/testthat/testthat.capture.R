library(unitizer)
context("Capture")

if(!identical(basename(getwd()), "testthat"))
  stop("Working dir does not appear to be /testthat, is ", getwd())

rdsf <- function(x)
  file.path(getwd(), "helper", "capture", sprintf("%s.rds", x))


# # Messing around trying to understand seek...
# f <- tempfile()
# con <- file(f, "w+b")
# writeChar(paste(letters, LETTERS, collapse=" "), con)
# readChar(con, 20)
# pos <- seek(con, origin="current")
# seek(con, pos, rw="write")
# writeChar("xxxxxxxxx", con)
# readChar(con, 3)
# pos <- seek(con, origin="current")
# seek(con, pos, rw="write")
# writeChar("yyyyy", con)
# close(con)
# readLines(f)
# unlink(f)

test_that("get_capture", {
  old.max <- options(unitizer.max.capture.chars=100L)
  on.exit(options(old.max))
  cons <- new("unitizerCaptCons")
  base.char <- paste(rep(letters, 10), collapse=" ")
  writeChar(base.char, cons@out.c)
  expect_error(
    cpt0 <- unitizer:::get_text_capture(cons, "output", TRUE, chrs.max="howdy"),
    "Argument `chrs.max`"
  )
  expect_warning(
    cpt0 <- unitizer:::get_text_capture(cons, "output", TRUE),
    "Reached maximum text capture"
  )
  expect_equal(cpt0, substr(base.char, 1, 100))
  ## for some reason this test stopped working; not sure why, need to look into
  ## it; seemingly it messes up the pointer for the next read

  # writeChar("xxxxxx", con)
  # cpt2 <- unitizer:::get_text_capture(con, f, "output", TRUE)
  # expect_equal("xxxxxx", cpt2)
  writeChar(paste0(rep("yyyyyyy", 20L), collapse=""), cons@out.c)
  expect_warning(
    cpt1 <- unitizer:::get_text_capture(cons, "output", TRUE),
    "Reached maximum text capture"
  )
  expect_equal(paste0(rep("y", 100), collapse=""), cpt1)
  unitizer:::close_and_clear(cons)
} )

test_that("connection capture works", {
  out.num <- as.integer(stdout())
  err.num <- as.integer(stderr())
  err.con <- getConnection(sink.number(type="message"))

  cons <- new("unitizerCaptCons")
  cons <- unitizer:::set_capture(cons)
  cat("hello there\n")
  cat("goodbye there\n", file=stderr())
  capt <- unitizer:::get_capture(cons)
  cons <- unitizer:::unsink_cons(cons)
  expect_identical(
    capt, structure(list(output = "hello there\n", message = "goodbye there\n")
  ))
  expect_identical(as.integer(stdout()), out.num)
  expect_identical(as.integer(stderr()), err.num)
  expect_identical(
    unitizer:::close_and_clear(cons),
    structure(c(TRUE, TRUE), .Names = c("output", "message"))
  )
  # Now, here we add an extra stdout sink. In both cases unsink_cons will not
  # touch the sinks since we're not in an expected state, leaving
  # close_and_clear to cleanup

  err.con <- getConnection(sink.number(type="message"))
  cons <- new("unitizerCaptCons")
  cons <- unitizer:::set_capture(cons)
  cat("there hello\n")
  cat("there goodbye\n", file=stderr())  # message does not work with testthat
  f1 <- tempfile()
  f2 <- tempfile()
  c2 <- file(f2, "w")
  sink(f1)
  sink(c2, type="message")
  cat("12 there hello\n")
  cat("12 there goodbye\n", file=stderr())  # message does not work with testthat
  capt <- unitizer:::get_capture(cons)
  cons <- unitizer:::unsink_cons(cons)
  expect_identical(
    unitizer:::close_and_clear(cons),
    structure(c(TRUE, TRUE), .Names = c("output", "message"))
  )
  expect_true(attr(cons@out.c, "waive"))
  expect_true(attr(cons@err.c, "waive"))
  expect_identical(
    capt, list(output = "there hello\n", message = "there goodbye\n")
  )
  expect_equal(readLines(f1), "12 there hello")
  expect_equal(readLines(f2), "12 there goodbye")
  close(c2)
  unlink(c(f1, f2))

  # Same, but this time close the sinks properly, so the connections should not
  # be waived

  err.con <- getConnection(sink.number(type="message"))
  cons <- new("unitizerCaptCons")
  cons <- unitizer:::set_capture(cons)
  cat("there hello\n")
  cat("there goodbye\n", file=stderr())  # message does not work with testthat
  f1 <- tempfile()
  f2 <- tempfile()
  c2 <- file(f2, "w")
  sink(f1)
  sink(c2, type="message")
  cat("12 there hello\n")
  cat("12 there goodbye\n", file=stderr())  # message does not work with testthat
  sink()
  sink(cons@err.c, type="message")
  capt <- unitizer:::get_capture(cons)
  cons <- unitizer:::unsink_cons(cons)
  expect_null(attr(cons@out.c, "waive"))
  expect_null(attr(cons@err.c, "waive"))
  expect_identical(
    capt, list(output = "there hello\n", message = "there goodbye\n")
  )
  expect_identical(
    unitizer:::close_and_clear(cons),
    structure(c(TRUE, TRUE), .Names = c("output", "message"))
  )
  expect_equal(readLines(f1), "12 there hello")
  expect_equal(readLines(f2), "12 there goodbye")
  close(c2)
  unlink(c(f1, f2))

  # Try to mess up sink counter by replacing the real sink with a fake sink
  # should lead to a waived connection

  cons <- new("unitizerCaptCons")
  cons <- unitizer:::set_capture(cons)

  f1 <- tempfile()
  sink()
  sink(f1)

  capt <- unitizer:::get_capture(cons)
  cons <- unitizer:::unsink_cons(cons)
  expect_true(attr(cons@out.c, "waive"))
  expect_null(attr(cons@err.c, "waive"))
  expect_identical(
    capt, list(output = "", message = "")
  )
  # Try to fix so that we don't get a full stack release error

  sink()
  sink(cons@out.c)

  expect_identical(
    unitizer:::close_and_clear(cons),
    structure(c(TRUE, TRUE), .Names = c("output", "message"))
  )
  unlink(f1)

  # helper function

  f1 <- tempfile()
  f2 <- tempfile()
  c1 <- file(f1, "w+b")
  c2 <- file(f2, "w+b")
  sink(c2)
  expect_false(unitizer:::is_stdout_sink(c1))
  sink()
  expect_error(unitizer:::is_stdout_sink(f1))
  sink(c1)
  expect_true(unitizer:::is_stdout_sink(c1))
  sink()
  close(c1)
  close(c2)
  unlink(c(f1, f2))
})
# # These tests cannot be run as they blow away the entire sink stack which can
# # mess up any testing done under capture
#
# test_that("connection breaking tests", {
#   # Test the more pernicious error where we substitute the stdout sink
#
#   cons <- new("unitizerCaptCons")
#   cons <- unitizer:::set_capture(cons)
#   cat("woohoo\n")
#   cat("yohooo\n", file=stderr())
#   f1 <- tempfile()
#   sink()
#   sink(f1)
#   capt <- unitizer:::get_capture(cons)
#   cons <- unitizer:::unsink_cons(cons)
#   sink()
#   unlink(f1)
#   expect_true(attr(cons@out.c, "waive"))
#   expect_null(attr(cons@err.c, "waive"))
#   expect_identical(
#     capt, list(output = "woohoo\n", message = "yohooo\n")
#   )
#   expect_identical(
#     unitizer:::close_and_clear(cons),
#     structure(c(FALSE, TRUE), .Names = c("output", "message"))
#   )
# })
test_that("eval with capt", {
  suppressWarnings(glob <- unitizer:::unitizerGlobal$new())
  expect_equal_to_reference(
    (capt <- unitizer:::eval_with_capture(quote(1+1), global=glob))[1:8],
    rdsf(100)
  )
  expect_is(capt[[9]], "unitizerCaptCons")
  expect_equal_to_reference(
    (
      capt <- unitizer:::eval_with_capture(
        cat("wow\n", file=stderr()), global=glob)
    )[1:8],
    rdsf(200)
  )
  expect_is(capt[[9]], "unitizerCaptCons")
})
