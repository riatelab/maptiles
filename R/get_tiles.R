#' @title Get basemap tiles from map servers
#' @name get_tiles
#' @description Get map tiles based on a spatial object extent. Maps can be
#' fetched from various map servers ('OpenStreetMap', 'Stadia', 'Esri', 'CARTO',
#' or 'Thunderforest').
#' @param x sf, sfc, bbox, SpatRaster, SpatVector or SpatExtent object.
#' If \code{x} is a SpatExtent it
#' must express coordinates in lon/lat WGS84 (epsg:4326).
#' @param provider tile server to get the tiles from. It can be one of
#' the builtin providers (see Details for the list) or a named list produced
#' by \link{create_provider} (see Examples).
#' @param zoom zoom level (see Details).
#' @param crop TRUE if results should be cropped to the specified x extent,
#' FALSE otherwise. If x is an sf object with one POINT, crop is set to FALSE.
#' @param project if TRUE, the output is projected to the crs of x.
#' If FALSE the output uses "EPSG:3857" (Web Mercator).
#' @param verbose if TRUE, tiles filepaths, zoom level and
#' attribution are displayed.
#' @param apikey API key. Not needed for Thunderforest or Stadia servers if
#' environment variables named "THUNDERFOREST_MAPS" or "STADIA_MAPS" are set.
#' @param cachedir name of a folder used to cache tiles. If not set, tiles
#' are cached in a \link[base:tempfile]{tempdir} folder.
#' @param forceDownload if TRUE, existing cached tiles may be overwritten.
#' @param retina if TRUE, tiles are downloaded in high resolution if they exist.
#' Stadia and CARTO provide such tiles.
#' @details
#' Zoom levels are described in the OpenStreetMap wiki:
#' \url{https://wiki.openstreetmap.org/wiki/Zoom_levels}. \cr\cr
#'
#' Here is the complete list of builtin providers: \cr
#'
#' "OpenStreetMap", "OpenStreetMap.DE", "OpenStreetMap.France",
#' "OpenStreetMap.HOT", "OpenTopoMap",
#'
#' "Stadia.AlidadeSmooth", "Stadia.AlidadeSmoothDark",
#' "Stadia.OSMBright", "Stadia.Outdoors",
#' "Stadia.StamenToner", "Stadia.StamenTonerBackground",
#' "Stadia.StamenTonerLines",
#' "Stadia.StamenTonerLabels", "Stadia.StamenTonerLite",
#' "Stadia.StamenWatercolor",
#' "Stadia.StamenTerrain", "Stadia.StamenTerrainBackground",
#' "Stadia.StamenTerrainLabels",
#'
#' "Esri.WorldStreetMap", "Esri.WorldTopoMap", "Esri.WorldImagery",
#' "Esri.WorldTerrain", "Esri.WorldShadedRelief", "Esri.OceanBasemap",
#' "Esri.NatGeoWorldMap", "Esri.WorldGrayCanvas",
#'
#' "CartoDB.Positron", "CartoDB.PositronNoLabels", "CartoDB.PositronOnlyLabels",
#' "CartoDB.DarkMatter",
#' "CartoDB.DarkMatterNoLabels", "CartoDB.DarkMatterOnlyLabels",
#' "CartoDB.Voyager", "CartoDB.VoyagerNoLabels", "CartoDB.VoyagerOnlyLabels",
#'
#' "Thunderforest.OpenCycleMap", "Thunderforest.Transport",
#' "Thunderforest.TransportDark",
#' "Thunderforest.SpinalMap", "Thunderforest.Landscape",
#' "Thunderforest.Outdoors",
#' "Thunderforest.Pioneer", "Thunderforest.MobileAtlas",
#' "Thunderforest.Neighbourhood"
#' @export
#' @return A SpatRaster is returned.
#' @importFrom terra ext project rast as.polygons gdal writeRaster
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
#'
#' # Create a provider from a custom url
#' osm_tiles <- create_provider(
#'   name = "osm_tiles",
#'   url = "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
#'   citation = "© OpenStreetMap contributors."
#' )
#' # Download tiles and compose raster (SpatRaster)
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
                      forceDownload = FALSE,
                      retina = TRUE) {
  # test input valididy
  test_input(x)

  # get input bbox, input crs and bbox in lonlat
  res <- get_bbox_and_proj(x)

  # get query parameters according to provider
  param <- get_param(provider)

  # get zoom level
  zoom <- get_zoom(zoom, res$bbox_lonlat)

  # get cache directory
  cachedir <- get_cachedir(cachedir, param$src)

  # get file name
  filename <- get_filename(
    res$bbox_input, zoom, crop, project, cachedir,
    param$q, retina
  )

  # display info
  display_infos(verbose, zoom, param$cit, cachedir)

  # get cached raster if it already exists
  ras <- get_cached_raster(filename, forceDownload, verbose)
  if (!is.null(ras)) {
    return(ras)
  }

  # get tile list
  tile_grid <- bbox_to_tile_grid(res$bbox_lonlat, zoom)

  # download images
  images <- download_tiles(
    tile_grid, param, apikey, verbose,
    cachedir, forceDownload, retina
  )

  # compose images
  ras <- compose_tiles(tile_grid, images)


  # project if needed
  ras <- project_and_crop_raster(ras, project, res, crop)

  # cache raster
  writeRaster(ras, filename, overwrite = TRUE)

  return(ras)
}
