.onAttach <- function(libname, pkgname) {
  gdv <- terra::gdal_version()
  if (gdv < "3.0.4") {
    a <- paste("\nNOTE: using GDAL version", gdv,
               "\nYou need at least version 3.0.4\n")
    packageStartupMessage(a)
  }
}
