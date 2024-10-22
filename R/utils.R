# test if input is correct
test_input <- function(x) {
  ok_classes <- c("sf", "sfc", "bbox", "SpatRaster", "SpatVector", "SpatExtent")
  if (!inherits(x, ok_classes)) {
    stop(
      paste0(
        "x should be an sf, sfc, bbox, SpatRaster, ",
        "SpatVector or SpatExtent object"
      ),
      call. = FALSE
    )
  }
  return(invisible(NULL))
}

# input a valid object
# return origin proj, origin bbox, lonlatbbox
get_bbox_and_proj <- function(x) {
  lonlat <- "epsg:4326"
  lonlat_wkt <- terra::crs("epsg:4326")

  if (inherits(x, c("SpatRaster", "SpatVector"))) {
    crs_input <- terra::crs(x)
    bbox_input <- terra::ext(x)[c(1, 3, 2, 4)]
    # test for single point (apply buffer to obtain a correct bbox)
    if (length(unique(bbox_input)) < 3) {
      x <- terra::buffer(x, 1000)
      bbox_input <- terra::ext(x)[c(1, 3, 2, 4)]
    }
    bbox_lonlat <- bbox_input
    if (crs_input != lonlat_wkt) {
      x_poly <- terra::as.polygons(x, extent = TRUE)
      x_proj <- terra::project(x_poly, lonlat)
      bbox_lonlat <- terra::ext(x_proj)[c(1, 3, 2, 4)]
    }
  }
  if (inherits(x, c("sf", "sfc", "bbox"))) {
    crs_input <- st_crs(x)$wkt
    bbox_input <- st_bbox(x)
    # test for single point (apply buffer to obtain a correct bbox)
    if (length(unique(bbox_input)) < 3) {
      # transform to 3857 to apply a 1km buffer around single point
      xt <- st_transform(x, "epsg:3857")
      xt <- st_buffer(st_geometry(xt), 1000)
      # and retransform to original proj
      bbox_input <- st_bbox(st_transform(xt, crs_input))
    }
    bbox_lonlat <- bbox_input
    if (crs_input != lonlat_wkt) {
      bbox_lonlat <- st_bbox(st_transform(st_as_sfc(bbox_lonlat), lonlat))
    }
  }

  if (inherits(x, "SpatExtent")) {
    crs_input <- st_crs(lonlat)$wkt
    bbox_lonlat <- x[c(1, 3, 2, 4)]
    bbox_input <- bbox_lonlat
  }

  bbox_input <- st_bbox(obj = bbox_input, crs = st_crs(crs_input))
  bbox_lonlat <- st_bbox(bbox_lonlat, crs = lonlat)

  return(list(
    crs_input = crs_input, bbox_input = bbox_input,
    bbox_lonlat = bbox_lonlat
  ))
}

# get fle extension from url
get_extension <- function(q) {
  # extension management
  if (length(grep(".jpg", q)) > 0) {
    ext <- "jpg"
  } else if (length(grep(".jpeg", q)) > 0) {
    ext <- "jpeg"
  } else if (length(grep(".png", q)) > 0) {
    ext <- "png"
  } else if (length(grep(".webp", q)) > 0) {
    ext <- "webp"
  }
  return(ext)
}



# providers parameters
get_param <- function(provider) {
  if (is.list(provider) && length(provider) == 4) {
    param <- provider
  } else {
    stamen_provider <- c(
      "Stamen.Toner", "Stamen.TonerBackground", "Stamen.TonerHybrid",
      "Stamen.TonerLines", "Stamen.TonerLabels", "Stamen.TonerLite",
      "Stamen.Watercolor", "Stamen.Terrain", "Stamen.TerrainBackground",
      "Stamen.TerrainLabels"
    )
    builtin_provider <- c(stamen_provider, names(.global_maptiles$providers))
    if (!provider %in% builtin_provider) {
      stop(paste0("'", provider, "' is not a builtin provider."), call. = FALSE)
    }
    if (provider %in% stamen_provider) {
      provider <- gsub("\\.", "", provider)
      provider <- paste0("Stadia.", provider)
      warning(
        paste0(
          "Stamen is not providing tiles anymore.\n",
          "Please use '", provider, "' instead.\n",
          "Do not forget to fill the apikey argument ",
          "(see https://stadiamaps.com/stamen/)."
        ),
        call. = FALSE
      )
    }
    param <- .global_maptiles$providers[[provider]]
  }
  param$ext <- get_extension(param$q)
  return(param)
}

# get zoom
get_zoom <- function(zoom, bbox_lonlat) {
  # select a default zoom level
  if (missing(zoom)) {
    gz <- slippymath::bbox_tile_query(bbox_lonlat)
    zoom <- min(gz[gz$total_tiles %in% 4:10, "zoom"])
  }
  return(zoom)
}

# cache directory
get_cachedir <- function(cachedir, src) {
  if (missing(cachedir)) {
    cachedir <- tempdir()
  }
  cachedir <- file.path(cachedir, src)
  if (!dir.exists(cachedir)) {
    dir.create(cachedir, recursive = TRUE)
  }
  return(cachedir)
}

# create a filename with hash
get_filename <- function(bbox, zoom, crop, project, cachedir, url) {
  filename <- digest::digest(paste0(bbox, zoom, crop, project, cachedir, url),
    algo = "md5", serialize = FALSE
  )
  full_filename <- file.path(cachedir, paste0(filename, ".tif"))
  full_filename
}

# display info if verbose
display_infos <- function(verbose, zoom, citation, cachedir) {
  if (verbose) {
    message(
      "Zoom: ", zoom, "\n", "Source(s): ", citation, "\n",
      "Cache directory: ", cachedir
    )
  }
  return(invisible(NULL))
}

# Use cache raster
get_cached_raster <- function(filename, forceDownload, verbose) {
  if (file.exists(filename) && isFALSE(forceDownload)) {
    if (verbose) {
      message("The resulting raster is a previously cached raster.")
    }
    return(terra::rast(filename))
  } else {
    return(NULL)
  }
}


# get the tiles according to the grid
download_tiles <- function(tile_grid, param, apikey, verbose, cachedir,
                           forceDownload) {
  images <- vector("list", length = nrow(tile_grid$tiles))
  zoom <- tile_grid$zoom
  ext <- param$ext
  src <- param$src
  if (missing(apikey)) {
    apikey <- ""
    if (startsWith(src, "Stadia") && Sys.getenv("STADIA_MAPS") != "") {
      apikey <- Sys.getenv("STADIA_MAPS")
    }
    if (startsWith(src, "Thunderforest") &&
      Sys.getenv("THUNDERFOREST_MAPS") != "") {
      apikey <- Sys.getenv("THUNDERFOREST_MAPS")
    }
  }
  cpt <- 0
  for (i in seq_along(images)) {
    x <- tile_grid$tiles[i, ]
    x <- trimws(x)
    outfile <- paste0(
      cachedir, "/", src, "_", zoom, "_", x[1], "_",
      x[2], ".", ext
    )
    if (!file.exists(outfile) || isTRUE(forceDownload)) {
      q <- gsub(
        pattern = "{s}", replacement = sample(param$sub, 1, TRUE),
        x = param$q, fixed = TRUE
      )
      q <- gsub(pattern = "{x}", replacement = x[1], x = q, fixed = TRUE)
      q <- gsub(pattern = "{y}", replacement = x[2], x = q, fixed = TRUE)
      q <- gsub(pattern = "{z}", replacement = zoom, x = q, fixed = TRUE)
      q <- gsub(pattern = "{apikey}", replacement = apikey, x = q, fixed = TRUE)

      e <- try(curl::curl_download(url = q, destfile = outfile), silent = TRUE)

      if (inherits(e, "try-error")) {
        stop(
          paste0(
            "A problem occurred while downloading the tiles.\n",
            "Please check the tile provider address."
          ),
          call. = FALSE
        )
      }
      cpt <- cpt + 1
    }
    images[[i]] <- outfile
  }
  if (verbose) {
    ntiles <- length(images)
    message(ntiles, " tile", ifelse(ntiles > 1, "s", ""))
    if (cpt != length(images)) {
      message("The resulting raster is built with previously cached tiles.")
    }
  }
  return(images)
}

# compose tiles
compose_tiles <- function(tile_grid, images) {
  bricks <- vector("list", nrow(tile_grid$tiles))
  ext <- unique(tools::file_ext(images))[1]
  for (i in seq_along(bricks)) {
    bbox <- slippymath::tile_bbox(
      x = tile_grid$tiles$x[i],
      y = tile_grid$tiles$y[i],
      zoom = tile_grid$zoom
    )
    img <- images[[i]]

    # special for png tiles
    if (ext == "png") {
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

    # warning is: [rast] unknown extent
    r_img <- suppressWarnings(terra::rast(img))
    # add RGB info
    if (is.null(terra::RGB(r_img))) {
      terra::RGB(r_img) <- c(1, 2, 3)
    }
    # add extent
    terra::ext(r_img) <- terra::ext(bbox[c("xmin", "xmax", "ymin", "ymax")])
    bricks[[i]] <- r_img
  }
  # if only one tile is needed
  if (length(bricks) == 1) {
    rout <- bricks[[1]]
  } else {
    # all tiles together
    rout <- do.call(terra::merge, bricks)
  }
  rout
}


project_and_crop_raster <- function(ras, project, res, crop) {
  # set the projection
  w_mercator <- "epsg:3857"
  terra::crs(ras) <- w_mercator

  # use predefine destination raster
  if (project && st_crs(w_mercator)$wkt != res$crs_input) {
    temprast <- rast(ras)
    temprast <- project(temprast, res$crs_input)
    terra::res(temprast) <- signif(terra::res(temprast), 3)
    ras <- terra::project(ras, temprast)
    ras <- terra::trim(ras)
    bbox_output <- res$bbox_input
  } else {
    bbox_output <- st_bbox(st_transform(st_as_sfc(res$bbox_lonlat), w_mercator))
  }

  ras <- terra::clamp(ras, lower = 0, upper = 255, values = TRUE)

  # crop management
  if (crop) {
    ras <- terra::crop(x = ras, y = bbox_output[c(1, 3, 2, 4)], snap = "out")
  }
  # set R, G, B channels, such that plot(ras) will go to plotRGB
  terra::RGB(ras) <- 1:3
  return(ras)
}
