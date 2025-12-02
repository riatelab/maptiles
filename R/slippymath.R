###############################################################################
## The following code originaly comes from the slippymath package.
## It has been modified and simplified to remove some dependencies (e.g. purrr)
## by maptiles author.
## The original code use the MIT License
###############################################################################
# MIT License
#
# Copyright (c) 2018 Miles McBain
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"),
# to deal in the Software without restriction, including without limitation
# the rights to use, copy, modify, merge, publish, distribute, sublicense,
# and/or sell copies of the Software, and to permit persons to whom the Software
# is furnished to do so, subject to the following conditions:
#
#   The above copyright notice and this permission notice shall be included in
#   all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

bbox_to_tile_grid <- function(bbox, zoom = NULL, max_tiles = NULL) {
  tile_extent <- bbox_tile_extent(bbox, zoom)
  x_tiles <- tile_extent$x_min:tile_extent$x_max
  y_tiles <- tile_extent$y_min:tile_extent$y_max
  tile_grid <- list(
    tiles = expand.grid(x = x_tiles, y = y_tiles),
    zoom = zoom
  )
  tile_grid
}

bbox_tile_extent <- function(bbox, zoom) {
  min_tile <- lonlat_to_tilenum(
    lat_deg = bbox["ymin"], lon_deg = bbox["xmin"], zoom
  )
  max_tile <- lonlat_to_tilenum(
    lat_deg = bbox["ymax"], lon_deg = bbox["xmax"], zoom
  )
  list(
    x_min = min_tile$x, y_min = max_tile$y, x_max = max_tile$x,
    y_max = min_tile$y
  )
}

lonlat_to_tilenum <- function(lon_deg, lat_deg, zoom) {
  lon_rad <- radians(lon_deg)
  lat_rad <- radians(lat_deg)
  x <- lon_rad
  y <- asinh(tan(lat_rad))
  x <- (1 + (x / pi)) / 2
  y <- (1 - (y / pi)) / 2
  n_tiles <- 2^zoom
  xtile <- sm_clamp(floor(x * n_tiles), 0, n_tiles - 1)
  ytile <- sm_clamp(floor(y * n_tiles), 0, n_tiles - 1)
  list(x = xtile, y = ytile)
}

radians <- function(angle_deg) {
  angle_deg * pi / 180
}

degrees <- function(angle_rad) {
  (angle_rad * 180) / pi
}

sm_clamp <- function(x, mn, mx) {
  x[x < mn] <- mn
  x[x > mx] <- mx
  x
}

bbox_tile_query <- function(bbox, zoom_levels = 2:18) {
  l <- list()
  for (i in seq_along(zoom_levels)) {
    l[[i]] <- bbox_tile_extent(bbox, zoom = zoom_levels[i])
  }
  extents_at_zooms <- data.frame(
    matrix(
      data = unlist(lapply(l, unlist)), ncol = 4, byrow = TRUE,
      dimnames = list(seq_along(l), c("x_min", "y_min", "x_max", "y_max"))
    )
  )
  extents_at_zooms$y_dim <- abs(extents_at_zooms$y_max - extents_at_zooms$y_min) + 1
  extents_at_zooms$x_dim <- abs(extents_at_zooms$x_max - extents_at_zooms$x_min) + 1
  extents_at_zooms$total_tiles <- extents_at_zooms$y_dim * extents_at_zooms$x_dim
  extents_at_zooms$zoom <- zoom_levels
  extents_at_zooms
}

tile_bbox <- function(x, y, zoom) {
  bottom_left <- lonlat_to_merc(t(as.matrix(unlist(tilenum_to_lonlat(x, y + 1, zoom)))))
  top_right <- lonlat_to_merc(t(as.matrix(unlist(tilenum_to_lonlat(x + 1, y, zoom)))))
  structure(
    c(
      xmin = bottom_left[[1]], ymin = bottom_left[[2]],
      xmax = top_right[[1]], ymax = top_right[[2]]
    ),
    class = "bbox",
    crs = sf::st_crs("EPSG:3857")
  )
}

tilenum_to_lonlat <- function(x, y, zoom) {
  n_tiles <- 2^zoom
  lon_rad <- (((x / n_tiles) * 2) - 1) * pi
  merc_lat <- (1 - ((y / n_tiles) * 2)) * pi
  lat_rad <- atan(sinh(merc_lat))
  list(lon = degrees(lon_rad), lat = degrees(lat_rad))
}

lonlat_to_merc <- function(ll) {
  A <- 6378137
  MAXEXTENT <- 20037508.342789244
  xy <- cbind(A * radians(ll[, 1]), A * log(tan((pi * 0.25) + (0.5 * radians(ll[, 2])))))
  xy[, 1] <- sm_clamp(xy[, 1], -MAXEXTENT, MAXEXTENT)
  xy[, 2] <- sm_clamp(xy[, 2], -MAXEXTENT, MAXEXTENT)
  xy
}
