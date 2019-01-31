# Snippet for hydro station map

# Check for packages (code structure from Lee McCoy - DM Training 2018)
pkgList <- c("RODBC",
             "dplyr",
             "rgdal",
             "jsonlite",
             "leaflet")  # leaflet 2.0.2+

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
library(RODBC)
# If want AOA polygons:
library(jsonlite)
library(rgdal)

# Variables
dbInstance <- "INPNISCVDBNRSST\\IMDGIS"
dbName <- "Hydro_Stage"
dbTable <- "dbo.Station"
connString <- paste0("driver={SQL Server};server=",dbInstance,";database=",dbName,";uid=Report_Data_Reader;pwd=ReportDataUser")
unitSQL <- "select distinct UnitCode from dbo.Station order by UnitCode"
stationSnippet <- "select distinct SiteNumber, StationName, Longitude_dd, Latitude_dd, UnitCode from dbo.Station order by UnitCode, StationName"

# NPS ParkTiles via MapBox: https://api.mapbox.com/v4/nps.397cfb9a,nps.3cf3d4ab,nps.b0add3e6.json?access_token=pk.eyJ1IjoibnBzIiwiYSI6IkdfeS1OY1UifQ.K8Qn5ojTw4RV1GwBlsci-Q&secure=1
tileURL <- 'http://api.mapbox.com/v4/nps.397cfb9a,nps.3cf3d4ab,nps.b0add3e6/{z}/{x}/{y}.png?access_token=pk.eyJ1IjoibnBzIiwiYSI6IkdfeS1OY1UifQ.K8Qn5ojTw4RV1GwBlsci-Q&secure=1'

# awesomeIcons plugin accesses three comprehensive icon sets. 
defaultMarker <- makeAwesomeIcon(
  icon = 'map-pin',
  library = 'fa',
  markerColor = 'red' 
)

# Get the UnitCodes for stations
dbConn <- odbcDriverConnect(connString)

unitCodes <- sqlQuery(dbConn, unitSQL)

# Get station details
stationInfo <- sqlQuery(dbConn, stationSnippet)

# Filter stations for selected park
parkCode <- "ROMO"
parkStations <- stationInfo[which(stationInfo$UnitCode == parkCode), ]

# Optional: get AOA polygon feature
getAOAFeature <- function(unitCode, aoaExtent="km30") {
  tempOutput <- "temp.geojson"
  featureServiceURLs <-
    list("park" = "https://irmaservices.nps.gov/arcgis/rest/services/LandscapeDynamics/LandscapeDynamics_AOA_WebMercator/FeatureServer/0",
         "km3" = "https://irmaservices.nps.gov/arcgis/rest/services/LandscapeDynamics/LandscapeDynamics_AOA_WebMercator/FeatureServer/1",
         "km30" = "https://irmaservices.nps.gov/arcgis/rest/services/LandscapeDynamics/LandscapeDynamics_AOA_WebMercator/FeatureServer/2"
    )
  featureServicePathInfo <- "query?where=UNIT_CODE+%3D+%27XXXX%27&objectIds=&time=&geometry=&geometryType=esriGeometryEnvelope&inSR=&spatialRel=esriSpatialRelIntersects&distance=&units=esriSRUnit_Meter&relationParam=&outFields=*&returnGeometry=true&maxAllowableOffset=&geometryPrecision=&outSR=4269&gdbVersion=&returnDistinctValues=false&returnIdsOnly=false&returnCountOnly=false&returnExtentOnly=false&orderByFields=&groupByFieldsForStatistics=&outStatistics=&returnZ=false&returnM=false&multipatchOption=&resultOffset=&resultRecordCount=&f=geojson"
  
  featureServiceRequest <- paste(as.character(featureServiceURLs[featureServiceURLs = aoaExtent]), gsub("XXXX", unitCode, featureServicePathInfo), sep = "/" )
  print(featureServiceRequest)
  geoJSONFeature <- fromJSON(featureServiceRequest)
  # Have to save to temp file
  jsonFeature <- download.file(featureServiceRequest, tempOutput, mode = "w")
  # For rgdal 1.2+, layer (format) does not need to be specified
  featurePoly <- readOGR(dsn = tempOutput)
  #featurePoly <- readOGR(dsn = tempOutput, layer = "OGRGeoJSON")
  return(featurePoly)
}

aoaPoly <- getAOAFeature(parkCode)

# Initialize the map; by default, it will zoom to the extent of all points 
# in the parkStations data frame
# The ParkTiles basemap is added by executing mapbox Javascript (wrapped in the addTiles function! 
# Also can be done via explicit calls to the mapbox CDN via an htmlDependency plugin - see previous version for example 
leaflet() %>%
  addTiles(urlTemplate = tileURL) %>%
  addAwesomeMarkers(lng=parkStations$Longitude_dd, lat=parkStations$Latitude_dd, 
                    icon=defaultMarker, label=parkStations$StationName)  %>%
  fitBounds(lng1 = min(parkStations$Longitude_dd) + 0.02,
               lat1 = min(parkStations$Latitude_dd) - 0.02,
               lng2 = max(parkStations$Longitude_dd) - 0.02,
               lat2 = max(parkStations$Latitude_dd) + 0.02
               ) %>%
  addPolygons(data = aoaPoly, fillOpacity = 0.0, color = "gray", weight = 2)


