library(sf)
nc <- st_read(system.file("shape/nc.shp", package="sf"), quiet = TRUE)
nc <- st_transform(nc, 3857)
nc1 <- nc[1,]
st_geometry(nc1) <- st_centroid(st_geometry(nc1))
home <- length(unclass(packageVersion("maptiles"))[[1]]) == 4
if(home){
  suppressMessages(expect_message(mp_get_tiles(x = nc, verbose=TRUE)))
  expect_true(methods::is(mp_get_tiles(x = nc, crop = TRUE), "SpatRaster"))
  expect_true(methods::is(mp_get_tiles(x = nc1, crop = TRUE), "SpatRaster"))
  expect_true(methods::is(mp_get_tiles(x = nc[1:2,], provider = "Stamen.Watercolor",
                                       zoom = 2), "SpatRaster"))

  x <- mp_get_tiles(x = nc)



  fullserver = paste("https://server.arcgisonline.com/ArcGIS/rest/services",
                     "Specialty/DeLorme_World_Base_Map/MapServer",
                     "tile/{z}/{y}/{x}.jpg",
                     sep = "/")
  esri <-  list(
    src = 'esri',
    q = fullserver,
    sub = NA,
    cit = 'Tiles: Esri; Copyright: 2012 DeLorme'
  )
  expect_true(methods::is(mp_get_tiles(x = nc, provider = esri, crop = TRUE,
                                       verbose = FALSE), "SpatRaster"))

  expect_true(methods::is(mp_get_tiles(x = nc, cachedir = tempdir(),
                                       forceDownload = TRUE, zoom = 2),
                          "SpatRaster"))



  st_crs(nc) <- NA
  expect_error(mp_get_tiles(x = x, zoom = 1))
  expect_silent(mp_tiles(x, add = FALSE))
  expect_silent(mp_tiles(x, add = TRUE))
  expect_silent(mp_get_tiles_attribution("OpenStreetMap"))
}

