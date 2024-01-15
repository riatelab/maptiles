providers <- list(
  "OpenStreetMap", "OpenStreetMap.France",
  "OpenStreetMap.HOT", "OpenTopoMap",
  "Stadia.StamenToner", "Stadia.StamenTonerBackground",
  "Stadia.StamenTonerLite", "Stadia.StamenWatercolor",
  "Stadia.StamenTerrain", "Stadia.StamenTerrainBackground",
  "Esri.WorldStreetMap", "Esri.WorldTopoMap",
  "Esri.WorldImagery", "Esri.WorldTerrain", "Esri.WorldShadedRelief",
  "Esri.OceanBasemap", "Esri.NatGeoWorldMap", "Esri.WorldGrayCanvas",
  "CartoDB.Positron", "CartoDB.PositronNoLabels", "CartoDB.PositronOnlyLabels",
  "CartoDB.DarkMatter",
  "CartoDB.Voyager", "CartoDB.VoyagerNoLabels",
  "Thunderforest.OpenCycleMap", "Thunderforest.Transport",
  "Thunderforest.TransportDark", "Thunderforest.SpinalMap",
  "Thunderforest.Landscape",
  "Thunderforest.Pioneer", "Thunderforest.MobileAtlas",
  "Thunderforest.Neighbourhood"
)
library(sf)
library(maptiles)
nc <- st_read(system.file("shape/nc.shp", package = "sf"), quiet = TRUE)
nc <- st_transform(nc, 3857)
library(mapsf)
png("man/figures/README-front.png", width = 202 * 4, height = 76 * 8)
par(mar = c(0, 0, 0, 0), mfrow = c(8, 4))
for (i in 1:length(providers)) {
  t <- get_tiles(nc,
    provider = providers[[i]],
    zoom = 5, cachedir = "tiles",
    crop = T, verbose = T
  )
  plot_tiles(t)
  mf_title(
    txt = providers[[i]], pos = "center", tab = TRUE, inner = TRUE,
    line = 1.5, cex = 1.5, bg = "white", fg = "black", font = 2
  )
}
dev.off()
