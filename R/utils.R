test_input <- function(x) {
  allowed_classes <- c(
    "sf", "sfc", "bbox",
    "SpatRaster", "SpatVector", "SpatExtent"
  )
  if (!inherits(x, allowed_classes)) {
    stop(
      paste0(
        "x should be an sf, sfc, bbox, SpatRaster, ",
        "SpatVector or SpatExtent object"
      ),
      call. = FALSE
    )
  }
}


get_bbox_and_proj <- function(x) {
  lonlat <- "epsg:4326"
  lonlat_wkt <- terra::crs("epsg:4326")

  if (inherits(x, c("SpatRaster", "SpatVector"))) {
    origin_proj <- terra::crs(x)
    cb <- terra::ext(x)[c(1, 3, 2, 4)]
    # test for single point (apply buffer to obtain a correct bbox)
    if (length(unique(cb)) < 3) {
      x <- terra::buffer(x, 1000)
      cb <- terra::ext(x)[c(1, 3, 2, 4)]
    }
    bbx <- cb
    if (origin_proj != lonlat_wkt) {
      x_poly <- terra::as.polygons(x, extent = TRUE)
      x_proj <- terra::project(x_poly, lonlat)
      bbx <- terra::ext(x_proj)[c(1, 3, 2, 4)]
    }
  }



  if (inherits(x, c("sf", "sfc", "bbox"))) {
    origin_proj <- st_crs(x)$wkt
    cb <- st_bbox(x)
    # test for single point (apply buffer to obtain a correct bbox)
    if (length(unique(cb)) < 3) {
      # transform to 3857 to apply a 1km buffer around single point
      xt <- st_transform(x, "epsg:3857")
      xt <- st_buffer(st_geometry(xt), 1000)
      # and retransform to original proj
      cb <- st_bbox(st_transform(xt, origin_proj))
    }
    bbx <- cb
    if (origin_proj != lonlat_wkt) {
      bbx <- st_bbox(st_transform(st_as_sfc(bbx), lonlat))
    }
  }

  if (inherits(x, "SpatExtent")) {
    origin_proj <- st_crs(lonlat)$wkt
    bbx <- x[c(1, 3, 2, 4)]
    cb <- bbx
  }

  cb <- st_bbox(obj = cb, crs = st_crs(origin_proj))
  bbx <- st_bbox(bbx, crs = lonlat)
  return(list(origin_proj = origin_proj, cb = cb, bbx = bbx))
}

# get the tiles according to the grid
get_tiles_n <- function(tile_grid, verbose, cachedir, forceDownload, apikey) {
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
    forceDownload = forceDownload,
    apikey = tile_grid$apikey
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
dl_t <- function(x, z, ext, src, q, verbose, cachedir, forceDownload, apikey) {
  # if cachedir is missing, save to temporary filepath
  if (missing(cachedir)) {
    cachedir <- tempdir()
  } else {
    # create the cachedir if it doesn't exist.
    if (!dir.exists(cachedir)) {
      dir.create(cachedir)
    }
    # uses subdirectories based on src to make the directory easier
    # for users to navigate
    subdir <- paste0(cachedir, "/", src)
    if (!dir.exists(subdir)) {
      dir.create(subdir)
    }
    cachedir <- subdir
  }

  # apply coerces to the same length character, need to ensure no
  # whitespace in numbers
  x <- trimws(x)

  outfile <- paste0(cachedir, "/", src, "_", z, "_", x[1], "_", x[2], ".", ext)
  if (!file.exists(outfile) || isTRUE(forceDownload)) {
    q <- gsub(pattern = "{s}", replacement = x[3], x = q, fixed = TRUE)
    q <- gsub(pattern = "{x}", replacement = x[1], x = q, fixed = TRUE)
    q <- gsub(pattern = "{y}", replacement = x[2], x = q, fixed = TRUE)
    q <- gsub(pattern = "{z}", replacement = z, x = q, fixed = TRUE)
    ano_q <- q
    q <- gsub(pattern = "{apikey}", replacement = apikey, x = q, fixed = TRUE)

    e <- try(
      {
        curl::curl_download(url = q, destfile = outfile)
      },
      silent = TRUE
    )
    if (inherits(e, "try-error")) {
      outfile <- NULL
    }
    if (verbose) {
      message(ano_q, " => ", outfile)
    }
  }
  outfile
}

# compose tiles
compose_tile_grid <- function(tile_grid, images, forceDownload) {
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
      terra::RGB(r_img) <- c(1, 2, 3)
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
  } else {
    # all tiles together
    rout <- warp_method(bricks, images, forceDownload)
  }
  rout
}



warp_method <- function(bricks, images, forceDownload) {
  # wrapped with try catch - if gdal warp fails defaults to terra::merge
  out_ras <- tryCatch(
    {
      save_ras <- function(ras, .img) {
        name <- paste(file_path_sans_ext(.img),
          ".tif",
          sep = ""
        )
        if (!file.exists(name) | isTRUE(forceDownload)) {
          terra::writeRaster(ras, name, overwrite = TRUE)
        }
        return(name)
      }

      ras_files <- mapply(save_ras, bricks, images)

      merge_path <- tempfile(fileext = ".tif")
      sf::gdal_utils(
        util = "warp", options = c("-srcnodata", "None"),
        source = as.character(ras_files),
        destination = merge_path
      )

      outras <- terra::rast(merge_path)
      return(outras)
    },
    error = function(e) {
      warning(
        "\nReceived error from gdalwarp.",
        "Attempting merge using terra::merge"
      )
      outras <- do.call(terra::merge, bricks)
      return(outras)
    }
  )
  return(out_ras)
}



# providers parameters
get_param <- function(provider) {
  if (is.list(provider) && length(provider) == 4) {
    param <- provider
  } else {
    stamen_provider <- c(
      "Stamen.Toner", "Stamen.TonerBackground",
      "Stamen.TonerHybrid", "Stamen.TonerLines",
      "Stamen.TonerLabels", "Stamen.TonerLite",
      "Stamen.Watercolor", "Stamen.Terrain",
      "Stamen.TerrainBackground",
      "Stamen.TerrainLabels"
    )
    if (provider %in% stamen_provider) {
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
    param <- maptiles_providers[[provider]]
  }
  param
}
