% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/create_provider.R
\name{create_provider}
\alias{create_provider}
\title{Create a new tile provider}
\usage{
create_provider(name, url, sub = NA, citation)
}
\arguments{
\item{name}{name of the provider.}

\item{url}{url of the provider.
The url must contain \{x\}, \{y\} and \{z\} placeholders. It may also contain
\{s\} for sub-domains or \{apikey\} for API keys (see Examples).}

\item{sub}{sub-domains.}

\item{citation}{attribution text of the provider.}
}
\value{
a list is returned. This list can be used by \link{get_tiles}.
}
\description{
Use this function to create new tiles provider.
}
\examples{
statdia_toner <- create_provider(
  name = "stadia_stamen_toner",
  url = "https://tiles.stadiamaps.com/tiles/stamen_toner/{z}/{x}/{y}.png?api_key={apikey}",
  citation = "© Stadia Maps © Stamen Design © OpenMapTiles © OpenStreetMap contributors"
)
opentopomap <- create_provider(
  name = "otm",
  url = "https://{s}.tile.opentopomap.org/{z}/{x}/{y}.png",
  sub = c("a", "b", "c"),
  citation = "map data: © OpenStreetMap contributors, SRTM | map style: © OpenTopoMap (CC-BY-SA)"
)
IGN <- create_provider(
  name = "orthophoto_IGN",
  url = paste0(
    "https://data.geopf.fr/wmts?",
    "request=GetTile",
    "&service=WMTS",
    "&version=1.0.0",
    "&style=normal",
    "&tilematrixset=PM_6_18",
    "&format=image/jpeg",
    "&layer=ORTHOIMAGERY.ORTHOPHOTOS.BDORTHO",
    "&tilematrix={z}",
    "&tilerow={y}",
    "&tilecol={x}"
  ),
  citation = "IGN, BD ORTHO®"
)

# Find TileMatrixSet and Style values
layer <- "ORTHOIMAGERY.ORTHOPHOTOS.BDORTHO"
path <- "https://data.geopf.fr/wmts?"
param_info <- "service=wmts&request=GetCapabilities&version=1.0.0"
url <- paste0("WMTS:", path, param_info, ",layer=", layer)
\dontrun{
tmp <- tempfile(fileext = ".xml")
sf::gdal_utils(
  util = "translate",
  source = url, destination = tmp,
  options = c("-of", "WMTS")
)
readLines(tmp)
}
}
