providers <- list("OpenStreetMap.MapnikBW", "OpenStreetMap",
                  "OpenStreetMap.France", "OpenStreetMap.HOT", "OpenTopoMap",
                  "Stamen.Toner", "Stamen.TonerBackground", "Stamen.TonerLite",
                  "Stamen.Watercolor", "Stamen.Terrain", "Stamen.TerrainBackground",
                  "Esri.WorldStreetMap", "Esri.DeLorme",
                  "Esri.WorldTopoMap", "Esri.WorldImagery", "Esri.WorldTerrain",
                  "Esri.WorldShadedRelief", "Esri.OceanBasemap", "Esri.NatGeoWorldMap",
                  "Esri.WorldGrayCanvas", "CartoDB.Positron", "CartoDB.PositronNoLabels",
                  "CartoDB.DarkMatter", "CartoDB.DarkMatterNoLabels",
                  "CartoDB.Voyager", "CartoDB.VoyagerNoLabels",
                  "HikeBike", "Wikimedia", "Thunderforest.OpenCycleMap",
                  "Thunderforest.Transport", "Thunderforest.TransportDark", "Thunderforest.SpinalMap",
                  "Thunderforest.Landscape", "Thunderforest.Pioneer",
                  "Thunderforest.MobileAtlas", "Thunderforest.Neighbourhood")
length(providers)
providers <- names(maptiles_providers)
apikey <- "xx"
nc <- st_read(system.file("shape/nc.shp", package="sf"), quiet = TRUE)
nc <- st_transform(nc, 3857)
library(mapsf)

png("man/figures/README-front.png", width = 210*7, height = 84*7)
par(mar = c(0,0,0,0), mfrow = c(7,7))
for (i in 1:length(providers)){
  t <- get_tiles(nc, provider = providers[[i]],
                 zoom = 5, cachedir = "./tiles",
                 crop = T, apikey = apikey)
  plot_tiles(t)
  mf_title(txt = providers[[i]], pos = "center",tab = TRUE, inner = TRUE,
           line = 1.5, cex = 1.5, bg = "white", fg = "black")
}
dev.off()


6*7
46/9
library(sf)
library(maptiles)
apikey <- "xxx"
for (i in 1:length(providers)){
  t <- get_tiles(nc, provider = providers[[i]], zoom = 7,
                 cachedir = "./tiles", crop = T, apikey = apikey)
  png(sprintf("gif/tile%03d.png", i), width = 827, height = 318)
  par(mar = c(0,0,0,0))
  plot_tiles(t)
  library(mapsf)
  tc_title(txt = providers[[i]], pos = "center",tab = TRUE, inner = TRUE,
           line = 1.5, cex = 1.5, bg = "white", fg = "black")
  tc_credits(txt = get_credit(providers[[i]]), pos = "rightbottom", cex = .8)
  dev.off()
}

