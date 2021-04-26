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
  if (!inherits(x, 'SpatRaster')){
    warning(paste0("x should be a SpatRaster"),
            call. = FALSE)
    return(invisible(NULL))
  }
  ops <- list(...)
  ops$x <- x
  ops$add <- add
  # Default opts
  ops$maxcell <- ifelse(is.null(ops$maxcell), terra::ncell(x), ops$maxcell)
  ops$bgalpha <- ifelse(is.null(ops$bgalpha), 0, ops$bgalpha)
  ops$smooth <- ifelse(is.null(ops$smooth), TRUE, ops$smooth)
  # if(nozo == TRUE){
  #   tsp <- dim(ops$x)[2:1]
  #   dsp <- dev.size("px")
  #   dsi <- dev.size("in")
  #   dd <- ((dsp - tsp)/ 2) / (dsp/dsi)
  #   dd <- c(dd[2:1], dd[2:1]) / 0.2
  #   if(min(dd)>=0){
  #     ops$smooth <- F
  #     ops$mar <- dd
  #   }
  # }
  do.call(terra::plotRGB, ops)
}
