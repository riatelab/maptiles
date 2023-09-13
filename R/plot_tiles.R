#' @title Plot map tiles
#' @description Plot map tiles.
#' @name plot_tiles
#' @param x a SpatRaster object.
#' @param add whether to add the layer to an existing plot (TRUE) or
#' not (FALSE).
#' @param ... bgalpha, interpolate, or other arguments passed to be passed to
#' \code{\link[terra:plotRGB]{plotRGB}}
#' @param adjust if TRUE, plot the raster without zoom-in or zoom-out in the
#' graphic device: add margins if the raster is smaller than the graphic device,
#' zoom-in if the raster is larger than the graphic device.
#' @note This function is a wrapper for \code{\link[terra:plotRGB]{plotRGB}}
#' from the terra package.
#' @export
#' @importFrom graphics plot.new plot.window
#' @importFrom grDevices dev.size
#' @examples
#' library(sf)
#' library(maptiles)
#' nc <- st_read(system.file("shape/nc.shp", package = "sf"), quiet = TRUE)
#' nc_osm <- get_tiles(nc, crop = TRUE)
#' plot_tiles(nc_osm)
plot_tiles <- function(x, adjust = FALSE, add = FALSE, ...) {
  if (is.null(x)) {
    message("x is NULL")
    return(invisible(NULL))
  }
  if (!inherits(x, "SpatRaster")) {
    warning(paste0("x should be a SpatRaster"),
      call. = FALSE
    )
    return(invisible(NULL))
  }
  ops <- list(...)
  ops$x <- x
  ops$add <- add
  # Default opts
  ops$maxcell <- ifelse(is.null(ops$maxcell), Inf, ops$maxcell)
  ops$bgalpha <- ifelse(is.null(ops$bgalpha), 0, ops$bgalpha)
  ops$smooth <- ifelse(is.null(ops$smooth), TRUE, ops$smooth)


  # Add margins if the raster is smaller than the device
  # Zoom-in if the raster is larger than the device
  if (adjust == TRUE && add == FALSE) {
    tsp <- dim(ops$x)[2:1]
    dsp <- dev.size("px")
    dsi <- dev.size("in")
    dd <- ((dsp - tsp) / 2) / (dsp / dsi)
    dd <- c(dd[2:1], dd[2:1]) / 0.2
    if (min(dd) >= 0) {
      ops$mar <- dd
    } else {
      et <- terra::ext(ops$x)
      rt <- terra::res(ops$x)[1]
      wp <- (tsp[1] - dsp[1]) / 2
      hp <- (tsp[2] - dsp[2]) / 2
      et[1:4] <- c(
        et[1] + wp * rt,
        et[2] - wp * rt,
        et[3] + hp * rt,
        et[4] - hp * rt
      )
      ops$ext <- et
    }
    ops$smooth <- FALSE
  }
  do.call(terra::plotRGB, ops)
}
