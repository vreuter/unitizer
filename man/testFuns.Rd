% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/item.sub.R
\docType{class}
\name{testFuns}
\alias{testFuns}
\title{Store Functions for New vs. Reference Test Comparisons}
\description{
\code{testFuns} contains the functions used to compare the results and side
effects of running test expressions.
}
\details{
The default comparison functions are as follows:
\itemize{
  \item value: \code{\link{all.eq}}
  \item conditions: \code{\link{all.eq}}
  \item output: \code{function(x, y) TRUE}, i.e. not compared
  \item message: \code{function(x, y) TRUE}, i.e. not compared as conditions
    should be capturing warnings/errors
  \item aborted: \code{function(x, y) TRUE}, i.e. not compared as conditions
    should also be capturing this implicitly
}
}
\examples{
# use `identical` instead of `all.equal` to compare values
testFuns(value=identical)
}
\seealso{
\code{\link{unitizer_sect}}, \code{\link{all.eq}}
}

