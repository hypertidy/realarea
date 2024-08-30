
<!-- README.md is generated from README.Rmd. Please edit that file -->

# realarea

<!-- badges: start -->
<!-- badges: end -->

The goal of realarea is to provide helpers to determine the actual area
covered and the calculated area vs the “real” geographic area
represented in a projected raster.

## Installation

You can install the development version of realarea like so:

``` r
remotes::install_github("hypertidy/realarea")
```

## Example

We have a shapefile and we want to assess suitability of a given map
projection.

``` r
library(realarea)

luxshp <- system.file("ex/lux.shp", package="terra", mustWork = TRUE)
lux <- terra::vect(luxshp)
```

With `crs_grid()` we can create a suitable raster grid from that vector
data set.

By default we just get a nice grid from it in the native crs.

``` r
crs_grid(lux)
#> class       : SpatRaster 
#> dimensions  : 380, 400, 1  (nrow, ncol, nlyr)
#> resolution  : 0.002, 0.002  (x, y)
#> extent      : 5.74, 6.54, 49.44, 50.2  (xmin, xmax, ymin, ymax)
#> coord. ref. : lon/lat WGS 84 (EPSG:4326) 
#> source(s)   : memory
#> name        : layer 
#> min value   :     1 
#> max value   :     1
```

But specify an actual map projection and we can get some more benefit,
and with ‘res’ we can get exactly what we want: a raster from which we
can calculate real-world area (with `terra::expanse()`) and compare that
with the nominal cell size which is `prod(res(<x>))`.

``` r
crs <- "EPSG:23032"
crs_grid(lux, crs = crs)
#> class       : SpatRaster 
#> dimensions  : 520, 360, 1  (nrow, ncol, nlyr)
#> resolution  : 160, 160  (x, y)
#> extent      : 265600, 323200, 5481600, 5564800  (xmin, xmax, ymin, ymax)
#> coord. ref. : ED50 / UTM zone 32N (EPSG:23032) 
#> source(s)   : memory
#> name        : layer 
#> min value   :     1 
#> max value   :     1
```

``` r

luxutm1000 <- crs_grid(lux, crs = crs, res = 1000)
luxaea1000 <- crs_grid(lux, crs = "+proj=aea +lon_0=6 +lat_0=50 +lat_1=50.1 +lat_2=49.4", res = 1000)
```

What is the total area of the input polygon?

What do we get from the two projections?

``` r
library(terra)
#> terra 1.7.81
```

``` r

polyarea <- sum(expanse(lux))
sqrt(polyarea)
#> [1] 50643.96
```

``` r
utmarea <- sum(values(mask(cellSize(luxutm1000), luxutm1000)), na.rm = TRUE)
sqrt(utmarea)
#> [1] 50589.04
```

``` r


## this one is closest to the polygon area
aeaarea <- sum(values(mask(cellSize(luxaea1000), luxaea1000)), na.rm = TRUE)
sqrt(aeaarea)
#> [1] 50645.83
```

``` r

plot(cellSize(luxutm1000)/prod(res(luxutm1000)))
```

<img src="man/figures/README-area-1.png" width="100%" />

``` r

plot(cellSize(luxaea1000)/prod(res(luxaea1000)))
```

<img src="man/figures/README-area-2.png" width="100%" />

So, unsurprsingly the local Albers Equal Area Conic projection is a
better choice than UTM, but do we really care about that level of
discrepancy? Probably not, but you can’t have a single rule that always
works, it depends where, how long how wide, on the projection, what you
need to measure, and what you are actually doing. :)

When folks look for a crs, they often restrict themselves only to codes
(e.g. EPSG) that are pre-defined, that can work ok for nations and
particular well-mapped regions, but there’s no hard rule, you can define
your own projection for particular purposes.

What about other fun projections?

``` r
library(terra)
library(sf)
#> Linking to GEOS 3.12.1, GDAL 3.9.0, PROJ 9.3.1; sf_use_s2() is TRUE
```

``` r
p <- vect(silicate::inlandwaters[5:6, ])
#> old-style crs object detected; please recreate object with a recent sf::st_crs()
#> old-style crs object detected; please recreate object with a recent sf::st_crs()
```

``` r

utm <- crs_grid(p, "EPSG:32755")

plot(cellSize(utm)/prod(res(utm)))
plot(project(p, "EPSG:32755"), add = TRUE)
```

<img src="man/figures/README-vicgrid-1.png" width="100%" />

``` r

vicgrid <- crs_grid(p, "EPSG:7899")

plot(cellSize(vicgrid)/prod(res(vicgrid)))
plot(project(p, "EPSG:7899"), add = TRUE)
```

<img src="man/figures/README-vicgrid-2.png" width="100%" />

What if we had a region like the Albers national projection used by GA?

So, what does that look like?

``` r
albex <- c(112.85,153.69,-43.7,-9.86)
bdy <- reproj::reproj_xy(vaster::vaster_boundary(c(32, 32), albex), 
                         "EPSG:3577", source = "EPSG:4326")

plot(bdy, asp = 1)
```

<img src="man/figures/README-vaster-1.png" width="100%" />

``` r
library(terra)
p <- terra::vect(matrix(albex[c(1, 1, 2, 2, 1, 
             3, 4, 4, 3, 3)], ncol = 2), type = "polygons", crs = "EPSG:4326")
p <- terra::densify(p, 1, flat = TRUE)  ## beware densify, we don't want great circles ...

grd <- crs_grid(p, "EPSG:3577")
terra::plot(grd); plot(project(p, "EPSG:3577"), add = TRUE)
```

<img src="man/figures/README-albersgrid-1.png" width="100%" />

``` r


plot(cellSize(grd)/prod(res(grd)))
oz <- vect(sds::CGAZ(), query = sds::CGAZ_sql("Australia"))
plot(project(oz, "EPSG:3577"), add = TRUE)
```

<img src="man/figures/README-albersgrid-2.png" width="100%" />

Let’s expand that out to Australia’s broader remit, this takes a bit of
special handling and is teaching me something I needed to figure out …
WIP

``` r
ozex <- c(55, 164, -90, -6)
p <- terra::vect(matrix(ozex[c(1, 1, 2, 2, 1, 
             3, 4, 4, 3, 3)], ncol = 2), type = "polygons", crs = "EPSG:4326")
p <- terra::densify(p, 1000)
grd <- crs_grid(p, "EPSG:3577")
grd <- crop(grd, c(xmin(grd), xmax(grd), -7.5e6, ymax(grd)))
agrd <- cellSize(grd)
agrd[!agrd > 1e5] <- NA
plot(agrd/prod(res(agrd)))
m <- reproj::reproj_xy(do.call(cbind, maps::map(plot = F)[1:2]), "EPSG:3577", source = "EPSG:4326")
lines(m)
```

<img src="man/figures/README-ozex-1.png" width="100%" />

## Code of Conduct

Please note that the realarea project is released with a [Contributor
Code of
Conduct](https://contributor-covenant.org/version/2/1/CODE_OF_CONDUCT.html).
By contributing to this project, you agree to abide by its terms.
