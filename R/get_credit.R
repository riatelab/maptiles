#' @title Get basemap tiles attribution
#' @name get_credit
#' @description Get the attribution of map tiles.
#' @param provider provider name or provider object
#' (as produced by \link{create_provider}).
#' @export
#' @examples
#' get_credit("OpenStreetMap")
get_credit <- function(provider) {
  if (is.list(provider) && length(provider) == 4) {
    return(provider$cit)
  }
  if (is.character(provider) && provider %in% names(.global_maptiles$providers)) {
    return(.global_maptiles$providers[[provider]]$cit)
  }
  return(NULL)
}
