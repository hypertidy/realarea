
## resolution determination from an extent

resdet <- function(x, dim = NULL) {
  if (is.null(dim)) dim <- 36L
  df <- diff(x)[c(1, 3)]
  #r <- df[2]/df[1]
  #dim <- if (r > 1)  c(dim, dim * r) else c(dim * r, dim)
  signif(min(df) / dim, 2)
}

## chunk an extent to a resolution
.align_extent <- function(x, res = NULL, dim = NULL) {
  if (is.null(res)) res <- resdet(x, dim)

  c(as.vector(terra::align(terra::ext(x), res)), res)
}

## function to make a raster from a vector
rit <- function(x, crs = NULL, res = NULL) {
  nores <- FALSE
  if (is.null(res)) nores <- TRUE
  if (!is.null(crs)) x <- terra::project(x, crs)
  exa <- .align_extent(as.vector(terra::ext(x)), res)
  ex <- exa[1:4]
  res <- exa[5]
  if (nores) res <- res / 10

 # print(res)
 # print(ex)
  df <- diff(ex)[c(1, 3)]
  dim <- df / res
 # r <- df[2]/df[1]
#  dim <- if (r > 1)  c(dim, dim * r) else c(dim * r, dim)
  terra::rast(terra::ext(ex), ncols = dim[1], nrows = dim[2], crs = terra::crs(x))

}

#' Make a grid in a crs projection from a vector data set
#'
#' This grid will mask the polygons so that only pixels of interest can be isolated.
#'
#' With ... can specify 'dim = <npixels>' for a side length of the grid, or
#' 'res = <resolution>' a value for the grid. If only dim is provided, or neither then
#' a heuristic is used to find a nice clean extent and resolution for the grid.
#' @param x SpatVector (we're assuming polygons)
#' @param crs a coordinate reference string (projstring, WKT, etc)
#' @param ... arguments res and dim for underlying function
#'
#' @return a SpatRaster, with a 1 for where the polygon was and NA elsewhere
#' @export
#'
#' @examples
#' luxshp <- system.file("ex/lux.shp", package="terra", mustWork = TRUE)
#' lux <- terra::vect(luxshp)
#' crs_grid(lux)
#' crs_grid(lux, crs = "+proj=laea")
#' crs_grid(lux, crs = "+proj=utm +zone=2", res = 1000)
crs_grid <- function(x, crs = NULL, ...) {
  r <- rit(x, crs = crs, ...)
  if (!is.null(crs)) x <- terra::project(x, crs)

  terra::rasterize(x, r)
}
