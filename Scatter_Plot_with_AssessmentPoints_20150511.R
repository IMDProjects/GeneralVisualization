# Brian R. Mitchell

# Metadata for the data services: http://irmadevservices.nps.gov/WaterQualityDataServices/Odata/$metadata
# Use the link above to find available fields for download.

# March 24, 2015 Revision
# This version streamlines the data call (downloads only data for a specific site and characteristic)
# and removes Provisional and QC data. It also incorporates some grouping options for when there
# are multiple data points on a given date, and plots the location of any data flags.

## Install required libraries
#install.packages("jsonlite", repos="http://cran.r-project.org")

## Load libraries
library(jsonlite)    # For data services
library(ggplot2)     # For scatter plot with overlay

## Call data services and generate data frame
# Root URL of data services:
targetURL <- paste0( "http://irmadevservices.nps.gov/WaterQualityDataServices/OData/Data?" );

# Expand related entities ('tables') to return from the data service:
targetURL <- paste0( targetURL, "&$expand=Characteristic,Site,Date" );

# Select the fields to use in querying:
targetURL <- paste0( targetURL, "&$select=Site/SITE_ID,Site/SiteName,Site/SiteCode,Site/ParkName,Characteristic/CharacteristicNameDisplay,Characteristic/CharacteristicUnits,CharacteristicValue,Date/DATE_ID" );

# Filter (query) to subset data to return:
targetURL <- paste0( targetURL, "&$filter=Characteristic/CharacteristicName eq 'Dissolved oxygen (DO)' and Site/SiteName eq 'West Primrose Brook' and (Date/DATE_ID gt 20100101 and Date/DATE_ID lt 20121231)" );

# Add an order by clause
targetURL <- paste0( targetURL, "&$orderby=Date/DATE_ID" );
# Encode the URL by replacing spaces with %20
targetURL = gsub(" ", "%20", targetURL)
print (targetURL)

#URL to request assessment point values for site, characteristic, and level
assessURL <- paste0( "http://irmadevservices.nps.gov/WaterQualityDataServices/OData/AssessmentPointsBySiteAndChars?" );
assessURL <- paste0(assessURL, "&$filter=SiteCode eq 'MORR_SC00' and CharacteristicKey eq 43 and Level eq 1")
# Old example using SITE_ID and CHARACTERISTIC_ID
#assessURL <- paste0(assessURL,  "&$filter=SITE_ID eq 184 and CHARACTERISTIC_ID eq 44 and Level eq 1" );

assessURL = gsub(" ", "%20", assessURL)
print (assessURL)

# Create object data frames (plotdf and assessdf) that contains the requested data
# The second element contains the data required for the plot. (The first contains the URL used.)
plotdf <<- fromJSON( targetURL, flatten = TRUE )[[ 2 ]]
assessdf <<- fromJSON( assessURL, flatten = TRUE )[[ 2 ]]

## Clean up data and assign readable names
# Rename columns
plotdf$Date <- as.Date( plotdf$Date.Date1 )
plotdf$CharacteristicName <- plotdf$Characteristic.CharacteristicNameDisplay
plotdf$CharacteristicValue <- as.numeric( plotdf$CharacteristicValue )
plotdf$CharacteristicUnits <- plotdf$CharacteristicUnits
plotdf$SiteName <- plotdf$Site.SiteName
plotdf$SiteCode <- plotdf$Site.SiteCode
plotdf$ParkName <- plotdf$Site.ParkName

# Get assessment points from assessment data frame
# NOTE: Adding the upper bound as the top of the data range may not be valid
upperPoint <- assessdf$UpperAssessmentPoint
if(is.na(assessdf$UpperAssessmentPoint)) {
  upperPoint <- ceiling(max(plotdf$CharacteristicValue))
} 
assessBounds <- c(assessdf$LowerAssessmentPoint,upperPoint)

## Begin scatter plot using gglot
thisPlot <- ggplot( 
  data = plotdf, 
  aes( x = Date.DATE_ID, y = CharacteristicValue ) 
) + 

  ##### BEGIN OVERALL THEME CHANGE #####
theme_bw() +
  ##### BEGIN OVERALL THEME CHANGE #####

##### BEGIN SCATTER POINTS ( TIME / CHARACTERISTIC VALUE ) #####
geom_point(
  colour = "blue", 
  size = 3, 
  alpha= 0.75, 
  shape = 20
) + 
  ##### END SCATTER POINTS ( TIME / CHARACTERISTIC VALUE ) #####
geom_line(aes(y=assessdf$LowerAssessmentPoint),size=1.25, label="Lower", color="green") +
geom_line(aes(y=upperPoint),size=1.25, color="green") +

##### BEGIN LEGENDS #####
labs(
  title = paste( plotdf$ParkName[1], "\n", plotdf$SiteName[1], " [", plotdf$SiteCode[1], "]", sep="" ),
  x = "Year Range", 
  y = paste( plotdf$CharacteristicName[1], plotdf$CharacteristicUnits[1], sep="\n" )
) 
#+
  ##### END LEGENDS #####
##### END GGPLOT SCATTER PLOT #####

##### BEGIN PLOT TO RETURN FROM FUNCTION #####
thisPlot
##### END PLOT TO RETURN FROM FUNCTION #####
