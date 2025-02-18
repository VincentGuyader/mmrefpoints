% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/12_calc_z.R
\name{calc_z}
\alias{calc_z}
\title{Degree of compensation}
\usage{
calc_z(MNPL_in, lh.params_in)
}
\arguments{
\item{MNPL_in}{User-specified value for MNPL (between 0 and 1)}

\item{lh.params_in}{a list of life history parameters}
}
\value{
the value of z corresponding to the value of MNPL (as a proportion of K) that the user has defined.
}
\description{
Calculate the parameter z, the degree of compensation
}
\details{
Helper function for calculating z when user specifies MNPL
}
\examples{
lh.params1 <- list(S0 = .5, S1plus = .944, nages = 25, AgeMat = 18)
test.z <- calc_z(MNPL_in = 0.4, lh.params_in = lh.params1)
}
