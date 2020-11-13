#' @title Plot map tiles
#' @description Plot a SpatRaster object over a map. It can be used to plot tiles.
#' @name plot_tiles
#' @param x a SpatRaster object.
#' @param add whether to add the layer to an existing plot (TRUE) or
#' not (FALSE).
#' @param ... bgalpha, interpolate, or other arguments passed to be passed to
#' \code{\link[terra:plotRGB]{plotRGB}}
#' @note This function is a wrapper for \code{\link[terra:plotRGB]{plotRGB}}
#' from the terra package.
#' @export
#' @importFrom graphics plot.new plot.window
#' @examples
#' library(sf)
#' library(maptiles)
#' nc <- st_read(system.file("shape/nc.shp", package="sf"), quiet = TRUE)
#' nc_osm <- get_tiles(nc, crop = TRUE)
#' plot_tiles(nc_osm)
plot_tiles <- function(x, add = FALSE, ...) {
  if (gdal_version() < "3.0.4"){
    warning(paste0("Your GDAL version is ",gdal_version(),
                   ". You need GDAL >= 3.0.4 to use maptiles"),
            call. = FALSE)
    return(invisible(NULL))
  }

  if (add == FALSE) {
    ext <- as.vector(ext(x))
    plot.new()
    plot.window(
      xlim = ext[1:2], ylim = ext[3:4],
      xaxs = "i", yaxs = "i", asp = TRUE
    )
  }
  ops <- list(...)
  ops$x <- x
  ops$add <- TRUE
  # Default opts
  ops$maxcell <- ifelse(is.null(ops$maxcell), terra::ncell(x), ops$maxcell)
  ops$bgalpha <- ifelse(is.null(ops$bgalpha), 0, ops$bgalpha)
  ops$interpolate <- ifelse(is.null(ops$interpolate), TRUE, ops$interpolate)
  do.call(terra::plotRGB, ops)
}
