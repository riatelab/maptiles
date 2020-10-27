
<!-- README.md is generated from README.Rmd. Please edit that file -->

# maptiles

<!-- badges: start -->
<!-- badges: end -->

The goal of `maptiles` is to download, compose and display map tiles.

## Installation

<!-- You can install the released version of maptiles from [CRAN](https://CRAN.R-project.org) with: -->
<!-- ``` r -->
<!-- install.packages("maptiles") -->
<!-- ``` -->

You can install the development version of maptiles from GitHub with:

``` r
# install.packages("devtools")
devtools::install_github("rCarto/maptiles")
```

## Example

This is a basic example which shows you how to dowload OpenStreetMap
tiles over North Carolina:

``` r
library(sf)
#> Linking to GEOS 3.7.1, GDAL 3.1.2, PROJ 7.1.0
library(maptiles)
nc <- st_read(system.file("shape/nc.shp", package="sf"), quiet = TRUE)
nc_osm <- mp_get_tiles(nc, crop = TRUE)
mp_tiles(nc_osm)
plot(st_geometry(nc), col = NA, add = TRUE)
mtext(text = "Tiles: © OpenStreetMap contributors", 
      side = 1, line = -1, adj = 1, cex = .9, font = 3)
```

<img src="man/figures/README-example-1.png" width="852" height="269" />

`maptiles` already gives access to a lot of tiles servers, but it is
possible to add others. In the following example we also cache the
original tiles for future use:

``` r
# Download esri tiles
fullserver = paste("https://server.arcgisonline.com/ArcGIS/rest/services",
                   "Specialty/DeLorme_World_Base_Map/MapServer",
                   "tile/{z}/{y}/{x}.jpg",
                   sep = "/")
typeosm <-  list(
  src = 'esri',
  q = fullserver,
  sub = NA,
  cit = 'Tiles: Esri; Copyright: 2012 DeLorme'
)
nc_ESRI <- mp_get_tiles(x = nc, type = typeosm, crop = TRUE, 
                        cachedir = "tilesfolder", verbose = TRUE)
#> https://server.arcgisonline.com/ArcGIS/rest/services/Specialty/DeLorme_World_Base_Map/MapServer/tile/7/50/34.jpg => tilesfolder/esri/esri_7_34_50.jpg
#> https://server.arcgisonline.com/ArcGIS/rest/services/Specialty/DeLorme_World_Base_Map/MapServer/tile/7/50/35.jpg => tilesfolder/esri/esri_7_35_50.jpg
#> https://server.arcgisonline.com/ArcGIS/rest/services/Specialty/DeLorme_World_Base_Map/MapServer/tile/7/50/36.jpg => tilesfolder/esri/esri_7_36_50.jpg
#> https://server.arcgisonline.com/ArcGIS/rest/services/Specialty/DeLorme_World_Base_Map/MapServer/tile/7/50/37.jpg => tilesfolder/esri/esri_7_37_50.jpg
#> https://server.arcgisonline.com/ArcGIS/rest/services/Specialty/DeLorme_World_Base_Map/MapServer/tile/7/51/34.jpg => tilesfolder/esri/esri_7_34_51.jpg
#> https://server.arcgisonline.com/ArcGIS/rest/services/Specialty/DeLorme_World_Base_Map/MapServer/tile/7/51/35.jpg => tilesfolder/esri/esri_7_35_51.jpg
#> https://server.arcgisonline.com/ArcGIS/rest/services/Specialty/DeLorme_World_Base_Map/MapServer/tile/7/51/36.jpg => tilesfolder/esri/esri_7_36_51.jpg
#> https://server.arcgisonline.com/ArcGIS/rest/services/Specialty/DeLorme_World_Base_Map/MapServer/tile/7/51/37.jpg => tilesfolder/esri/esri_7_37_51.jpg
#> Zoom:7
#> Data and map tiles sources:
#> Tiles: Esri; Copyright: 2012 DeLorme
# Plot the tiles
mp_tiles(nc_ESRI)
txt <- typeosm$cit
mtext(text = txt, side = 1, line = -1, adj = 1, cex = .9, font = 3)
```

<img src="man/figures/README-example2-1.png" width="852" height="269" />

## Background

Most of `maptiles`code comes from `getTiles()` and `tilesLayer()`
functions in [`cartography`](https://github.com/riatelab/cartography).
It uses `terra` instead of `raster` for managing raster data.

## Alternatives

-   [`ceramic`](https://github.com/hypertidy/ceramic)  
-   [`rosm`](https://github.com/paleolimbot/rosm)
-   [`ggspatial`](https://github.com/paleolimbot/ggspatial) (`ggplot2`
    focused, based on `rosm`)
-   [`mapboxapi`](https://github.com/walkerke/mapboxapi)
-   [`OpenStreetMap`](https://github.com/ifellows/ROSM) (require Java)
-   [`ggmap`](https://github.com/dkahle/ggmap) (`ggplot2` focused)
-   …

## Note

Not to be confused with
[`tilemaps`](https://github.com/kaerosen/tilemaps), that “implements an
algorithm for generating maps, known as tile maps, in which each region
is represented by a single tile of the same shape and size.”
