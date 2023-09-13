#' @title Get basemap tiles from map servers
#' @name get_tiles
#' @description Get map tiles based on a spatial object extent. Maps can be
#' fetched from various map servers.
#' @param x an sf, sfc, bbox, SpatRaster, SpatVector or SpatExtent object.
#' If \code{x} is a SpatExtent it
#' must express coordinates in lon/lat WGS84 (epsg:4326).
#' @param provider the tile server from which to get the map. It can be one of
#' the builtin providers (see Details for the list) or a named list produced
#' by \link{create_provider} (see Examples).
#' @param zoom the zoom level (see Details).
#' @param crop TRUE if results should be cropped to the specified x extent,
#' FALSE otherwise. If x is an sf object with one POINT, crop is set to FALSE.
#' @param project if TRUE, the output is projected to the crs of x.
#' If FALSE the output uses "EPSG:3857" (Web Mercator).
#' @param verbose if TRUE, tiles filepaths, zoom level and
#' attribution are displayed.
#' @param apikey API key, needed for Thunderforest or Stadia servers for
#' example.
#' @param cachedir name of a directory used to cache tiles. If not set, tiles
#' are cached in a \link[base:tempfile]{tempdir} folder.
#' @param forceDownload if TRUE, existing cached tiles may be overwritten.
#' @details
#' Zoom levels are described on the OpenStreetMap wiki:
#' \url{https://wiki.openstreetmap.org/wiki/Zoom_levels}. \cr\cr
#' Providers: \cr
#' "OpenStreetMap", "OpenStreetMap.DE", "OpenStreetMap.France",
#' "OpenStreetMap.HOT", "OpenTopoMap", \cr
#' "Stadia.Stamen.Toner", "Stadia.Stamen.TonerBackground",
#' "Stadia.Stamen.TonerLines", "Stadia.Stamen.TonerLabels",
#' "Stadia.Stamen.TonerLite",
#' "Stadia.Stamen.Watercolor", "Stadia.Stamen.Terrain",
#' "Stadia.Stamen.TerrainBackground",
#' "Stadia.Stamen.TerrainLabels", \cr
#' "Esri.WorldStreetMap", "Esri.DeLorme",
#' "Esri.WorldTopoMap", "Esri.WorldImagery", "Esri.WorldTerrain",
#' "Esri.WorldShadedRelief", "Esri.OceanBasemap", "Esri.NatGeoWorldMap",
#' "Esri.WorldGrayCanvas", "CartoDB.Positron", "CartoDB.PositronNoLabels", \cr
#' "CartoDB.PositronOnlyLabels", "CartoDB.DarkMatter",
#' "CartoDB.DarkMatterNoLabels",
#' "CartoDB.DarkMatterOnlyLabels", "CartoDB.Voyager", "CartoDB.VoyagerNoLabels",
#' "CartoDB.VoyagerOnlyLabels", \cr
#' "Thunderforest.OpenCycleMap", "Thunderforest.Transport",
#' "Thunderforest.TransportDark", "Thunderforest.SpinalMap",
#' "Thunderforest.Landscape",
#' "Thunderforest.Outdoors", "Thunderforest.Pioneer",
#' "Thunderforest.MobileAtlas",
#' "Thunderforest.Neighbourhood"
#' @export
#' @return A SpatRaster is returned.
#' @importFrom terra ext project rast as.polygons 'RGB<-' gdal
#' @importFrom sf st_is st_transform st_geometry<- st_buffer st_geometry
#' st_bbox st_as_sfc st_crs
#' @importFrom tools file_path_sans_ext
#' @examples
#' \dontrun{
#' library(sf)
#' library(maptiles)
#' nc <- st_read(system.file("shape/nc.shp", package = "sf"), quiet = TRUE)
#' nc_osm <- get_tiles(nc, crop = TRUE, zoom = 6)
#' plot_tiles(nc_osm)
#' # Download tiles from a custom url
#' osm_tiles <- create_provider(
#'   name = "osm_tiles",
#'   url = "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
#'   citation = "© OpenStreetMap contributors."
#' )
#' # dowload tiles and compose raster (SpatRaster)
#' nc_osm2 <- get_tiles(
#'   x = nc, provider = osm_tiles, crop = FALSE,
#'   zoom = 6, project = FALSE, verbose = TRUE
#' )
#' # Plot the tiles
#' plot_tiles(nc_osm2)
#' # Add attribution
#' mtext(get_credit(osm_tiles), side = 1, line = -1)
#' }
get_tiles <- function(x,
                      provider = "OpenStreetMap",
                      zoom,
                      crop = FALSE,
                      project = TRUE,
                      verbose = FALSE,
                      apikey,
                      cachedir,
                      forceDownload = FALSE) {
  # gdal_version is obsolete.
  if (gdal() < "2.2.3") {
    warning(
      paste0(
        "Your GDAL version is ", gdal(),
        ". You need GDAL >= 2.2.3 to use maptiles."
      ),
      call. = FALSE
    )
    return(invisible(NULL))
  }

  # test input valididy
  test_input(x)


  # get bbox and origin proj
  res <- get_bbox_and_proj(x)
  bbx <- res$bbx
  cb <- res$cb
  origin_proj <- res$origin_proj


  # select a default zoom level
  if (missing(zoom)) {
    gz <- slippymath::bbox_tile_query(bbx)
    zoom <- min(gz[gz$total_tiles %in% 4:10, "zoom"])
  }

  # get tile list
  tile_grid <- slippymath::bbox_to_tile_grid(bbox = bbx, zoom = zoom)

  # get query parameters according to provider
  param <- get_param(provider)
  # subdomains management
  tile_grid$tiles$s <- sample(param$sub, nrow(tile_grid$tiles), replace = TRUE)
  # src mgmnt
  tile_grid$src <- param$src
  # query mgmnt
  if (missing(apikey)) {
    apikey <- ""
  }
  tile_grid$apikey <- apikey
  tile_grid$q <- sub("XXXXXX", "{apikey}", param$q, perl = TRUE)
  # citation
  tile_grid$cit <- param$cit

  # extension management
  if (length(grep("jpg", param$q)) > 0) {
    ext <- "jpg"
  } else if (length(grep("jpeg", param$q)) > 0) {
    ext <- "jpeg"
  } else if (length(grep("png", param$q)) > 0) {
    ext <- "png"
  }
  tile_grid$ext <- ext

  # download images
  images <- get_tiles_n(tile_grid, verbose, cachedir, forceDownload)
  if (is.null(images)) {
    message(
      "A problem occurred while downloading the tiles.", "\n",
      "Please check the tile provider address."
    )
    return(invisible(NULL))
  }
  # compose images
  rout <- compose_tile_grid(tile_grid, images, forceDownload)

  # set the projection
  webmercator <- "epsg:3857"
  terra::crs(rout) <- webmercator

  # use predefine destination raster
  if (project && st_crs(webmercator)$wkt != origin_proj) {
    temprast <- rast(rout)
    temprast <- project(temprast, origin_proj)
    terra::res(temprast) <- signif(terra::res(temprast), 3)
    rout <- terra::project(rout, temprast)
    rout <- terra::trim(rout)
  } else {
    cb <- st_bbox(st_transform(st_as_sfc(bbx), webmercator))
  }

  rout <- terra::clamp(rout, lower = 0, upper = 255, values = TRUE)

  # crop management
  if (crop) {
    rout <- terra::crop(rout, cb[c(1, 3, 2, 4)], snap = "out")
  }

  # set R, G, B channels, such that plot(rout) will go to plotRGB
  RGB(rout) <- 1:3

  return(rout)
}
