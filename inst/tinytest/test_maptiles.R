# Extra test for dev version
home <- length(unclass(packageVersion("maptiles"))[[1]]) == 4

# load libs and data
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


# test_input() ----
expect_silent(maptiles:::test_input(nc_sf))
expect_silent(maptiles:::test_input(nc_sfc))
expect_silent(maptiles:::test_input(nc_bbox))
expect_silent(maptiles:::test_input(nc_SpatVector))
expect_silent(maptiles:::test_input(nc_SpatRaster))
expect_silent(maptiles:::test_input(nc_SpatExtent))
expect_silent(maptiles:::test_input(nc_SpatVector_centro))
expect_silent(maptiles:::test_input(nc_sf_centro))
expect_error(maptiles:::test_input("bop"))


# get_bbox_and_proj() ----
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


# get_extension() ----
q <- "https://tile.openstreetmap.org/{z}/{x}/{y}.jpeg"
expect_equal(maptiles:::get_extension(q), "jpeg")
q <- "https://tile.openstreetmap.org/{z}/{x}/{y}.jpg"
expect_equal(maptiles:::get_extension(q), "jpg")
q <- "https://tile.openstreetmap.org/{z}/{x}/{y}.webp"
expect_equal(maptiles:::get_extension(q), "webp")


# get_param() ----
osm <- list(src = "OpenStreetMap",
            q = "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
            sub = NA,
            cit = "© OpenStreetMap contributors",
            ext = "png")
expect_identical(maptiles:::get_param("OpenStreetMap"), osm)
expect_warning(maptiles:::get_param("Stamen.Toner"))
expect_error(maptiles:::get_param("Esri.Delorme"))

# get_zoom() ----
expect_equal(maptiles:::get_zoom(bbox_lonlat = nc_bbox), 7)
expect_equal(maptiles:::get_zoom(zoom = 8, bbox_lonlat = nc_bbox), 8)


# get_cachedir() ----
tmpdir <- file.path(tempdir(), "popo")
expect_equal(maptiles:::get_cachedir(src = "popo"), tmpdir)
expect_equal(maptiles:::get_cachedir(cachedir = tempdir(), src = "pop"),
             file.path(tempdir(), "pop"))
expect_true(dir.exists(file.path(tempdir(), "pop")))


# get_filename() ----
expect_equal(maptiles:::get_filename(bbox = nc_bbox, zoom = 7, crop = TRUE,
                                     project = FALSE,
                                     cachedir = "/dummy/folder",
                                     url = osm$q, retina = TRUE),
             "/dummy/folder/45ec6961a57873957489067baecf0827.tif")


# display_infos() ----
expect_message(maptiles:::display_infos(verbose = TRUE, zoom = 7,
                                        citation = "blalalal",
                                        cachedir = "/dummy/folder"))
expect_null(maptiles:::display_infos(verbose = FALSE, zoom = 7,
                                     citation = "blalalal",
                                     cachedir = "/dummy/folder"))


# get_cached_raster() ----
pth <- file.path(tempdir(), "test.tif")
writeRaster(x = rast(nrows=5, ncols=5, vals=1:25), filename = pth,
            overwrite = TRUE)
expect_null(maptiles:::get_cached_raster(filename = "dummy.file",
                                         forceDownload = FALSE,
                                         verbose = TRUE))
expect_inherits(maptiles:::get_cached_raster(filename = pth,
                                             forceDownload = FALSE,
                                             verbose = FALSE),
                "SpatRaster")
expect_message(maptiles:::get_cached_raster(filename = pth,
                                            forceDownload = FALSE,
                                            verbose = TRUE))


# get_credit() ----
expect_equal(get_credit("OpenStreetMap"), "© OpenStreetMap contributors")
osmouaich <- create_provider(
  name = "osmouaich",
  url = "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
  citation = "ouaich ouaich yo"
)
expect_equal(get_credit(osmouaich), "ouaich ouaich yo")
expect_null(get_credit("Wuwu"))

# get_providers ----
expect_equal(get_providers(), maptiles:::.global_maptiles$providers)

if (home){
  # download_tiles() ----
  input <- nc_sf
  res <- maptiles:::get_bbox_and_proj(input)
  tile_grid <- slippymath::bbox_to_tile_grid(bbox = res$bbox_lonlat, zoom = 6)
  param <- param2 <- maptiles:::get_param("OpenStreetMap")
  param2$q <- "ppp"
  cachedir <- maptiles:::get_cachedir(src = "OSM")
  images <- maptiles:::download_tiles(tile_grid = tile_grid, param = param,
                                      verbose = FALSE, cachedir = cachedir,
                                      forceDownload = TRUE, retina = FALSE)
  expect_inherits(images, "list")
  expect_equal(images[[1]], file.path(cachedir, "OpenStreetMap_6_17_25.png"))
  expect_true(file.exists(file.path(cachedir, "OpenStreetMap_6_17_25.png")))

  expect_message(maptiles:::download_tiles(tile_grid = tile_grid,
                                           param = param,
                                           verbose = TRUE,
                                           cachedir = cachedir,
                                           retina = FALSE,
                                           forceDownload = FALSE))

  expect_error(maptiles:::download_tiles(tile_grid = tile_grid,
                                         param = param2,
                                         verbose = FALSE,
                                         cachedir = cachedir,
                                         retina = FALSE,
                                         forceDownload = TRUE))


  # compose_tiles() ----
  ras <- maptiles:::compose_tiles(tile_grid, images)
  expect_inherits(ras, "SpatRaster")
  expect_equal(dim(ras), c(256,512,3))

  input2 <- nc_sf_centro
  res2 <- maptiles:::get_bbox_and_proj(input2)
  tile_grid2 <- slippymath::bbox_to_tile_grid(bbox = res2$bbox_lonlat, zoom = 4)
  param2 <- maptiles:::get_param("CartoDB.PositronOnlyLabels")
  cachedir2 <- maptiles:::get_cachedir(src = "CartoDBxPos")
  images2 <- maptiles:::download_tiles(tile_grid = tile_grid2, param = param2,
                                      verbose = FALSE, cachedir = cachedir2,
                                      forceDownload = TRUE, retina = TRUE)
  ras2 <- maptiles:::compose_tiles(tile_grid2, images2)
  expect_inherits(ras2, "SpatRaster")
  expect_equal(dim(ras2), c(512, 512, 4))


  # project_and_crop_raster() ----
  ras <- maptiles:::compose_tiles(tile_grid, images)
  unmodified <- maptiles:::project_and_crop_raster(ras = ras, project = FALSE,
                                                   res = res, crop = FALSE)
  crs(ras) <- "epsg:3857"
  expect_equivalent(unmodified, ras)
  ras <- maptiles:::compose_tiles(tile_grid, images)
  pr_and_cr <- maptiles:::project_and_crop_raster(ras = ras, project = TRUE,
                                                   res = res, crop = TRUE)
  expect_equivalent(crs(input), crs(pr_and_cr))
  expect_equivalent(st_bbox(input), st_bbox(pr_and_cr),
                    tolerance = res(pr_and_cr)[1])


  # get_tiles() ----
  input <- nc_sf
  x <- get_tiles(x = input, crop = TRUE)
  expect_inherits(x, "SpatRaster")
  expect_equivalent(st_bbox(input), st_bbox(x), tolerance = 0.001)
  expect_message(get_tiles(x = input, crop = TRUE, verbose = TRUE))

  # create_provider() ----
  osm <- create_provider(
    name = "osm",
    url = "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
    citation = "© OpenStreetMap contributors"
    )
  input <- nc_sf
  x <- get_tiles(x = input, provider = osm, crop = TRUE, zoom = 4)
  expect_inherits(x, "SpatRaster")


  # plot_tiles() ----
  input <- nc_sf
  x <- get_tiles(x = input, zoom = 4, project = F, crop = TRUE)
  expect_error(plot_tiles(NULL))
  expect_error(plot_tiles(input))
  expect_silent(plot_tiles(x, add = FALSE))
  expect_silent(plot_tiles(x, add = TRUE))
  expect_silent(plot_tiles(x, adjust = TRUE))
  x <- get_tiles(x = input, zoom = 4, project = T, crop = TRUE)
  expect_message(plot_tiles(x, adjust = TRUE))
  x <- get_tiles(x = input, zoom = 4, project = FALSE)
  expect_silent(plot_tiles(x, adjust = TRUE))

}


