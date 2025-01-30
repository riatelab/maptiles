#' @importFrom utils globalVariables
.global_maptiles <- new.env(parent = emptyenv())
globalVariables(".global_maptiles", package = "maptiles", add = FALSE)

.global_maptiles$providers <- list(
  OpenStreetMap = list(
    src = "OpenStreetMap",
    q = "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
    sub = NA,
    cit = "\ua9 OpenStreetMap contributors"
  ),
  OpenStreetMap.DE = list(
    src = "OpenStreetMap.DE",
    q = "https://tile.openstreetmap.de/tiles/osmde/{z}/{x}/{y}.png",
    sub = NA,
    cit = "\ua9 OpenStreetMap contributors"
  ),
  OpenStreetMap.France = list(
    src = "OpenStreetMap.France",
    q = "https://{s}.tile.openstreetmap.fr/osmfr/{z}/{x}/{y}.png",
    sub = c("a", "b", "c"),
    cit = "\ua9 OpenStreetMap France | \ua9 OpenStreetMap contributors"
  ),
  OpenStreetMap.HOT = list(
    src = "OpenStreetMap.HOT",
    q = "https://{s}.tile.openstreetmap.fr/hot/{z}/{x}/{y}.png",
    sub = c("a", "b", "c"),
    cit = "\ua9 OpenStreetMap contributors, Tiles style by Humanitarian OpenStreetMap Team hosted by OpenStreetMap France"
  ),
  OpenTopoMap = list(
    src = "OpenTopoMap",
    q = "https://{s}.tile.opentopomap.org/{z}/{x}/{y}.png",
    sub = c("a", "b", "c"),
    cit = "Map data: \ua9 OpenStreetMap contributors | Map style: \ua9 OpenTopoMap (CC-BY-SA)"
  ),
  Stadia.AlidadeSmooth = list(
    src = "Stadia.AlidadeSmooth",
    q = "https://tiles.stadiamaps.com/tiles/alidade_smooth/{z}/{x}/{y}{r}.png?api_key={apikey}",
    sub = NA,
    cit = "\ua9 Stadia Maps \ua9 OpenMapTiles \ua9 OpenStreetMap contributors"
  ),
  Stadia.AlidadeSmoothDark = list(
    src = "Stadia.AlidadeSmoothDark",
    q = "https://tiles.stadiamaps.com/tiles/alidade_smooth_dark/{z}/{x}/{y}{r}.png?api_key={apikey}",
    sub = NA,
    cit = "\ua9 Stadia Maps \ua9 OpenMapTiles \ua9 OpenStreetMap contributors"
  ),
  Stadia.OSMBright = list(
    src = "Stadia.OSMBright",
    q = "https://tiles.stadiamaps.com/tiles/osm_bright/{z}/{x}/{y}{r}.png?api_key={apikey}",
    sub = NA,
    cit = "\ua9 Stadia Maps \ua9 OpenMapTiles \ua9 OpenStreetMap contributors"
  ),
  Stadia.Outdoors = list(
    src = "Stadia.Outdoors",
    q = "https://tiles.stadiamaps.com/tiles/outdoors/{z}/{x}/{y}{r}.png?api_key={apikey}",
    sub = NA,
    cit = "\ua9 Stadia Maps \ua9 OpenMapTiles \ua9 OpenStreetMap contributors"
  ),
  Stadia.StamenToner = list(
    src = "Stadia.StamenToner",
    q = "https://tiles.stadiamaps.com/tiles/stamen_toner/{z}/{x}/{y}{r}.png?api_key={apikey}",
    sub = NA,
    cit = "\ua9 Stadia Maps \ua9 Stamen Design \ua9 OpenMapTiles \ua9 OpenStreetMap contributors"
  ),
  Stadia.StamenTonerBackground = list(
    src = "Stadia.StamenTonerBackground",
    q = "https://tiles.stadiamaps.com/tiles/stamen_toner_background/{z}/{x}/{y}{r}.png?api_key={apikey}",
    sub = NA,
    cit = "\ua9 Stadia Maps \ua9 Stamen Design \ua9 OpenMapTiles \ua9 OpenStreetMap contributors"
  ),
  Stadia.StamenTonerLines = list(
    src = "Stadia.StamenTonerLines",
    q = "https://tiles.stadiamaps.com/tiles/stamen_toner_lines/{z}/{x}/{y}{r}.png?api_key={apikey}",
    sub = NA,
    cit = "\ua9 Stadia Maps \ua9 Stamen Design \ua9 OpenMapTiles \ua9 OpenStreetMap contributors"
  ),
  Stadia.StamenTonerLabels = list(
    src = "Stadia.StamenTonerLabels",
    q = "https://tiles.stadiamaps.com/tiles/stamen_toner_labels/{z}/{x}/{y}{r}.png?api_key={apikey}",
    sub = NA,
    cit = "\ua9 Stadia Maps \ua9 Stamen Design \ua9 OpenMapTiles \ua9 OpenStreetMap contributors"
  ),
  Stadia.StamenTonerLite = list(
    src = "Stadia.StamenTonerLite",
    q = "https://tiles.stadiamaps.com/tiles/stamen_toner_lite/{z}/{x}/{y}{r}.png?api_key={apikey}",
    sub = NA,
    cit = "\ua9 Stadia Maps \ua9 Stamen Design \ua9 OpenMapTiles \ua9 OpenStreetMap contributors"
  ),
  Stadia.StamenWatercolor = list(
    src = "Stadia.StamenWatercolor",
    q = "https://tiles.stadiamaps.com/tiles/stamen_watercolor/{z}/{x}/{y}.jpg?api_key={apikey}",
    sub = NA,
    cit = "\ua9 Stadia Maps \ua9 Stamen Design \ua9 OpenStreetMap contributors"
  ),
  Stadia.StamenTerrain = list(
    src = "Stadia.StamenTerrain",
    q = "https://tiles.stadiamaps.com/tiles/stamen_terrain/{z}/{x}/{y}{r}.png?api_key={apikey}",
    sub = NA,
    cit = "\ua9 Stadia Maps \ua9 Stamen Design \ua9 OpenMapTiles \ua9 OpenStreetMap contributors"
  ),
  Stadia.StamenTerrainBackground = list(
    src = "Stadia.StamenTerrainBackground",
    q = "https://tiles.stadiamaps.com/tiles/stamen_terrain_background/{z}/{x}/{y}{r}.png?api_key={apikey}",
    sub = NA,
    cit = "\ua9 Stadia Maps \ua9 Stamen Design \ua9 OpenMapTiles \ua9 OpenStreetMap contributors"
  ),
  Stadia.StamenTerrainLabels = list(
    src = "Stadia.StamenTerrainLabels",
    q = "https://tiles.stadiamaps.com/tiles/stamen_terrain_labels/{z}/{x}/{y}{r}.png?api_key={apikey}",
    sub = NA,
    cit = "\ua9 Stadia Maps \ua9 Stamen Design \ua9 OpenMapTiles \ua9 OpenStreetMap contributors"
  ),
  Esri.WorldStreetMap = list(
    src = "Esri.WorldStreetMap",
    q = "https://server.arcgisonline.com/ArcGIS/rest/services/World_Street_Map/MapServer/tile/{z}/{y}/{x}.jpg",
    sub = NA,
    cit = "Tiles \ua9 Esri - Source: Esri, DeLorme, NAVTEQ, USGS, Intermap, iPC, NRCAN, Esri Japan, METI, Esri China (Hong Kong), Esri (Thailand), TomTom, 2012"
  ),
  Esri.WorldTopoMap = list(
    src = "Esri.WorldTopoMap",
    q = "https://server.arcgisonline.com/ArcGIS/rest/services/World_Topo_Map/MapServer/tile/{z}/{y}/{x}.jpg",
    sub = NA,
    cit = "Tiles \ua9 Esri - Esri, DeLorme, NAVTEQ, TomTom, Intermap, iPC, USGS, FAO, NPS, NRCAN, GeoBase, Kadaster NL, Ordnance Survey, Esri Japan, METI, Esri China (Hong Kong), and the GIS User Community"
  ),
  Esri.WorldImagery = list(
    src = "Esri.WorldImagery",
    q = "https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}.jpg",
    sub = NA,
    cit = "Tiles \ua9 Esri - Source: Esri, i-cubed, USDA, USGS, AEX, GeoEye, Getmapping, Aerogrid, IGN, IGP, UPR-EGP, and the GIS User Community"
  ),
  Esri.WorldTerrain = list(
    src = "Esri.WorldTerrain",
    q = "https://server.arcgisonline.com/ArcGIS/rest/services/World_Terrain_Base/MapServer/tile/{z}/{y}/{x}.jpg",
    sub = NA,
    cit = "Tiles \ua9 Esri - Source: USGS, Esri, TANA, DeLorme, and NPS"
  ),
  Esri.WorldShadedRelief = list(
    src = "Esri.WorldShadedRelief",
    q = "https://server.arcgisonline.com/ArcGIS/rest/services/World_Shaded_Relief/MapServer/tile/{z}/{y}/{x}.jpg",
    sub = NA,
    cit = "Tiles \ua9 Esri - Source: Esri"
  ),
  Esri.OceanBasemap = list(
    src = "Esri.OceanBasemap",
    q = "https://server.arcgisonline.com/ArcGIS/rest/services/Ocean/World_Ocean_Base/MapServer/tile/{z}/{y}/{x}.jpg",
    sub = NA,
    cit = "Tiles \ua9 Esri - Sources: GEBCO, NOAA, CHS, OSU, UNH, CSUMB, National Geographic, DeLorme, NAVTEQ, and Esri"
  ),
  Esri.NatGeoWorldMap = list(
    src = "Esri.NatGeoWorldMap",
    q = "https://server.arcgisonline.com/ArcGIS/rest/services/NatGeo_World_Map/MapServer/tile/{z}/{y}/{x}.jpg",
    sub = NA,
    cit = "Tiles \ua9 Esri - National Geographic, Esri, DeLorme, NAVTEQ, UNEP-WCMC, USGS, NASA, ESA, METI, NRCAN, GEBCO, NOAA, iPC"
  ),
  Esri.WorldGrayCanvas = list(
    src = "Esri.WorldGrayCanvas",
    q = "https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Base/MapServer/tile/{z}/{y}/{x}.jpg",
    sub = NA,
    cit = "Tiles \ua9 Esri - Esri, DeLorme, NAVTEQ"
  ),
  CartoDB.Positron = list(
    src = "CartoDB.Positron",
    q = "https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png",
    sub = c("a", "b", "c", "d"),
    cit = "\ua9 OpenStreetMap contributors \ua9 CARTO"
  ),
  CartoDB.PositronNoLabels = list(
    src = "CartoDB.PositronNoLabels",
    q = "https://{s}.basemaps.cartocdn.com/light_nolabels/{z}/{x}/{y}{r}.png",
    sub = c("a", "b", "c", "d"),
    cit = "\ua9 OpenStreetMap contributors \ua9 CARTO"
  ),
  CartoDB.PositronOnlyLabels = list(
    src = "CartoDB.PositronOnlyLabels",
    q = "https://{s}.basemaps.cartocdn.com/light_only_labels/{z}/{x}/{y}{r}.png",
    sub = c("a", "b", "c", "d"),
    cit = "\ua9 OpenStreetMap contributors \ua9 CARTO"
  ),
  CartoDB.DarkMatter = list(
    src = "CartoDB.DarkMatter",
    q = "https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png",
    sub = c("a", "b", "c", "d"),
    cit = "\ua9 OpenStreetMap contributors \ua9 CARTO"
  ),
  CartoDB.DarkMatterNoLabels = list(
    src = "CartoDB.DarkMatterNoLabels",
    q = "https://{s}.basemaps.cartocdn.com/dark_nolabels/{z}/{x}/{y}{r}.png",
    sub = c("a", "b", "c", "d"),
    cit = "\ua9 OpenStreetMap contributors \ua9 CARTO"
  ),
  CartoDB.DarkMatterOnlyLabels = list(
    src = "CartoDB.DarkMatterOnlyLabels",
    q = "https://{s}.basemaps.cartocdn.com/dark_only_labels/{z}/{x}/{y}{r}.png",
    sub = c("a", "b", "c", "d"),
    cit = "\ua9 OpenStreetMap contributors \ua9 CARTO"
  ),
  CartoDB.Voyager = list(
    src = "CartoDB.Voyager",
    q = "https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png",
    sub = c("a", "b", "c", "d"),
    cit = "\ua9 OpenStreetMap contributors \ua9 CARTO"
  ),
  CartoDB.VoyagerNoLabels = list(
    src = "CartoDB.VoyagerNoLabels",
    q = "https://{s}.basemaps.cartocdn.com/rastertiles/voyager_nolabels/{z}/{x}/{y}{r}.png",
    sub = c("a", "b", "c", "d"),
    cit = "\ua9 OpenStreetMap contributors \ua9 CARTO"
  ),
  CartoDB.VoyagerOnlyLabels = list(
    src = "CartoDB.VoyagerOnlyLabels",
    q = "https://{s}.basemaps.cartocdn.com/rastertiles/voyager_only_labels/{z}/{x}/{y}{r}.png",
    sub = c("a", "b", "c", "d"),
    cit = "\ua9 OpenStreetMap contributors \ua9 CARTO"
  ),
  Thunderforest.OpenCycleMap = list(
    src = "Thunderforest.OpenCycleMap",
    q = "https://tile.thunderforest.com/cycle/{z}/{x}/{y}.png?apikey={apikey}",
    sub = NA,
    cit = "\ua9 Thunderforest \ua9 OpenStreetMap contributors"
  ),
  Thunderforest.Transport = list(
    src = "Thunderforest.Transport",
    q = "https://tile.thunderforest.com/transport/{z}/{x}/{y}.png?apikey={apikey}",
    sub = NA,
    cit = "\ua9 Thunderforest \ua9 OpenStreetMap contributors"
  ),
  Thunderforest.TransportDark = list(
    src = "Thunderforest.TransportDark",
    q = "https://tile.thunderforest.com/transport-dark/{z}/{x}/{y}.png?apikey={apikey}",
    sub = NA,
    cit = "\ua9 Thunderforest \ua9 OpenStreetMap contributors"
  ),
  Thunderforest.SpinalMap = list(
    src = "Thunderforest.SpinalMap",
    q = "https://tile.thunderforest.com/spinal-map/{z}/{x}/{y}.png?apikey={apikey}",
    sub = NA,
    cit = "\ua9 Thunderforest \ua9 OpenStreetMap contributors"
  ),
  Thunderforest.Landscape = list(
    src = "Thunderforest.Landscape",
    q = "https://tile.thunderforest.com/landscape/{z}/{x}/{y}.png?apikey={apikey}",
    sub = NA,
    cit = "\ua9 Thunderforest \ua9 OpenStreetMap contributors"
  ),
  Thunderforest.Outdoors = list(
    src = "Thunderforest.Outdoors",
    q = "https://tile.thunderforest.com/outdoors/{z}/{x}/{y}.png?apikey={apikey}",
    sub = NA,
    cit = "\ua9 Thunderforest \ua9 OpenStreetMap contributors"
  ),
  Thunderforest.Pioneer = list(
    src = "Thunderforest.Pioneer",
    q = "https://tile.thunderforest.com/pioneer/{z}/{x}/{y}.png?apikey={apikey}",
    sub = NA,
    cit = "\ua9 Thunderforest \ua9 OpenStreetMap contributors"
  ),
  Thunderforest.MobileAtlas = list(
    src = "Thunderforest.MobileAtlas",
    q = "https://tile.thunderforest.com/mobile-atlas/{z}/{x}/{y}.png?apikey={apikey}",
    sub = NA,
    cit = "\ua9 Thunderforest \ua9 OpenStreetMap contributors"
  ),
  Thunderforest.Neighbourhood = list(
    src = "Thunderforest.Neighbourhood",
    q = "https://tile.thunderforest.com/neighbourhood/{z}/{x}/{y}.png?apikey={apikey}",
    sub = NA,
    cit = "\ua9 Thunderforest \ua9 OpenStreetMap contributors"
  )
)
