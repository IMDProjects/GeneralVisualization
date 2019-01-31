# Snippet for hydro station map

# Check for packages (code structure from Lee McCoy - DM Training 2018)
pkgList <- c("RODBC",
             "dplyr",
             "htmlwidgets",
             "leaflet")


toInstall <- pkgList %in% installed.packages() #check which packages are installed
if (length(pkgList[!toInstall]) > 0) install.packages(pkgList[!toInstall],dep=TRUE) #install packages that are missing
lapply(pkgList, library, character.only = TRUE, quietly=TRUE) #load packages

# Ensure latest leaflet
#if ("leaflet" %in% pkgList) {
#  remove.packages("leaflet")
#  install.packages("leaflet", repos = "https://cran.rstudio.com/", quiet=TRUE)
#}

# Library initialization
library(leaflet)
library(htmlwidgets)
library(htmltools)
library(RODBC)

# Variables
dbInstance <- "INPNISCVDBNRSST\\IMDGIS"
dbName <- "Hydro_Stage"
dbTable <- "dbo.Station"
connString <- paste0("driver={SQL Server};server=",dbInstance,";database=",dbName,";uid=Report_Data_Reader;pwd=ReportDataUser")
unitSQL <- "select distinct UnitCode from dbo.Station order by UnitCode"
stationSnippet <- "select distinct SiteNumber, StationName, Longitude_dd, Latitude_dd, UnitCode from dbo.Station order by UnitCode, StationName"

tileURL <- 'http://api.mapbox.com/v4/nps.397cfb9a,nps.3cf3d4ab,nps.b0add3e6/{z}/{x}/{y}.png?access_token=pk.eyJ1IjoibnBzIiwiYSI6IkdfeS1OY1UifQ.K8Qn5ojTw4RV1GwBlsci-Q&secure=1'

defaultMarker <- makeAwesomeIcon(
  icon = 'map-pin',
  library = 'fa',
  markerColor = 'red'#iconColor = 'black', 
)

# Get the UnitCodes for stations
dbConn <- odbcDriverConnect(connString)

unitCodes <- sqlQuery(dbConn, unitSQL)

# Get station details
stationInfo <- sqlQuery(dbConn, stationSnippet)

# Filter stations for selected park
parkCode <- "GRTE"
parkStations <- stationInfo[which(stationInfo$UnitCode == parkCode), ]

# Set up the NPS ParkTiles basemap
# Use the mapbox Javascript library (via the htmltools plugin capability)
# NPS has an access token for the ParkTiles tileset
# Plugin registration code (example from https://gist.github.com/jcheng5/c084a59717f18e947a17955007dc5f92)
mbPlugin <- htmlDependency("mapbox", "3.1.1",
                             src = c(href = "https://api.mapbox.com/mapbox.js/v3.1.1/"),
                             #src = normalizePath(getwd()),
                             script = "mapbox.js",
                             stylesheet = "https://api.mapbox.com/mapbox.js/v3.1.1/mapbox.css"
)

# Add the htmlDependency plugin object to the map. 
# This ensures that however or whenever the map
# gets rendered, the plugin will be loaded into the browser.
registerPlugin <- function(map, plugin) {
  map$dependencies <- c(map$dependencies, list(plugin))
  map
}

# Initialize the map; by default, it will zoom to the extent of all points 
# in the parkStations data frame
# The ParkTiles basemap is added by executing mapbox Javascript(wrapped in the addTiles function! 
leaflet() %>% addTiles(urlTemplate = tileURL) %>% addAwesomeMarkers(lng=parkStations$Longitude_dd, lat=parkStations$Latitude_dd, icon=defaultMarker, label=parkStations$StationName)
leaflet() %>% 
  #addTiles() %>%
  #setView(-120, 36, zoom = 7) %>%
  # Register ESRI plugin on this map instance
  # https://api.mapbox.com/v4/nps.397cfb9a,nps.3cf3d4ab,nps.b0add3e6
  # https://b.tiles.mapbox.com/v4/397cfb9a,nps.3cf3d4ab,nps.b0add3e6/
  # L.tileLayer('http://{s}.tile.osm.org/{z}/{x}/{y}.png?{foo}').addTo(this);
  # L.tileLayer('b.tiles.mapbox.com/v4/397cfb9a,nps.3cf3d4ab,nps.b0add3e6/{z}/{x}/{y}.png')
  # NPS ParkTiles via MapBox: https://api.mapbox.com/v4/nps.397cfb9a,nps.3cf3d4ab,nps.b0add3e6.json?access_token=pk.eyJ1IjoibnBzIiwiYSI6IkdfeS1OY1UifQ.K8Qn5ojTw4RV1GwBlsci-Q&secure=1
  registerPlugin(mbPlugin) %>%
  onRender("
    function(el, x) {
L.tileLayer('http://api.mapbox.com/v4/nps.397cfb9a,nps.3cf3d4ab,nps.b0add3e6/{z}/{x}/{y}.png?access_token=pk.eyJ1IjoibnBzIiwiYSI6IkdfeS1OY1UifQ.K8Qn5ojTw4RV1GwBlsci-Q&secure=1').addTo(this);
}") %>% addAwesomeMarkers(lng=parkStations$Longitude_dd, lat=parkStations$Latitude_dd, icon=defaultMarker, label=parkStations$StationName)
 


