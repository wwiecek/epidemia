context("Test expected behaviour for different arguments to epiobs")

data("EuropeCovid")
deaths <- EuropeCovid$obs$deaths
args0 <- list()
args0$i2o <- deaths$i2o
args0$formula <- deaths$formula

test_that("wrong i2o throws error", {
  args <- args0
  args$i2o <- rep(0,10)
  expect_error(do.call(epiobs, args), regexp = "No positive values")
  args$i2o <- runif(10)
  expect_warning(do.call(epiobs, args), regexp = "does not sum to 1")
  args$i2o[5] <- -runif(1)
  expect_error(do.call(epiobs, args), regexp = "Negative values found")
})

test_that("Check aspects of formula", {
  args <- args0
  args$formula <- "not a formula"
  expect_error(do.call(epiobs, args), regexp = "'formula' must have class")
  args$formula <- dummy ~ 1
  expect_error(do.call(epiobs, args), regexp = "left hand side")
  args$formula <- dummy(country) ~ 1
  expect_error(do.call(epiobs, args), regexp = "left hand side")
})

test_that("Other wrong arguments", {
  expect_error(
    do.call(epiobs, c(args0, list(link="dummy"))), 
    regexp = "'link' must be one of")
  expect_error(
    do.call(epiobs, c(args0, list(family="dummy"))), 
    regexp = "'family' must be one of")
})
