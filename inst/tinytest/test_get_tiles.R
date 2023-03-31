home <- length(unclass(packageVersion("maptiles"))[[1]]) == 4

library(sf)
library(terra)
nc <- st_read(system.file("shape/nc.shp", package="sf"), quiet = TRUE)
# nc_sf <- st_transform(nc, 2153)
nc_sf <- nc
nc_sfc <- st_geometry(nc_sf)
nc_bbox <- st_bbox(nc_sf)
nc_SpatVector <- vect(nc_sf)
nc_SpatRaster <- rast(nc_SpatVector)
nc_SpatExtent <- ext(project(nc_SpatVector, "epsg:4326"))
nc_sf_centro <- nc_sf[1, ]
st_geometry(nc_sf_centro) <- st_centroid(st_geometry(nc_sf_centro))
nc_SpatVector_centro <- vect(nc_sf_centro)

expect_silent(maptiles:::test_input(nc_sf))
expect_silent(maptiles:::test_input(nc_sfc))
expect_silent(maptiles:::test_input(nc_bbox))
expect_silent(maptiles:::test_input(nc_SpatVector))
expect_silent(maptiles:::test_input(nc_SpatRaster))
expect_silent(maptiles:::test_input(nc_SpatExtent))
expect_silent(maptiles:::test_input(nc_SpatVector_centro))
expect_silent(maptiles:::test_input(nc_sf_centro))
expect_error(maptiles:::test_input("bop"))


input = nc_sf
x <- maptiles:::get_bbox_and_proj(input)
expect_true(st_crs(x[[1]]) == st_crs(input))
expect_true(st_crs(x[[2]]) == st_crs(input))
expect_true(st_crs(x[[3]]) == st_crs("epsg:4326"))
expect_inherits(x[[2]], "bbox")
expect_inherits(x[[3]], "bbox")

input = nc_sfc
x <- maptiles:::get_bbox_and_proj(input)
expect_true(st_crs(x[[1]]) == st_crs(input))
expect_true(st_crs(x[[2]]) == st_crs(input))
expect_true(st_crs(x[[3]]) == st_crs("epsg:4326"))
expect_inherits(x[[2]], "bbox")
expect_inherits(x[[3]], "bbox")

input = nc_bbox
x <- maptiles:::get_bbox_and_proj(input)
expect_true(st_crs(x[[1]]) == st_crs(input))
expect_true(st_crs(x[[2]]) == st_crs(input))
expect_true(st_crs(x[[3]]) == st_crs("epsg:4326"))
expect_inherits(x[[2]], "bbox")
expect_inherits(x[[3]], "bbox")

input = nc_SpatVector
x <- maptiles:::get_bbox_and_proj(input)
expect_true(st_crs(x[[1]]) == st_crs(input))
expect_true(st_crs(x[[2]]) == st_crs(input))
expect_true(st_crs(x[[3]]) == st_crs("epsg:4326"))
expect_inherits(x[[2]], "bbox")
expect_inherits(x[[3]], "bbox")

input = nc_SpatRaster
x <- maptiles:::get_bbox_and_proj(input)
expect_true(st_crs(x[[1]]) == st_crs(input))
expect_true(st_crs(x[[2]]) == st_crs(input))
expect_true(st_crs(x[[3]]) == st_crs("epsg:4326"))
expect_inherits(x[[2]], "bbox")
expect_inherits(x[[3]], "bbox")

input = nc_SpatExtent
x <- maptiles:::get_bbox_and_proj(input)
expect_true(st_crs(x[[1]]) == st_crs("epsg:4326"))
expect_true(st_crs(x[[2]]) == st_crs("epsg:4326"))
expect_true(st_crs(x[[3]]) == st_crs("epsg:4326"))
expect_inherits(x[[2]], "bbox")
expect_inherits(x[[3]], "bbox")

input = nc_sf_centro
x <- maptiles:::get_bbox_and_proj(input)
expect_true(st_crs(x[[1]]) == st_crs(input))
expect_true(st_crs(x[[2]]) == st_crs(input))
expect_true(st_crs(x[[3]]) == st_crs("epsg:4326"))
expect_inherits(x[[2]], "bbox")
expect_inherits(x[[3]], "bbox")

input = nc_SpatVector_centro
x <- maptiles:::get_bbox_and_proj(input)
expect_true(st_crs(x[[1]]) == st_crs(input))
expect_true(st_crs(x[[2]]) == st_crs(input))
expect_true(st_crs(x[[3]]) == st_crs("epsg:4326"))
expect_inherits(x[[2]], "bbox")
expect_inherits(x[[3]], "bbox")

#
# if(home){
#   # test sf input
#   expect_true(inherits(get_tiles(x = bb), "SpatRaster"))
#   # test SpatExtent input
#   expect_true(inherits(get_tiles(x = se), "SpatRaster"))
#   # test SpatVector input
#   a <- get_tiles(x = nc.sv)
#   expect_true(inherits(a, "SpatRaster"))
#   # test SpatRaster input
#   expect_true(inherits(get_tiles(x = a), "SpatRaster"))
#   # test verbosity
#   suppressMessages(expect_message(get_tiles(x = nc, verbose=TRUE)))
#   # test crop
#   expect_true(inherits(get_tiles(x = nc, crop = TRUE), "SpatRaster"))
#   # test 1 point
#   expect_true(inherits(get_tiles(x = nc1, crop = TRUE), "SpatRaster"))
#   # test zoom and provider
#   expect_true(inherits(get_tiles(x = nc[1:2,],
#                                     provider = "Stamen.Watercolor",
#                                     zoom = 2), "SpatRaster"))
#   # test custom server
#   fullserver = paste("https://server.arcgisonline.com/ArcGIS/rest/services",
#                      "Specialty/DeLorme_World_Base_Map/MapServer",
#                      "tile/{z}/{y}/{x}.jpg", sep = "/")
#   esri <-  list(src = 'esri', q = fullserver, sub = NA,
#                 cit = 'Tiles: Esri; Copyright: 2012 DeLorme')
#   expect_true(inherits(get_tiles(x = nc, provider = esri, crop = TRUE,
#                                     verbose = FALSE), "SpatRaster"))
#   # test cachedir
#   expect_true(inherits(get_tiles(x = nc, cachedir = tempdir(),
#                                     forceDownload = TRUE, zoom = 2),
#                           "SpatRaster"))
#   # test garbage input
#   expect_error(get_tiles(x = "1", zoom = 1))
#   # test plot
#   x <- get_tiles(x = nc)
#   expect_silent(plot_tiles(x, add = FALSE))
#   expect_silent(plot_tiles(x, add = TRUE))
#   expect_silent(plot_tiles(x, adjust = TRUE))
#   # test credits
#   expect_silent(get_credit("OpenStreetMap"))
# }
#
#
#
#
# # library(sf)
# # library(terra)
# # nc <- st_read(system.file("shape/nc.shp", package="sf"), quiet = TRUE)
# # nc_sf <- st_transform(nc, 3857)
# # nc_sfc <- st_geometry(nc_sf)
# # nc_bbox <- st_bbox(nc_sf)
# # nc_SpatVector <- vect(nc_sf)
# # nc_SpatRaster <- rast(nc_SpatVector)
# # nc_SpatExtent <- ext(project(nc_SpatVector, "epsg:4326"))
# # nc_sf_centro <- nc_sf[1, ]
# # st_geometry(nc_sf_centro) <- st_centroid(st_geometry(nc_sf_centro))
# # nc_SpatVector_centro <- vect(nc_sf_centro)
# #
# # expect_silent(test_input(nc_sf))
# # expect_silent(test_input(nc_sfc))
# # expect_silent(test_input(nc_bbox))
# # expect_silent(test_input(nc_SpatVector))
# # expect_silent(test_input(nc_SpatRaster))
# # expect_silent(test_input(nc_SpatExtent))
# # expect_silent(test_input(nc_SpatVector_centro))
# # expect_silent(test_input(nc_sf_centro))
# # expect_error(test_input("bop"))
# #
