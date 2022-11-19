#' @title Get basemap tiles from map servers
#' @name get_tiles
#' @description Get map tiles based on a spatial object extent. Maps can be
#' fetched from various map servers.
#' @param x an sf, sfc, bbox, SpatRaster, SpatVerctor or SpatExtent object.
#' If \code{x} is a SpatExtent it
#' must express coordinates in lon/lat WGS84 (epsg:4326).
#' @param provider the tile server from which to get the map. It can be a name
#' (see Details for providers) or a named list like this one: \code{
#' provider = list(src = "name of the source",
#' q = "server address", sub = "subdomains", cit = "how to cite the tiles")}
#' (see Examples).
#' @param zoom the zoom level (see Details).
#' @param crop TRUE if results should be cropped to the specified x extent,
#' FALSE otherwise. If x is an sf object with one POINT, crop is set to FALSE.
#' @param verbose if TRUE, tiles filepaths, zoom level and citation are displayed.
#' @param apikey API key, needed for Thunderforest servers
#' @param cachedir name of a directory used to cache tiles. If not set, tiles
#' are cached in a \link[base:tempfile]{tempdir} folder.
#' @param forceDownload if TRUE, existing cached tiles may be overwritten
#' @details
#' Zoom levels are described on the OpenStreetMap wiki:
#' \url{https://wiki.openstreetmap.org/wiki/Zoom_levels}. \cr\cr
#' Providers: \cr
#' "OpenStreetMap.MapnikBW", "OpenStreetMap", "OpenStreetMap.DE",
#' "OpenStreetMap.France", "OpenStreetMap.HOT", \cr
#' "Stamen.Toner",
#' "Stamen.TonerBackground", "Stamen.TonerHybrid", "Stamen.TonerLines",
#' "Stamen.TonerLabels", "Stamen.TonerLite", "Stamen.Watercolor",
#' "Stamen.Terrain", "Stamen.TerrainBackground", "Stamen.TerrainLabels",\cr
#' "Esri.WorldStreetMap", "Esri.DeLorme", "Esri.WorldTopoMap", "Esri.WorldImagery",
#' "Esri.WorldTerrain", "Esri.WorldShadedRelief", "Esri.OceanBasemap",
#' "Esri.NatGeoWorldMap", "Esri.WorldGrayCanvas",\cr
#' "CartoDB.Positron",
#' "CartoDB.PositronNoLabels", "CartoDB.PositronOnlyLabels", "CartoDB.DarkMatter",
#' "CartoDB.DarkMatterNoLabels", "CartoDB.DarkMatterOnlyLabels",
#' "CartoDB.Voyager", "CartoDB.VoyagerNoLabels", "CartoDB.VoyagerOnlyLabels",\cr
#'  "Thunderforest.OpenCycleMap", "Thunderforest.Transport",
#' "Thunderforest.TransportDark", "Thunderforest.SpinalMap", "Thunderforest.Landscape",
#' "Thunderforest.Outdoors", "Thunderforest.Pioneer", "Thunderforest.MobileAtlas",
#' "Thunderforest.Neighbourhood",\cr
#' "OpenTopoMap",\cr
#' "HikeBike", \cr
#' "Wikimedia",\cr
#' @export
#' @return A SpatRaster is returned.
#' @importFrom terra ext project rast as.polygons 'RGB<-' gdal
#' @importFrom sf st_is st_transform st_geometry<- st_buffer st_geometry
#' st_bbox st_as_sfc st_crs
#' @importFrom tools file_path_sans_ext
#' @examples
#' library(sf)
#' library(maptiles)
#' nc <- st_read(system.file("shape/nc.shp", package="sf"), quiet = TRUE)
#' nc_osm <- get_tiles(nc, crop = TRUE, zoom = 6)
#' plot_tiles(nc_osm)
#'
#' # Download tiles from OSM, no labels
#' osm <- list(
#'   src = 'OSM',
#'   q = '"http://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"',
#'   sub = c('a','b', 'c'),
#'   cit = '© OpenStreetMap contributors.'
#' )
#' # dowload tiles and compose raster (SpatRaster)
#' nc_osm2 <- get_tiles(x = nc, provider = osm, crop = TRUE,
#'                      zoom = 6, verbose = TRUE)
#' # Plot the tiles
#' plot_tiles(nc_osm2)
get_tiles <- function(x,
                      provider = "OpenStreetMap",
                      zoom,
                      crop = FALSE,
                      verbose = FALSE,
                      apikey,
                      cachedir,
                      forceDownload = FALSE) {
  # gdal_version is obsolete.
  if (gdal() < "2.2.3"){
    warning(paste0("Your GDAL version is ",gdal(),
                   ". You need GDAL >= 2.2.3 to use maptiles."),
            call. = FALSE)
    return(invisible(NULL))
  }

  if(inherits(x, 'bbox')){
    x <- st_as_sfc(x)
  }

  if(inherits(x, 'SpatRaster')){
    x <- terra::as.polygons(x, extent = TRUE)
    x <- terra::project(x, "epsg:4326")
    x <- terra::ext(x)
  } else if(inherits(x, 'SpatVector')){
    x <- terra::project(x, "epsg:4326")
    x <- terra::ext(x)
  }

  if(inherits(x, c('sf', 'sfc'))){
    origin_proj <- st_crs(x)$wkt
    # test for single point (apply buffer to obtain a correct bbox)
    if (nrow(x) == 1 && inherits(st_geometry(x), "sfc_POINT")) {
      xt <- st_transform(x, 3857)
      st_geometry(xt) <- st_buffer(st_geometry(xt), 1000)
      crop <- FALSE
      # use x bbox to select the tiles to get
      bbx <- st_bbox(st_transform(st_as_sfc(st_bbox(xt)), 4326))
    } else {
      # use x bbox to select the tiles to get
      bbx <- st_bbox(st_transform(st_as_sfc(st_bbox(x)), 4326))
      cb <- st_bbox(x)
    }
  } else if(inherits(x, "SpatExtent")){
    origin_proj <- st_crs("epsg:4326")$wkt
    bbx <- as.vector(x)[c(1,3,2,4)]
    cb <- bbx
  } else {
    stop(paste0("x should be an sf, sfc, bbox, SpatRaster,",
                " SpatVector or SpatExtent object"),
         call. = FALSE)
  }

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
  tile_grid$tiles$s <- sample(param$sub, nrow(tile_grid$tiles), replace = T)
  # src mgmnt
  tile_grid$src <- param$src
  # query mgmnt
  if(missing(apikey)){
    apikey <- ""
  }
  tile_grid$q <- sub("XXXXXX", apikey, param$q)
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
  if(is.null(images)){
    message("A problem occurred while downloading the tiles.","\n",
            "Please check the tile provider address.")
    return(invisible(NULL))
  }
  # compose images
  rout <- compose_tile_grid(tile_grid, images)

  # set the projection
  terra::crs(rout) <- "epsg:3857"

  # use predefine destination raster
  if(st_crs("epsg:3857")$wkt!=origin_proj){
    temprast <- rast(rout)
    temprast <- project(temprast, origin_proj)
    terra::res(temprast) <- signif(terra::res(temprast), 3)
    rout <- terra::project(rout, temprast)
    rout <- terra::trim(rout)
  }

  rout <- terra::clamp(rout, lower = 0, upper = 255, values = TRUE)

  # crop management
  if (crop == TRUE) {
    k <- min(c(0.052 * (cb[4] - cb[2]), 0.052 * (cb[3] - cb[1])))
    cb <- cb + c(-k, -k, k, k)
    rout <- terra::crop(rout, cb[c(1, 3, 2, 4)])
  }

  # set R, G, B channels, such that plot(rout) will go to plotRGB
  RGB(rout)<- 1:3

  rout
}


# get the tiles according to the grid
get_tiles_n <- function(tile_grid, verbose, cachedir, forceDownload) {
  # go through tile_grid tiles and download
  images <- apply(
    X = tile_grid$tiles,
    MARGIN = 1,
    FUN = dl_t,
    z = tile_grid$zoom,
    ext = tile_grid$ext,
    src = tile_grid$src,
    q = tile_grid$q,
    verbose = verbose,
    cachedir = cachedir,
    forceDownload = forceDownload
  )

  if (verbose) {
    message(
      "Zoom:", tile_grid$zoom, "\nData and map tiles sources:\n",
      tile_grid$cit
    )
  }
  images
}

# download tile according to parameters
dl_t <- function(x, z, ext, src, q, verbose, cachedir, forceDownload) {
  # forceDownload will overwrite any files existing in cache
  # if (!is.logical(forceDownload)) stop("forceDownload must be TRUE or FALSE")
  # if cachedir is missing, save to temporary filepath
  if (missing(cachedir)) {
    cachedir <- tempdir()
  } else {
    # if cachedir==T, place in working directory
    # if (cachedir == TRUE) cachedir <- paste0(getwd(), "/tile.cache")
    # create the cachedir if it doesn't exist.
    if (!dir.exists(cachedir)) dir.create(cachedir)
    # uses subdirectories based on src to make the directory easier for users to navigate
    subdir <- paste0(cachedir, "/", src)
    if (!dir.exists(subdir)) dir.create(subdir)
    cachedir <- subdir
  }

  # apply coerces to the same length character, need to ensure no whitespace in numbers
  x <- trimws(x)

  outfile <- paste0(cachedir, "/", src, "_", z, "_", x[1], "_", x[2], ".", ext)
  if (!file.exists(outfile) | isTRUE(forceDownload)) {
    q <- gsub(pattern = "{s}", replacement = x[3], x = q, fixed = TRUE)
    q <- gsub(pattern = "{x}", replacement = x[1], x = q, fixed = TRUE)
    q <- gsub(pattern = "{y}", replacement = x[2], x = q, fixed = TRUE)
    q <- gsub(pattern = "{z}", replacement = z, x = q, fixed = TRUE)

    e <- try({curl::curl_download(url = q, destfile = outfile)}, silent = TRUE)
    if (inherits(e,"try-error")){
      outfile <- NULL
    }

    if (verbose) {
      message(q, " => ", outfile)
    }
  }
  outfile
}

# compose tiles
compose_tile_grid <- function(tile_grid, images) {
  bricks <- vector("list", nrow(tile_grid$tiles))
  for (i in seq_along(bricks)) {
    bbox <- slippymath::tile_bbox(
      tile_grid$tiles$x[i], tile_grid$tiles$y[i],
      tile_grid$zoom
    )
    img <- images[i]
    # special for png tiles
    if (tile_grid$ext == "png") {
      img <- png::readPNG(img) * 255

      # Give transparency if available
      if (dim(img)[3] == 4) {
        nrow <- dim(img)[1]
        for (j in seq_len(nrow)) {
          row <- img[j, , ]
          alpha <- row[, 4] == 0
          row[alpha, ] <- NA
          img[j, , ] <- row
        }
      }
    }

    # compose brick raster
    r_img <- suppressWarnings(terra::rast(img))

    if (is.null(terra::RGB(r_img))) {
      terra::RGB(r_img) <- c(1,2,3)
    }

    terra::ext(r_img) <- terra::ext(bbox[c(
      "xmin", "xmax",
      "ymin", "ymax"
    )])
    bricks[[i]] <- r_img
  }
  # if only one tile is needed
  if (length(bricks) == 1) {
    rout <- bricks[[1]]
    rout <- terra::merge(rout, rout)
  }else{
    # all tiles together

    # function to use gdal warp approach
    warp_method <- function(){
      # wrapped with try catch - if gdal warp fails defaults to terr::merge
      out_ras <- tryCatch({
        save_ras <- function(ras, .img){
          name <- paste(file_path_sans_ext(.img),
                        '.tif', sep = "")
          if (!file.exists(name)){
            terra::writeRaster(ras, name)
          }
          return(name)
        }

        ras_files <- mapply(save_ras, bricks, images)

        merge_path <- tempfile(fileext = '.tif')
        sf::gdal_utils(util = "warp", options = c("-srcnodata", "None"),
                       source = as.character(ras_files),
                       destination = merge_path)

        outras <- terra::rast(merge_path)
        return(outras)
      },
      error = function(e) {
        warning(
          "\nReceived error from gdalwarp.",
          "Attempting merge using terra::merge")
        outras <- do.call(terra::merge, bricks)
        return(outras)
      }
      )
    }
    rout <- warp_method()
  }
  rout
}

# providers parameters
get_param <- function(provider) {
  if (length(provider) == 4) {
    param <- provider
  } else {
    param <- maptiles_providers[[provider]]
  }
  param
}
