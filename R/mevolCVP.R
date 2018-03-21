
#' Do mevolCVP
#'
#' More about it
#'
#' @param mat A PCA matrix (individuals in rows and variables in columns).
#' @param group the grouping factor (a vector or a factor)
#' @param lim maximum number of components to be included
#' @param nrep number of resampling.
#' @param return.matrix if =TRUE, the matrix used to draw the graphics is returned.
#' @param minInd the minimum number of specimens to be included in the analyses. By default the number of specimens in the smallest group.
#' @param print.legend `logical` whether to add a legend
#'
#' @return a graph and if `return.matrix` is `TRUE`, then a `list`
#'
#' @examples
#' # Some examples
#' mevolCVP(pig$mat, pig$gp, nrep=2)
#' @export
mevolCVP <- function(mat=mat, group=group,
                     lim=30, nrep=100,
                     return.matrix=FALSE,
                     minInd= NULL, print.legend=TRUE) {
  mat <- as.matrix(mat)
  group <- as.factor(as.character(group))
  lgroup <- levels(group)
  ngroup <- length(lgroup)

  if (is.null(minInd)) minInd <- min(table(group))

  a <- table(group)
  print(paste("The analyses are done with", ngroup, "groups"))
  print(a)

  CVoriginal <- vector(length = lim)
  CVbalanced <- matrix(, nrow = nrep, ncol = lim)
  CVrandom <- matrix(, nrow = nrep, ncol = lim)
  CVbalancedrandom <- matrix(, nrow = nrep, ncol = lim)

  if (ncol(mat) != 1) {
    for (nbc in 2:lim) {
      matr <- mat[, 1:nbc]
      z <- MASS::lda(matr, group, CV = TRUE)
      tablez <- table(z$class, group)
      CVoriginal[nbc] <- 100 * sum(diag(tablez)) / sum(tablez)
    }
  }

  if (ncol(mat) == 1) {
    z <- MASS::lda(mat, group, CV = TRUE)
    tablez <- table(z$class, group)
    CVoriginal <- 100 * sum(diag(tablez)) / sum(tablez)
  }

  for (j in 1:nrep) {
    if (ncol(mat) != 1) {
      matbalanced <- matrix(ncol = ncol(mat))
      for (i in 1:ngroup) {
        matg <- mat[which(group == as.character(lgroup[i])), ]
        mati <- matg[sample(1:nrow(matg), minInd, replace = FALSE), ]
        matbalanced <- rbind(matbalanced, mati)
      }
      matbalanced <- prcomp(matbalanced[-1, ])$x
    }


    if (ncol(mat) == 1) {
      matbalanced <- vector()
      for (i in 1:ngroup) {
        matg <- mat[which(group == as.character(lgroup[i]))]
        mati <- matg[sample(1:length(matg), minInd, replace = FALSE)]
        matbalanced <- c(matbalanced, mati)
      }
      matbalanced <- as.matrix(matbalanced)
    }

    gpbalanced <- rep(lgroup, each = minInd)
    gprandom <- sample(group, length(group), replace = FALSE)
    gpbalancedrandom <- sample(gpbalanced, length(gpbalanced), replace = FALSE)
    if (ncol(mat) != 1) {
      for (nbc in 2:lim) {
        # balanced samples
        matr <- matbalanced[, 1:nbc]
        z <- MASS::lda(matr, gpbalanced, CV = TRUE)
        tablez <- table(z$class, gpbalanced)
        CVbalanced[j, nbc] <- 100 * sum(diag(tablez)) / sum(tablez)
        # balanced randomized samples
        z <- MASS::lda(matr, gpbalancedrandom, CV = TRUE)
        tablez <- table(z$class, gpbalancedrandom)
        CVbalancedrandom[j, nbc] <- 100 * sum(diag(tablez)) / sum(tablez)
        # un balanced randomized samples
        z <- MASS::lda(mat[, 1:nbc], gprandom, CV = TRUE)
        tablez <- table(z$class, gprandom)
        CVrandom[j, nbc] <- 100 * sum(diag(tablez)) / sum(tablez)
      }
    }
    if (ncol(mat) == 1) {
      # balanced samples
      z <- MASS::lda(matbalanced, gpbalanced, CV = TRUE)
      tablez <- table(z$class, gpbalanced)
      CVbalanced[j] <- 100 * sum(diag(tablez)) / sum(tablez)
      # balanced randomized samples
      z <- MASS::lda(matbalanced, gpbalancedrandom, CV = TRUE)
      tablez <- table(z$class, gpbalancedrandom)
      CVbalancedrandom[j] <- 100 * sum(diag(tablez)) / sum(tablez)
      # un balanced randomized samples
      z <- MASS::lda(as.matrix(mat), gprandom, CV = TRUE)
      tablez <- table(z$class, gprandom)
      CVrandom[j] <- 100 * sum(diag(tablez)) / sum(tablez)
    }
  }
  if (ncol(mat) != 1) {
    CVoriginal <- CVoriginal[-1]
    CVbalanced <- CVbalanced[, -1]
    CVrandom <- CVrandom[, -1]
    CVbalancedrandom <- CVbalancedrandom[, -1]
  }
  if (ncol(mat) != 1) {
    par(mfrow = c(1, 1))
    CVbalanceds <- matrix(, lim - 1, 3)
    CVrandoms <- matrix(, lim - 1, 3)
    CVbalancedrandoms <- matrix(, lim - 1, 3)
    for (i in 1:(lim - 1)) {
      CVbalanceds[i, ] <- c(mean(CVbalanced[, i]), quantile(CVbalanced[, i], c(0.05, 0.95))[1:2])
      CVrandoms[i, ] <- c(mean(CVrandom[, i]), quantile(CVrandom[, i], c(0.05, 0.95))[1:2])
      CVbalancedrandoms[i, ] <- c(mean(CVbalancedrandom[, i]), quantile(CVbalancedrandom[, i], c(0.05, 0.95))[1:2])
    }
    plot(x = c(2:lim), y = CVoriginal, type = "l", lwd = 2, col = "white", tck = 0, ylim = range(0:100), axes = FALSE, xlab = "Number of components", ylab = "%", xlim = range(2, lim))
    title(main = paste("mevolCVP computed with ", nrep, " resampling, ", "\n", ngroup, " groups of ", minInd, " ind. min", sep = ""))
    axis(1, at = c(2:lim))
    axis(2, at = c(0, 20, 40, 60, 80, 100))
    box()
    abline(h = c(0, 20, 40, 60, 80, 100), v = c(2:lim), col = "grey", lty = "dotted")
    polygon(c(2:lim, lim:2), c(CVbalancedrandoms[, 2], rev(CVbalancedrandoms[, 3])), col = rgb(255, 255, 0, maxColorValue = 255, alpha = 90), xlim = range(2, lim))
    par(new = TRUE)
    plot(x = c(2:lim), y = CVbalancedrandoms[, 1], type = "l", lty = "solid", lwd = 2, col = rgb(139, 139, 0, maxColorValue = 255, alpha = 100), tck = 1, ylim = range(0:100), axes = FALSE, xlab = "", ylab = "", xlim = range(2, lim))
    polygon(c(2:lim, lim:2), c(CVrandoms[, 2], rev(CVrandoms[, 3])), col = rgb(0, 205, 0, maxColorValue = 255, alpha = 90), xlim = range(2, lim))
    par(new = TRUE)
    plot(x = c(2:lim), y = CVrandoms[, 1], type = "l", lty = "solid", lwd = 2, col = rgb(0, 139, 0, maxColorValue = 255, alpha = 100), tck = 1, ylim = range(0:100), axes = FALSE, xlab = "", ylab = "", xlim = range(2, lim))
    polygon(c(2:lim, lim:2), c(CVbalanceds[, 2], rev(CVbalanceds[, 3])), col = rgb(255, 165, 0, maxColorValue = 255, alpha = 90), xlim = range(2, lim))
    par(new = TRUE)
    plot(x = c(2:lim), y = CVbalanceds[, 1], type = "l", lty = "solid", lwd = 2, col = rgb(255, 140, 0, maxColorValue = 255, alpha = 100), tck = 1, ylim = range(0:100), axes = FALSE, xlab = "", ylab = "", xlim = range(2, lim))
    par(new = TRUE)
    plot(x = c(2:lim), y = CVoriginal, type = "l", lwd = 2, col = "red", tck = 1, ylim = range(0:100), axes = FALSE, xlab = "", ylab = "", xlim = range(2, lim))
    if (print.legend == TRUE) legend("bottomright", c("CVoriginal", "CVbalanced", "CVrandom", "CVbalancedrandom"), col = c("red", "orange", "green", "yellow"), lty = 1, lwd = 2, bty = "n")
  }

  if (ncol(mat) == 1) {
    par(mfrow = c(1, 1))
    CVbalanceds <- c(mean(CVbalanced[, 1]), quantile(CVbalanced[, 1], c(0.05, 0.95))[1:2])
    CVrandoms <- c(mean(CVrandom[, 1]), quantile(CVrandom[, 1], c(0.05, 0.95))[1:2])
    CVbalancedrandoms <- c(mean(CVbalancedrandom[, 1]), quantile(CVbalancedrandom[, 1], c(0.05, 0.95))[1:2])
    plot(x = 2, y = CVoriginal, type = "l", lwd = 2, col = "white", ylim = range(0:100), xlab = "Samples", ylab = "%", xlim = range(0, 3), axes = "FALSE")
    title(main = paste("mevolCVP computed with ", nrep, " resampling, ", "\n", ngroup, " groups of ", minInd, " ind. min", sep = ""))

    axis(1, c(1, 2), labels = c("a", "b"))
    axis(2)
    box()
    abline(h = c(0, 20, 40, 60, 80, 100), v = c(1, 2), col = "grey", lty = "dotted")
    lines(c(2, 2), c(CVbalancedrandoms[2], CVbalancedrandoms[3]), col = rgb(255, 255, 0, maxColorValue = 255, alpha = 90), xlim = range(0, 3), lwd = 5)
    par(new = TRUE)
    points(x = c(2, 2, 2), y = c(CVbalancedrandoms[1], CVbalancedrandoms[2], CVbalancedrandoms[3]), pch = 20, cex = 2, col = rgb(139, 139, 0, maxColorValue = 255, alpha = 100), ylim = range(0:100), xlim = range(0, 3))
    lines(c(1, 1), c(CVrandoms[2], CVrandoms[3]), col = rgb(0, 205, 0, maxColorValue = 255, alpha = 90), xlim = range(2, lim), lwd = 5)
    par(new = TRUE)
    points(x = c(1, 1, 1), y = c(CVrandoms[1], CVrandoms[2], CVrandoms[3]), pch = 20, cex = 2, col = rgb(0, 139, 0, maxColorValue = 255, alpha = 100), ylim = range(0:100), xlim = range(0, 3))
    lines(c(2, 2), c(CVbalanceds[2], CVbalanceds[3]), col = rgb(255, 165, 0, maxColorValue = 255, alpha = 90), xlim = range(2, lim), lwd = 5)
    par(new = TRUE)
    points(x = c(2, 2, 2), y = c(CVbalanceds[1], CVbalanceds[2], CVbalanceds[3]), pch = 20, cex = 2, col = rgb(255, 140, 0, maxColorValue = 255, alpha = 100), ylim = range(0:100), xlim = range(0, 3))
    par(new = TRUE)
    points(x = 1, y = CVoriginal, pch = 20, cex = 2, col = "red", ylim = range(0:100), xlab = "Number of components", ylab = "%", xlim = range(0, 3))
    if (print.legend == TRUE) legend(0, 20, c("CVoriginal", "CVbalanced", "CVrandom", "CVbalancedrandom"), col = c("red", "orange", "green", "yellow"), lty = 1, lwd = 2, bty = "o")
  }
  if (return.matrix == TRUE) {
    names(CVoriginal) <- paste(1:length(CVoriginal) + 1, "PCs", sep = "")
  }
  colnames(CVbalanced) <- colnames(CVbalancedrandom) <- colnames(CVrandom) <- paste(1:ncol(CVbalanced) + 1, "PCs", sep = "")
  CVsummary <- cbind(CVbalanceds, CVrandoms, CVbalancedrandoms)
  colnames(CVsummary) <- paste(rep(c("mean-", "CI5%-", "CI95%-"), 3), rep(c("CVbalanced", "CVrandom", "CVbalancedrandom"), each = 3), sep = "")
  rownames(CVsummary) <- paste(1:nrow(CVsummary) + 1, "PCs", sep = "")
  return(list(CVoriginal = CVoriginal, CVbalanced = CVbalanced, CVrandom = CVrandom, CVbalancedrandom = CVbalancedrandom, CVsummary = CVsummary))
}
