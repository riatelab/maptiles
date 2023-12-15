home <- length(unclass(packageVersion("maptiles"))[[1]]) == 4

suppressPackageStartupMessages(library(sf))
suppressPackageStartupMessages(library(terra))
nc <- st_read(system.file("shape/nc.shp", package = "sf"), quiet = TRUE)
nc_sf <- nc
nc_sfc <- st_geometry(nc_sf)
nc_bbox <- st_bbox(nc_sf)
nc_SpatVector <- vect(nc_sf)
nc_SpatRaster <- rast(nc_SpatVector)
nc_SpatExtent <- ext(project(nc_SpatVector, "epsg:4326"))
nc_sf_centro <- nc_sf[1, ]
st_geometry(nc_sf_centro) <- st_centroid(st_geometry(nc_sf_centro))
nc_SpatVector_centro <- vect(nc_sf_centro)


# test allowed and forbidden input
expect_silent(maptiles:::test_input(nc_sf))
expect_silent(maptiles:::test_input(nc_sfc))
expect_silent(maptiles:::test_input(nc_bbox))
expect_silent(maptiles:::test_input(nc_SpatVector))
expect_silent(maptiles:::test_input(nc_SpatRaster))
expect_silent(maptiles:::test_input(nc_SpatExtent))
expect_silent(maptiles:::test_input(nc_SpatVector_centro))
expect_silent(maptiles:::test_input(nc_sf_centro))
expect_error(maptiles:::test_input("bop"))

# test proj mgmgt
input <- nc_sf
x <- maptiles:::get_bbox_and_proj(input)
expect_true(st_crs(x[[1]]) == st_crs(input))
expect_true(st_crs(x[[2]]) == st_crs(input))
expect_true(st_crs(x[[3]]) == st_crs("epsg:4326"))
expect_inherits(x[[2]], "bbox")
expect_inherits(x[[3]], "bbox")

input <- nc_sfc
x <- maptiles:::get_bbox_and_proj(input)
expect_true(st_crs(x[[1]]) == st_crs(input))
expect_true(st_crs(x[[2]]) == st_crs(input))
expect_true(st_crs(x[[3]]) == st_crs("epsg:4326"))
expect_inherits(x[[2]], "bbox")
expect_inherits(x[[3]], "bbox")

input <- nc_bbox
x <- maptiles:::get_bbox_and_proj(input)
expect_true(st_crs(x[[1]]) == st_crs(input))
expect_true(st_crs(x[[2]]) == st_crs(input))
expect_true(st_crs(x[[3]]) == st_crs("epsg:4326"))
expect_inherits(x[[2]], "bbox")
expect_inherits(x[[3]], "bbox")

input <- nc_SpatVector
x <- maptiles:::get_bbox_and_proj(input)
expect_true(st_crs(x[[1]]) == st_crs(input))
expect_true(st_crs(x[[2]]) == st_crs(input))
expect_true(st_crs(x[[3]]) == st_crs("epsg:4326"))
expect_inherits(x[[2]], "bbox")
expect_inherits(x[[3]], "bbox")

input <- nc_SpatRaster
x <- maptiles:::get_bbox_and_proj(input)
expect_true(st_crs(x[[1]]) == st_crs(input))
expect_true(st_crs(x[[2]]) == st_crs(input))
expect_true(st_crs(x[[3]]) == st_crs("epsg:4326"))
expect_inherits(x[[2]], "bbox")
expect_inherits(x[[3]], "bbox")

input <- nc_SpatExtent
x <- maptiles:::get_bbox_and_proj(input)
expect_true(st_crs(x[[1]]) == st_crs("epsg:4326"))
expect_true(st_crs(x[[2]]) == st_crs("epsg:4326"))
expect_true(st_crs(x[[3]]) == st_crs("epsg:4326"))
expect_inherits(x[[2]], "bbox")
expect_inherits(x[[3]], "bbox")

input <- nc_sf_centro
x <- maptiles:::get_bbox_and_proj(input)
expect_true(st_crs(x[[1]]) == st_crs(input))
expect_true(st_crs(x[[2]]) == st_crs(input))
expect_true(st_crs(x[[3]]) == st_crs("epsg:4326"))
expect_inherits(x[[2]], "bbox")
expect_inherits(x[[3]], "bbox")

input <- nc_SpatVector_centro
x <- maptiles:::get_bbox_and_proj(input)
expect_true(st_crs(x[[1]]) == st_crs(input))
expect_true(st_crs(x[[2]]) == st_crs(input))
expect_true(st_crs(x[[3]]) == st_crs("epsg:4326"))
expect_inherits(x[[2]], "bbox")
expect_inherits(x[[3]], "bbox")



if (home) {
  # test full fun
  input <- nc_sf
  x <- get_tiles(input)
  expect_true(st_crs(x) == st_crs(input))
  expect_inherits(x, "SpatRaster")
  input <- nc_sfc
  x <- get_tiles(input)
  expect_true(st_crs(x) == st_crs(input))
  expect_inherits(x, "SpatRaster")
  input <- nc_bbox
  x <- get_tiles(input)
  expect_true(st_crs(x) == st_crs(input))
  expect_inherits(x, "SpatRaster")
  input <- nc_SpatVector
  x <- get_tiles(input)
  expect_true(st_crs(x) == st_crs(input))
  expect_inherits(x, "SpatRaster")
  input <- nc_SpatRaster
  x <- get_tiles(input)
  expect_true(st_crs(x) == st_crs(input))
  expect_inherits(x, "SpatRaster")
  input <- nc_SpatExtent
  x <- get_tiles(input)
  expect_true(crs(x) == crs("epsg:4326"))
  expect_inherits(x, "SpatRaster")
  input <- nc_sf_centro
  x <- get_tiles(input)
  expect_true(st_crs(x) == st_crs(input))
  expect_inherits(x, "SpatRaster")
  input <- nc_SpatVector_centro
  x <- get_tiles(input)
  expect_true(st_crs(x) == st_crs(input))
  expect_inherits(x, "SpatRaster")

  # test project
  input <- nc_sf
  x <- get_tiles(x = input, project = FALSE)
  expect_equal(crs(x), crs("epsg:3857"))

  # test verbosity
  input <- nc_sf
  suppressMessages(expect_message(get_tiles(x = input, verbose = TRUE)))

  # test crop
  input <- nc_sf
  x <- get_tiles(x = input, crop = TRUE)
  expect_inherits(x, "SpatRaster")
  expect_equivalent(st_bbox(input), st_bbox(x), tolerance = 0.001)

  # test zoom and provider
  input <- nc_sf
  x <- get_tiles(x = input,
                 provider = "Esri.WorldStreetMap",
                 zoom = 2)
  expect_inherits(x, "SpatRaster")

  # test custom server
  opentopomap <- create_provider(
    name = "otm",
    url = "https://{s}.tile.opentopomap.org/{z}/{x}/{y}.png",
    sub = c("a", "b", "c"),
    citation = "map data: © OpenStreetMap contributors, SRTM | map style: © OpenTopoMap (CC-BY-SA)"
  )
  input <- nc_sf
  x <- get_tiles(x = input, provider = opentopomap, crop = TRUE)
  expect_inherits(x, "SpatRaster")


  # test error custom server
  opentopomapx <- create_provider(
    name = "otm",
    url = "https://{s}.tile.opentopyyyyyyyyyomap.org/{z}/{x}/{y}.png",
    sub = c("a", "b", "c"),
    citation = "map data: © OpenStreetMap contributors, SRTM | map style: © OpenTopoMap (CC-BY-SA)"
  )
  input <- nc_sf
  expect_message(get_tiles(x = input, provider = opentopomapx, crop = TRUE,
                           forceDownload = TRUE))


  # test cachedir
  input <- nc_sf
  cache_d <- tempdir()
  x <- get_tiles(x = input, cachedir = tempdir(),
                 forceDownload = FALSE, zoom = 2)
  expect_true(file.exists(cache_d))
  expect_inherits(x, "SpatRaster")

  # test forceDownload
  input <- nc_sf
  x <- get_tiles(x = input, cachedir = tempdir(),
                 forceDownload = TRUE, zoom = 2)
  expect_inherits(x, "SpatRaster")



  # test plot
  input <- nc_sf
  x <- get_tiles(x = input, crop = TRUE)
  expect_message(plot_tiles(NULL))
  expect_warning(plot_tiles(input))
  expect_silent(plot_tiles(x, add = FALSE))
  expect_silent(plot_tiles(x, add = TRUE))
  expect_silent(plot_tiles(x, adjust = TRUE))


  # test credits
  expect_equal(get_credit("OpenStreetMap"), "© OpenStreetMap contributors")
}
