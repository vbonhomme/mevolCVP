#' Predictive discriminant analyses based on balanced samples.
#'
#' More about it
#'
#' @param mat matrix with the 'known' data (usually PC scores, but works also with univariate data)
#' @param group grouping factor of the 'known' data
#' @param mattoid matrix with the data to be predicted
#' @param codetoid label of the specimens to predict
#' @param ncpts number of PCs to retain
#' @param nrep number of replicates
#' @param return.matrix `logical` whether to return full results
#' @param limproba a limit for the posterior probability to be concidered
#' @param limCVP a limit for the cross validation % of the discriminate analysis to be concidered
#' @param nrep number of replicates
#' @param minInd the number of specimens to include for the balanced design if smaller than the smallest of the "known" groups
#'
#' @return a `list`
#'
#' @examples
#' # Some examples
#' # Grab some data from pig
#' mat <- pig$mat
#' gp <- pig$gp
#' # For the sake of reproducibility
#' set.seed(123)
#' train_ids <- sample(nrow(mat), 150, replace=FALSE)
#'
#' pldam(# train data
#'       mat=mat[train_ids, ], group=gp[train_ids],
#'       # test data
#'       mattoid=mat[-train_ids, ], codetoid=paste0("id_", 1:nrow(mat[-train_ids, ])),
#'       nrep=2)
#' @export
pldam <- function(mat=mat, group=group,
                  mattoid=mattoid, codetoid=codetoid,
                  ncpts=20, limproba=0, limCVP=FALSE,
                  nrep=100, return.matrix=TRUE, minInd= NULL) {
  mat <- as.matrix(mat)
  mattoid <- as.matrix(mattoid)
  group <- as.factor(as.character(group))
  codetoid <- as.factor(codetoid)
  lgroup <- levels(group)
  ngroup <- length(lgroup)

  if (is.null(minInd)) minInd <- min(table(group))

  a <- table(group)
  print(paste("The analyses are done with", ngroup, "groups"))
  print(a)
  print(paste(nrep, " ressampling"))
  CVbalanced <- vector(length = nrep)
  resultplda <- as.character(codetoid)
  resultpldap <- as.character(codetoid)
  print(paste("The limit % to concider an identification is ", limproba))
  ####
  for (k in 1:nrep) {
    ### calcul mat avec effectifs balanc?s
    matbalanced <- matrix(ncol = ncol(mat), nrow = (minInd * ngroup))
    for (i in 1:ngroup) {
      matg <- as.matrix(mat[which(group == as.character(lgroup[i])), ])
      mati <- as.matrix(matg[sample(1:nrow(matg), minInd, replace = FALSE), ])
      matbalanced[c((i * minInd - minInd + 1):(i * minInd)), ] <- mati
    }
    gpbalanced <- rep(lgroup, each = minInd)
    ## Calcul des prediction
    # balanced samples
    matr <- as.matrix(matbalanced[, 1:ncpts])
    colnames(mattoid) <- colnames(matr)
    z <- MASS::lda(matr, gpbalanced)
    zp <- predict(z, as.matrix(mattoid[, 1:ncpts]))
    maxproba <- apply(zp$post, 1, max)
    resultplda <- cbind(resultplda, as.character(zp$class))
    resultpldap <- cbind(resultpldap, round(maxproba, 2))
    z <- MASS::lda(matr, gpbalanced, CV = TRUE)
    a <- table(z$class, gpbalanced)
    CVbalanced[k] <- sum(diag(a)) / sum(a)
  }

  if (limCVP == FALSE) limCVP <- summary(CVbalanced)[5]
  resultplda <- resultplda[, -1]
  resultpldap <- resultpldap[, -1]
  resultpldaCVP <- as.matrix(resultplda[, which(CVbalanced >= limCVP)])
  resultpldapCVP <- as.matrix(resultpldap[, which(CVbalanced >= limCVP)])
  print(paste("Results are provided for the", ncol(resultpldaCVP), "LDAs that have a CVP above ", limCVP))
  matplda <- matrix(ncol = 6, nrow = length(codetoid))
  for (i in 1:length(codetoid)) {
    matplda[i, 1] <- as.character(codetoid[i])
    tableau <- sort(table(resultpldaCVP[i, which(resultpldapCVP[i, ] >= limproba)]), decreasing = TRUE)
    if (length(tableau != 0)) {
      matplda[i, 2] <- length(resultpldapCVP[i, which(resultpldapCVP[i, ] >= limproba)])
      matplda[i, 3] <- names(tableau)[1]
      matplda[i, 4] <- round(tableau[1] * 100 / sum(tableau), 2)
      if (length(tableau) != 1) matplda[i, 5] <- names(tableau)[2]
      if (length(tableau) != 1) matplda[i, 6] <- round(tableau[2] * 100 / sum(tableau), 2)
    }
  }
  rownames(resultplda) <- rownames(resultpldap) <- codetoid
  colnames(resultplda) <- colnames(resultpldap) <- paste("rep", c(1:nrep), sep = "")
  colnames(matplda) <- c("codetoid", "NumberOfLda", "ID-1", "Proba-1", "ID-2", "Proba-2")

  if (return.matrix == TRUE) return(list(CVbalanced = CVbalanced, resultplda = resultplda, resultpldap = resultpldap, matplda = matplda))
}
