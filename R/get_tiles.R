#' @title Get basemap tiles from map servers
#' @name mp_get_tiles
#' @description Get map tiles based on a spatial object extent. Maps can be
#' fetched from various open map servers.
#' @param x an sf or sfc object.
#' @param type the tile server from which to get the map. See Details for providers.
#' For other sources use a list: type = list(src = "name of the source" ,
#' q = "tiles address", sub = "subdomains", cit = "how to cite the tiles"). See Examples.
#' @param zoom the zoom level.
#' @param crop TRUE if results should be cropped to the specified x extent,
#' FALSE otherwise. If x is an sf object with one POINT, crop is set to FALSE.
#' @param verbose if TRUE, tiles filepaths, zoom level and citation are displayed.
#' @param apikey Needed for Thunderforest maps.
#' @param cachedir name of a directory used to cache tiles. If TRUE, places a
#' 'tile.cache' folder in the working directory. If FALSE, tiles are only
#' cached in \link[base:tempdir]{tempdir}.
#' @param forceDownload if TRUE, cached tiles are downloaded again.
#' @details
#' Zoom levels are described on the OpenStreetMap wiki:
#' \url{http://wiki.openstreetmap.org/wiki/Zoom_levels}. \cr\cr
#' @export
#' @return A SpatRaster is returned.
#' @importFrom terra ext project rast
#' @importFrom sf st_is st_transform st_geometry<- st_buffer st_geometry
#' st_bbox st_as_sfc st_crs
#' @examples
#' \dontrun{
#' library(sf)
#' }
mp_get_tiles <- function(x,
                         type = "OpenStreetMap",
                         zoom = NULL,
                         crop = FALSE,
                         verbose = FALSE,
                         apikey = NA,
                         cachedir = FALSE,
                         forceDownload = FALSE) {
  # test for single point (apply buffer to obtain a correct bbox)
  if (nrow(x) == 1 && st_is(x, "POINT")) {
    xt <- st_transform(x, 3857)
    st_geometry(xt) <- st_buffer(st_geometry(xt), 1000)
    crop <- FALSE
    # use x bbox to select the tiles to get
    bbx <- st_bbox(st_transform(st_as_sfc(st_bbox(xt)), 4326))
  } else {
    # use x bbox to select the tiles to get
    bbx <- st_bbox(st_transform(st_as_sfc(st_bbox(x)), 4326))
  }
  # select a default zoom level
  if (is.null(zoom)) {
    gz <- slippymath::bbox_tile_query(bbx)
    zoom <- min(gz[gz$total_tiles %in% 4:10, "zoom"])
  }

  # get tile list
  tile_grid <- slippymath::bbox_to_tile_grid(bbox = bbx, zoom = zoom)

  # get query parameters according to type
  param <- get_param(type)
  # subdomains management
  tile_grid$tiles$s <- sample(param$sub, nrow(tile_grid$tiles), replace = T)
  # src mgmnt
  tile_grid$src <- param$src
  # query mgmnt
  tile_grid$q <- sub("XXXXXX", apikey, param$q)
  # citation
  tile_grid$cit <- param$cit

  # extension management
  if (length(grep("jpg", param$q)) > 0) {
    ext <- "jpg"
  } else if (length(grep("png", param$q)) > 0) {
    ext <- "png"
  }
  tile_grid$ext <- ext
  # tile_grid$ext <- substr(param$q, nchar(param$q)-2, nchar(param$q))

  # download images
  images <- get_tiles(tile_grid, verbose, cachedir, forceDownload)
  # compose images
  rout <- compose_tile_grid(tile_grid, images)

  terra::crs(rout) <- "epsg:3857"
  # a <- terra::crs(mtq)
  # ?crs

  # # # reproject rout
  rout <- terra::project(x = rout, y = st_crs(x)$wkt)
  rout <- terra::clamp(rout, lower = 0, upper = 255, values = TRUE)
  # #
  # # crop management
  if (crop == TRUE) {
    cb <- st_bbox(x)
    k <- min(c(0.052 * (cb[4] - cb[2]), 0.052 * (cb[3] - cb[1])))
    cb <- cb + c(-k, -k, k, k)
    rout <- terra::crop(rout, cb[c(1, 3, 2, 4)])
  }
  #
  rout
}


# get the tiles according to the grid
get_tiles <- function(tile_grid, verbose, cachedir, forceDownload) {
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
  if (!is.logical(forceDownload)) stop("forceDownload must be TRUE or FALSE")
  # if cachedir==F, save to temporary filepath
  if (cachedir == FALSE) {
    cachedir <- tempdir()
  } else {
    # if cachedir==T, place in working directory
    if (cachedir == TRUE) cachedir <- paste0(getwd(), "/tile.cache")
    # create the cachedir if it doesn't exist.
    if (!dir.exists(cachedir)) dir.create(cachedir)
    # uses subdirectories based on src to make the directory easier for users to navigate
    subdir <- paste0(cachedir, "/", src)
    if (!dir.exists(subdir)) dir.create(subdir)
    cachedir <- subdir
  }

  outfile <- paste0(cachedir, "/", src, "_", z, "_", x[1], "_", x[2], ".", ext)
  if (!file.exists(outfile) | isTRUE(forceDownload)) {
    q <- gsub(pattern = "{s}", replacement = x[3], x = q, fixed = TRUE)
    q <- gsub(pattern = "{x}", replacement = x[1], x = q, fixed = TRUE)
    q <- gsub(pattern = "{y}", replacement = x[2], x = q, fixed = TRUE)
    q <- gsub(pattern = "{z}", replacement = z, x = q, fixed = TRUE)
    if (verbose) {
      message(q, " => ", outfile)
    }
    curl::curl_download(url = q, destfile = outfile)
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
    }

    # compose brick raster
    r_img <- terra::rast(img)
    terra::ext(r_img) <- terra::ext(bbox[c(
      "xmin", "xmax",
      "ymin", "ymax"
    )])
    bricks[[i]] <- r_img
  }
  # if only one tile is needed
  if (length(bricks) == 1) {
    return(bricks[[1]])
  }
  # all tiles together
  rout <- do.call(terra::merge, bricks)
  rout
}

# providers parameters
get_param <- function(type) {
  if (length(type) == 4) {
    param <- type
  } else {
    param <- switch(
      type,
      OpenStreetMap.MapnikBW = list(
        src = "osmgrayscale",
        q = "https://tiles.wmflabs.org/bw-mapnik/{z}/{x}/{y}.png",
        sub = NA,
        cit = "\u00A9 OpenStreetMap contributors. Tiles style under CC BY-SA, www.openstreetmap.org/copyright."
      ),
      OpenStreetMap = list(
        src = "OpenStreetMap",
        q = "http://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
        sub = c("a", "b", "c"),
        cit = "\u00A9 OpenStreetMap contributors"
      ),
      OpenStreetMap.DE = list(
        src = "OpenStreetMap.DE",
        q = "https://{s}.tile.openstreetmap.de/tiles/osmde/{z}/{x}/{y}.png",
        sub = c("a", "b", "c"),
        cit = "\u00A9 OpenStreetMap contributors"
      ),
      OpenStreetMap.France = list(
        src = "OpenStreetMap.France",
        q = "https://{s}.tile.openstreetmap.fr/osmfr/{z}/{x}/{y}.png",
        sub = c("a", "b", "c"),
        cit = "\u00A9 Openstreetmap France | \u00A9 OpenStreetMap contributors"
      ),
      OpenStreetMap.HOT = list(
        src = "OpenStreetMap.HOT",
        q = "https://{s}.tile.openstreetmap.fr/hot/{z}/{x}/{y}.png",
        sub = c("a", "b", "c"),
        cit = "\u00A9 OpenStreetMap contributors, Tiles style by OpenStreetMap France"
      ),
      OpenTopoMap = list(
        src = "OpenTopoMap",
        q = "https://{s}.tile.opentopomap.org/{z}/{x}/{y}.png",
        sub = c("a", "b", "c"),
        cit = "Map data: \u00A9 OpenStreetMap contributors, OpenTopoMap (CC-BY-SA)"
      ),
      Stamen.Toner = list(
        src = "Stamen.Toner",
        q = "https://stamen-tiles-{s}.a.ssl.fastly.net/toner/{z}/{x}/{y}.png",
        sub = c("a", "b", "c", "d"),
        cit = "Map tiles by CC BY 3.0 \u2014 Map data \u00A9 OpenStreetMap contributors"
      ),
      Stamen.TonerBackground = list(
        src = "Stamen.TonerBackground",
        q = "https://stamen-tiles-{s}.a.ssl.fastly.net/toner-background/{z}/{x}/{y}.png",
        sub = c("a", "b", "c", "d"),
        cit = "Map tiles by CC BY 3.0 \u2014 Map data \u00A9 OpenStreetMap contributors"
      ),
      Stamen.TonerHybrid = list(
        src = "Stamen.TonerHybrid",
        q = "https://stamen-tiles-{s}.a.ssl.fastly.net/toner-hybrid/{z}/{x}/{y}.png",
        sub = c("a", "b", "c", "d"),
        cit = "Map tiles by CC BY 3.0 \u2014 Map data \u00A9 OpenStreetMap contributors"
      ),
      Stamen.TonerLines = list(
        src = "Stamen.TonerLines",
        q = "https://stamen-tiles-{s}.a.ssl.fastly.net/toner-lines/{z}/{x}/{y}.png",
        sub = c("a", "b", "c", "d"),
        cit = "Map tiles by CC BY 3.0 \u2014 Map data \u00A9 OpenStreetMap contributors"
      ),
      Stamen.TonerLabels = list(
        src = "Stamen.TonerLabels",
        q = "https://stamen-tiles-{s}.a.ssl.fastly.net/toner-labels/{z}/{x}/{y}.png",
        sub = c("a", "b", "c", "d"),
        cit = "Map tiles by CC BY 3.0 \u2014 Map data \u00A9 OpenStreetMap contributors"
      ),
      Stamen.TonerLite = list(
        src = "Stamen.TonerLite",
        q = "https://stamen-tiles-{s}.a.ssl.fastly.net/toner-lite/{z}/{x}/{y}.png",
        sub = c("a", "b", "c", "d"),
        cit = "Map tiles by CC BY 3.0 \u2014 Map data \u00A9 OpenStreetMap contributors"
      ),
      Stamen.Watercolor = list(
        src = "Stamen.Watercolor",
        q = "https://stamen-tiles-{s}.a.ssl.fastly.net/watercolor/{z}/{x}/{y}.jpg",
        sub = c("a", "b", "c", "d"),
        cit = "Map tiles by CC BY 3.0 \u2014 Map data \u00A9 OpenStreetMap contributors"
      ),
      Stamen.Terrain = list(
        src = "Stamen.Terrain",
        q = "https://stamen-tiles-{s}.a.ssl.fastly.net/terrain/{z}/{x}/{y}.png",
        sub = c("a", "b", "c", "d"),
        cit = "Map tiles by CC BY 3.0 \u2014 Map data \u00A9 OpenStreetMap contributors"
      ),
      Stamen.TerrainBackground = list(
        src = "Stamen.TerrainBK",
        q = "https://stamen-tiles-{s}.a.ssl.fastly.net/terrain-background/{z}/{x}/{y}.png",
        sub = c("a", "b", "c", "d"),
        cit = "Map tiles by CC BY 3.0 \u2014 Map data \u00A9 OpenStreetMap contributors"
      ),
      Stamen.TerrainLabels = list(
        src = "Stamen.Terrainlabs",
        q = "https://stamen-tiles-{s}.a.ssl.fastly.net/terrain-labels/{z}/{x}/{y}.png",
        sub = c("a", "b", "c", "d"),
        cit = "Map tiles by CC BY 3.0 \u2014 Map data \u00A9 OpenStreetMap contributors"
      ),
      Esri.WorldStreetMap = list(
        src = "EsriWSM",
        q = "https://server.arcgisonline.com/ArcGIS/rest/services/World_Street_Map/MapServer/tile/{z}/{y}/{x}.jpg",
        sub = NA,
        cit = "Tiles \u00A9 Esri \u2014 Source: Esri, DeLorme, NAVTEQ, USGS, Intermap, iPC, NRCAN, Esri Japan, METI, Esri China (Hong Kong), Esri (Thailand), TomTom, 2012"
      ),
      Esri.DeLorme = list(
        src = "EsriDLor",
        q = "https://server.arcgisonline.com/ArcGIS/rest/services/Specialty/DeLorme_World_Base_Map/MapServer/tile/{z}/{y}/{x}.jpg",
        sub = NA,
        cit = "Tiles \u00A9 Esri \u2014 Copyright: \u00A92012 DeLorme"
      ),
      Esri.WorldTopoMap = list(
        src = "EsriWTM",
        q = "https://server.arcgisonline.com/ArcGIS/rest/services/World_Topo_Map/MapServer/tile/{z}/{y}/{x}.jpg",
        sub = NA,
        cit = "Tiles \u00A9 Esri \u2014 Esri, DeLorme, NAVTEQ, TomTom, Intermap, iPC, USGS, FAO, NPS, NRCAN, GeoBase, Kadaster NL, Ordnance Survey, Esri Japan, METI, Esri China (Hong Kong), and the GIS User Community"
      ),
      Esri.WorldImagery = list(
        src = "EsriWI",
        q = "https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}.jpg",
        sub = NA,
        cit = "Tiles \u00A9 Esri \u2014 Source: Esri, i-cubed, USDA, USGS, AEX, GeoEye, Getmapping, Aerogrid, IGN, IGP, UPR-EGP, and the GIS User Community"
      ),
      Esri.WorldTerrain = list(
        src = "EsriWT",
        q = "https://server.arcgisonline.com/ArcGIS/rest/services/World_Terrain_Base/MapServer/tile/{z}/{y}/{x}.jpg",
        sub = NA,
        cit = "Tiles \u00A9 Esri \u2014 Source: USGS, Esri, TANA, DeLorme, and NPS"
      ),
      Esri.WorldShadedRelief = list(
        src = "EsriWSR",
        q = "https://server.arcgisonline.com/ArcGIS/rest/services/World_Shaded_Relief/MapServer/tile/{z}/{y}/{x}.jpg",
        sub = NA,
        cit = "Tiles \u00A9 Esri \u2014 Source: Esri"
      ),
      Esri.OceanBasemap = list(
        src = "EsriOBM",
        q = "https://server.arcgisonline.com/ArcGIS/rest/services/Ocean_Basemap/MapServer/tile/{z}/{y}/{x}.jpg",
        sub = NA,
        cit = "Tiles \u00A9 Esri \u2014 Sources: GEBCO, NOAA, CHS, OSU, UNH, CSUMB, National Geographic, DeLorme, NAVTEQ, and Esri"
      ),
      Esri.NatGeoWorldMap = list(
        src = "EsriNGW",
        q = "https://server.arcgisonline.com/ArcGIS/rest/services/NatGeo_World_Map/MapServer/tile/{z}/{y}/{x}.jpg",
        sub = NA,
        cit = "Tiles \u00A9 Esri \u2014 National Geographic, Esri, DeLorme, NAVTEQ, UNEP-WCMC, USGS, NASA, ESA, METI, NRCAN, GEBCO, NOAA, iPC"
      ),
      Esri.WorldGrayCanvas = list(
        src = "EsriWGC",
        q = "https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Base/MapServer/tile/{z}/{y}/{x}.jpg",
        sub = NA,
        cit = "Tiles \u00A9 Esri \u2014 Esri, DeLorme, NAVTEQ"
      ),
      CartoDB.Positron = list(
        src = "CartoP",
        q = "https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png",
        sub = c("a", "b", "c", "d"),
        cit = "\u00A9 OpenStreetMap contributors \u00A9 CARTO"
      ),
      CartoDB.PositronNoLabels = list(
        src = "CartoPNL",
        q = "https://{s}.basemaps.cartocdn.com/light_nolabels/{z}/{x}/{y}.png",
        sub = c("a", "b", "c", "d"),
        cit = "\u00A9 OpenStreetMap contributors \u00A9 CARTO"
      ),
      CartoDB.PositronOnlyLabels = list(
        src = "CartoPOL",
        q = "https://{s}.basemaps.cartocdn.com/light_only_labels/{z}/{x}/{y}.png",
        sub = c("a", "b", "c", "d"),
        cit = "\u00A9 OpenStreetMap contributors \u00A9 CARTO"
      ),
      CartoDB.DarkMatter = list(
        src = "CartoDM",
        q = "https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png",
        sub = c("a", "b", "c", "d"),
        cit = "\u00A9 OpenStreetMap contributors \u00A9 CARTO"
      ),
      CartoDB.DarkMatterNoLabels = list(
        src = "CartoDMNL",
        q = "https://{s}.basemaps.cartocdn.com/dark_nolabels/{z}/{x}/{y}.png",
        sub = c("a", "b", "c", "d"),
        cit = "\u00A9 OpenStreetMap contributors \u00A9 CARTO"
      ),
      CartoDB.DarkMatterOnlyLabels = list(
        src = "CartoDMOL",
        q = "https://{s}.basemaps.cartocdn.com/dark_only_labels/{z}/{x}/{y}.png",
        sub = c("a", "b", "c", "d"),
        cit = "\u00A9 OpenStreetMap contributors \u00A9 CARTO"
      ),
      CartoDB.Voyager = list(
        src = "CartoV",
        q = "https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png",
        sub = c("a", "b", "c", "d"),
        cit = "\u00A9 OpenStreetMap contributors \u00A9 CARTO"
      ),
      CartoDB.VoyagerNoLabels = list(
        src = "CartoVNL",
        q = "https://{s}.basemaps.cartocdn.com/rastertiles/voyager_nolabels/{z}/{x}/{y}.png",
        sub = c("a", "b", "c", "d"),
        cit = "\u00A9 OpenStreetMap contributors \u00A9 CARTO"
      ),
      CartoDB.VoyagerOnlyLabels = list(
        src = "CartoVOL",
        q = "https://{s}.basemaps.cartocdn.com/rastertiles/voyager_only_labels/{z}/{x}/{y}.png",
        sub = c("a", "b", "c", "d"),
        cit = "\u00A9 OpenStreetMap contributors \u00A9 CARTO"
      ),
      HikeBike = list(
        src = "HikeBike",
        q = "https://tiles.wmflabs.org/hikebike/{z}/{x}/{y}.png",
        sub = NA,
        cit = "\u00A9 OpenStreetMap contributors"
      ),
      Wikimedia = list(
        src = "Wikimedia",
        q = "https://maps.wikimedia.org/osm-intl/{z}/{x}/{y}.png",
        sub = NA,
        cit = "Wikimedia"
      ),
      Thunderforest.OpenCycleMap = list(
        src = "Tf",
        q = "https://tile.thunderforest.com/cycle/{z}/{x}/{y}.png?apikey=XXXXXX",
        sub = NA,
        cit = "Maps \u00A9 www.thunderforest.com, Data \u00A9 www.osm.org/copyright"
      ),
      Thunderforest.Transport = list(
        src = "Tf.Tr",
        q = "https://tile.thunderforest.com/transport/{z}/{x}/{y}.png?apikey=XXXXXX",
        sub = NA,
        cit = "Maps \u00A9 www.thunderforest.com, Data \u00A9 www.osm.org/copyright"
      ),
      Thunderforest.TransportDark = list(
        src = "Tf.TrDr",
        q = "https://tile.thunderforest.com/transport-dark/{z}/{x}/{y}.png?apikey=XXXXXX",
        sub = NA,
        cit = "Maps \u00A9 www.thunderforest.com, Data \u00A9 www.osm.org/copyright"
      ),
      Thunderforest.SpinalMap = list(
        src = "Tf.SP",
        q = "https://tile.thunderforest.com/spinal-map/{z}/{x}/{y}.png?apikey=XXXXXX",
        sub = NA,
        cit = "Maps \u00A9 www.thunderforest.com, Data \u00A9 www.osm.org/copyright"
      ),
      Thunderforest.Landscape = list(
        src = "Tf.Lc",
        q = "https://tile.thunderforest.com/landscape/{z}/{x}/{y}.png?apikey=XXXXXX",
        sub = NA,
        cit = "Maps \u00A9 www.thunderforest.com, Data \u00A9 www.osm.org/copyright"
      ),
      Thunderforest.Outdoors = list(
        src = "Tf.Out",
        q = "https://tile.thunderforest.com/outdoors/{z}/{x}/{y}.png?apikey=XXXXXX",
        sub = NA,
        cit = "Maps \u00A9 www.thunderforest.com, Data \u00A9 www.osm.org/copyright"
      ),
      Thunderforest.Pioneer = list(
        src = "Tf.Pion",
        q = "https://tile.thunderforest.com/pioneer/{z}/{x}/{y}.png?apikey=XXXXXX",
        sub = NA,
        cit = "Maps \u00A9 www.thunderforest.com, Data \u00A9 www.osm.org/copyright"
      ),
      Thunderforest.MobileAtlas = list(
        src = "Tf.MB",
        q = "https://tile.thunderforest.com/mobile-atlas/{z}/{x}/{y}.png?apikey=XXXXXX",
        sub = NA,
        cit = "Maps \u00A9 www.thunderforest.com, Data \u00A9 www.osm.org/copyright"
      ),
      Thunderforest.Neighbourhood = list(
        src = "Tf.Nbg",
        q = "https://tile.thunderforest.com/neighbourhood/{z}/{x}/{y}.png?apikey=XXXXXX",
        sub = NA,
        cit = "Maps \u00A9 www.thunderforest.com, Data \u00A9 www.osm.org/copyright"
      )
    )
  }
  param
}
