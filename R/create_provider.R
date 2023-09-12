#' Create a new tile provider
#'
#' @param name name of the provider
#' @param url url of the provider. The url must contain {x}, {y} and {z} placeholder
#' @param sub sub-domains
#' @param citation attribution text of the provider
#'
#' @return a list is returned. This list can be used by get_tiles()
#' @export
#'
#' @examples
create_provider <- function(name, url, sub = NA, citation){

  return(list(src = name, q = url, sub = sub, cit = citation))


}



