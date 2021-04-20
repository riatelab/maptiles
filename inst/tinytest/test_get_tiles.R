
home <- length(unclass(packageVersion("maptiles"))[[1]]) == 4
if(home){
  suppressPackageStartupMessages(library(sf))
  suppressPackageStartupMessages(library(terra))
  nc <- st_read(system.file("shape/nc.shp", package="sf"), quiet = TRUE)
  nc <- st_transform(nc, 3857)
  nc.sv <- vect(nc)
  nc1 <- nc[1,]
  st_geometry(nc1) <- st_centroid(st_geometry(nc1))
  bb <- st_bbox(c(xmin = -81.74, ymin = 36.23,
                  xmax  = -81.23, ymax = 36.58),
                crs = st_crs(4326))
  se <- ext(-81.74,-81.23,36.23,36.58)

  # test bbox input
  expect_true(methods::is(get_tiles(x = bb), "SpatRaster"))
  # test SpatExtent input
  expect_true(methods::is(get_tiles(x = se), "SpatRaster"))
  # test SpatVector input
  a <- get_tiles(x = nc.sv)
  expect_true(methods::is(a, "SpatRaster"))
  # test SpatRaster input
  expect_true(methods::is(get_tiles(x = a), "SpatRaster"))
  # test verbosity
  suppressMessages(expect_message(get_tiles(x = nc, verbose=TRUE)))
  # test crop
  expect_true(methods::is(get_tiles(x = nc, crop = TRUE), "SpatRaster"))
  # test 1 point
  expect_true(methods::is(get_tiles(x = nc1, crop = TRUE), "SpatRaster"))
  # test zoom and provider
  expect_true(methods::is(get_tiles(x = nc[1:2,],
                                    provider = "Stamen.Watercolor",
                                    zoom = 2), "SpatRaster"))
  # test custom server
  fullserver = paste("https://server.arcgisonline.com/ArcGIS/rest/services",
                     "Specialty/DeLorme_World_Base_Map/MapServer",
                     "tile/{z}/{y}/{x}.jpg", sep = "/")
  esri <-  list(src = 'esri', q = fullserver, sub = NA,
                cit = 'Tiles: Esri; Copyright: 2012 DeLorme')
  expect_true(methods::is(get_tiles(x = nc, provider = esri, crop = TRUE,
                                    verbose = FALSE), "SpatRaster"))
  # test cachedir
  expect_true(methods::is(get_tiles(x = nc, cachedir = tempdir(),
                                    forceDownload = TRUE, zoom = 2),
                          "SpatRaster"))
  # test garbage input
  expect_error(get_tiles(x = "1", zoom = 1))
  # test plot
  x <- get_tiles(x = nc)
  expect_silent(plot_tiles(x, add = FALSE))
  expect_silent(plot_tiles(x, add = TRUE))
  # test credits
  expect_silent(get_credit("OpenStreetMap"))
}
