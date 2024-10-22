#' @title Providers
#' @description
#' List of builtin providers with their name, URL, subdomains and
#' attribution text.
#' @return A list of is returned.
#' @export
#' @examples
#' get_providers()
get_providers <- function() {
  return(.global_maptiles$providers)
}
