#' Generate discretized and truncated data from a latent exponential
#' generalized linear model with natural parameter exp(X b)
#'
#' @param X An n x p design matrix
#' @param b A vector of p regression coefficients
#' @param d A scalar controlling the coarseness of the support, where d = 1
#'  means integer support (see details)
#' @param ymax An upper bound on the observable response (see details)
#'
#' @return A matrix with n rows and 2 columns; the first is the lower endpoint
#'  of the observed interval and the second the upper endpoint (see details)
#'
#' @details{
#'   Data are generated by (i) draw y ~ Exp(exp(X b)), (ii) replace y by floor(y
#'   / d) * d, and (iii) replace every element of y greater than ymax by ymax;
#'   this gives the lower endpoint of the interval. Observe that the operation
#'   floor(y / d) * d sets y to the nearest smaller multiple of d.
#'
#'   The upper endpoint of the observed interval is yupp = y + d, unless y =
#'   y_max in which case yupp = Inf.
#'  }
#'
#' @export
generate_ee <- function(X, b, d = 1, ymax = 10){
  # Do argument checking
  stopifnot(is.matrix(X))
  p <- ncol(X)
  n <- nrow(X)
  stopifnot(is.numeric(b), length(b) == p)
  stopifnot(is.numeric(d), length(d) == 1, d > 0)
  stopifnot(is.numeric(ymax), length(ymax) == 1, ymax >= 0)
  
  eta <- X %*% b
  y <- stats::rexp(n = nrow(X), rate = exp(X %*% b))
  y <- floor(y / d) * d
  y <- pmin(y, ymax)
  yupp <- y + d
  yupp[y == ymax] <- Inf
  return(cbind(y, yupp))
}

#' Compute value and derivatives of an elastic net-penalized negative
#' log-likelihood corresponding to a latent exponential generalized linear model
#' with natural parameter exp(X b)
#' 
#' @param y A vector of n observed responses (see details in fit_ee)
#' @param X An n x p matrix of predictors
#' @param b A vector of p regression coefficients
#' @param yupp A vector of n upper endpoints of intervals corresponding to y
#'   (see details in fit_ee)
#' @param lam A scalar penalty parameter
#' @param alpha A scalar weight for elastic net (1 = lasso, 0 = ridge)
#' @param pen_factor A vector of coefficient-specific penalty weights; defaults
#' to 0 for first element of b and 1 for the remaining.
#' @param order An integer where 0 means only value is computed; 1 means both value
#'   and sub-gradient; and 2 means value, sub-gradient, and Hessian (see details)
#' @return A list with elements "obj", "grad", and "hessian" (see details)
#' 
#' @details{
#'  When order = 0, the gradient and Hessian elements of the return list are set
#'  to all zeros, and similarly for the Hessian when order = 1.
#'  
#'  The sub-gradient returned is that obtained by taking the sub-gradient of the
#'  absolute value to equal zero at zero. When no element of b is zero, this is
#'  the usual gradient. The Hessian returns is that of the smooth part of the
#'  objective function that is, the average negative log-likelihood plus the L2
#'  penalty only. When no element of b is zero, this is the Hessian of the
#'  objective function
#' }
#' @export
obj_diff <- function(y, X, b, yupp, lam = 0, alpha = 1, pen_factor = c(0, rep(1, ncol(X) - 1)), order){
  # Do argument checking
  stopifnot(is.matrix(X))
  p <- ncol(X)
  n <- nrow(X)
  stopifnot(is.numeric(b), length(b) == p)
  stopifnot(is.numeric(y), is.null(dim(y)), length(y) == n)
  stopifnot(is.numeric(yupp), is.null(dim(yupp)), length(yupp) == n)
  stopifnot(is.numeric(lam), length(lam) == 1)
  stopifnot(is.numeric(alpha), length(alpha) == 1,
            alpha >= 0, alpha <= 1)
  stopifnot(is.numeric(pen_factor), is.null(dim(pen_factor)),
            length(pen_factor) == p)
  stopifnot(is.numeric(order), length(order) == 1, order %in% 0:2)

  obj_diff_cpp(y, X, b, yupp, lam1 = alpha * lam * pen_factor, lam2 = (1 - alpha) * lam * pen_factor, order)
}