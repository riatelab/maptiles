#' @title Get basemap tiles attribution
#' @name mp_get_tiles_attribution
#' @description Get the attribution of map tiles.
#' @param provider provider name
#' @export
#' @examples
#' mp_get_tiles_attribution("OpenStreetMap")
mp_get_tiles_attribution <- function(provider){
  maptiles_providers[[provider]]$cit
}
