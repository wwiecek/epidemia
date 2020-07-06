#' Adds random walks to the parameterization of the time-varying reproduction number.
#'
#' A call to \code{rw} can be used in the 'formula' argument of \code{epim}, allowing 
#' random walks for the reproduction number. Does not evaluate arguments. Simply creates a 
#' list with the information needed for the stan data to be parsed correctly.
#'
#' @param time An optional vector defining the random walk time periods for each 
#'    date and group. Defaults to NA, in which case the column of 'data' representing the dates 
#'    is used. 
#' @param gr Optional vector defining the grouping to used for the random walks. A separate walk is defined 
#'  for each group individually. Defaults to NA, in which case a common random walk is used for all groups.
#' @return A list
#' @examples
#' 
#' x<-c("2020-02-22", "2020-02-23", "2020-02-24", "2020-02-25")
#' rw(x,delta=2)
#' rw(x,delta=1)
#' \dontrun{
#' data("EuropeCovid")
#' args <- EuropeCovid
#' args$formula <- R(country, date) ~ 1 + rw(gr=country) + lockdown
#' }
#' @export
rw <- function(time=NA, gr=NA) {
  label <- deparse(match.call())
  time <- deparse(substitute(time))
  gr <- deparse(substitute(gr))
  out <- loo::nlist(time, gr, label)
  class(out) <- c("rw_term")
  return(out)
}

#' Finds random walk terms in a formula object
#' 
#' @param x An object of class "formula"
#' @export
terms_rw <- function(x) {
  if(!inherits(x,"formula"))
    stop("'formula' must be a formula object.")
  
  # use regex to find random walk terms in formula
  trms <- attr(terms(x), "term.labels")
  match <- grepl("(^(rw)\\([^:]*\\))$", trms)
  
  # ignore when included in a random effects term
  match <- match & !grepl("\\|", trms)
  return(trms[match])
}

# Parses random walk terms
# 
# @param trm A deparsed call to \code{rw}
# @param data The \code{data} argument from \code{epim}, 
# after going through checkData
# @return A list giving number of random walk terms, total 
# number of time periods for each term, and a sparse matrix 
# representing a design matrix for the walks.
parse_term <- function(trm, data) {
  trm <- eval(parse(text=trm))

  # retrieve the time and group vectors
  time <- if(trm$time=="NA") data$date else data[[trm$time]]
  group <- if(trm$gr=="NA") "all" else droplevels(data[[trm$gr]])
  
  fbygr <- split(time, group)
  ntime <- sapply(fbygr, function(x) length(unique(x)))
  nproc <- length(ntime)
  
  f <- paste0(time,",", group)
  f <- ordered(f, levels=unique(f))
  Z <- Matrix::t(as(f, Class="sparseMatrix"))
  
  return(loo::nlist(nproc, ntime, Z))
}

# Parses a sequence of random walk terms, concatenating 
# the results
#
# @param trms A vector of deparsed calls to \code{rw}.
# @inherits parse_term returns
parse_all_terms <- function(trms, data) {
  out <- list()
  for (trm in trms)
    out[[trm]] <- parse_term(trm, data)

  nproc <- do.call(c, args=lapply(out, function(x) x$nproc))
  ntime <- do.call(c, args=lapply(out, function(x) x$ntime))
  Z <- do.call(cbind, args=lapply(out, function(x) x$Z))
  return(loo::nlist(nproc, ntime, Z))
}
