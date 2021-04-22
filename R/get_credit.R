#' @title Get basemap tiles attribution
#' @name get_credit
#' @description Get the attribution of map tiles.
#' @param provider provider name
#' @export
#' @examples
#' get_credit("OpenStreetMap")
get_credit <- function(provider){
  maptiles_providers[[provider]]$cit
}
