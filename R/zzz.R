.onAttach <- function(libname, pkgname) {
  gdv <- terra::gdal()
  if (gdv < "2.2.3") {
    a <- paste("\nNOTE: using GDAL version", gdv,
               "\nYou need at least version 2.2.3\n")
    packageStartupMessage(a)
  }
}
