## Code for downloading NETN data and plotting box plots with scatter plot overlay
# Brian R. Mitchell

# Metadata for the data services: http://irmadevservices.nps.gov/WaterQualityDataServices/Odata/$metadata
# Use the link above to find available fields for download.

# March 24, 2015 Revision
# This version streamlines the data call (downloads only data for a specific site and characteristic)
# and removes Provisional and QC data. It also incorporates some grouping options for when there
# are multiple data points on a given date, and plots the location of any data flags.

## Install required libraries
install.packages("jsonlite", repos="http://cran.r-project.org")

## Load libraries
library(jsonlite)    # For data services

## User Inputs; these should be supplied through web interface / R-Shiny
# Use 4-letter park abbreviation and full display characteristic name
ParkSelection <- "MIMA"
CharSelection <- "pH"
MinDateBox <- "1980-01-01"
MaxDateBox <- "2012-12-31"
MinDateScatter <- "2013-01-01"
MaxDateScatter <- "2020-12-31"
MinDepth <- 0.0
MaxDepth <- 0.9

## Network-defined inputs; these should be set by a network scientist
# Grouping option for multiple data points within a day: None, Median, Average
GroupingOption <- "Median"

## Call data services and generate data frame
# Use a series of strings (S1-S4) to make this easier to follow, then concatenate
# Note that %20 is the html code for a space (" ")
# Root URL of data services:
S1 <- "http://irmadevservices.nps.gov/WaterQualityDataServices/Odata/Data?"
# Expand related entities ('tables') to return from the data service:
S2 <- "$expand=Characteristic,Site,Date&"
# Select the fields to use in querying:
S3 <- "$select=Site/SiteName,Site/ParkCode,Site/ParkName,Site/NetworkCode,Characteristic/CharacteristicNameDisplay,Characteristic/CharacteristicUnits,CharacteristicValue,Replicate,Public,CharacteristicLabFlag,CharacteristicOtherFlag,Date/Date1,CharacteristicDepth"
# Filter (query) to subset data to return:
# Get all data for the selected park and characteristic. 
S4 <- paste0("&$filter=Site/ParkCode eq '",ParkSelection,"' and Characteristic/CharacteristicNameDisplay eq '",CharSelection,"'")
# Concatenate the strings. 
targetURL = paste0(S1,S2,S3,S4)
# Encode the URL by replacing spaces with %20
targetURL = gsub(" ", "%20", targetURL)

# Create object data frame (plotdf) that contains the requested data
# The second element contains the data required for the plot. (The first contains the URL used.)
myResult <- fromJSON(targetURL, flatten = TRUE)
plotdf <- myResult[[2]]

## Clean up data and assign readable names
# Rename columns
names(plotdf)[1] <- "Value"
names(plotdf)[2] <- "Replicate"
names(plotdf)[3] <- "Public"
names(plotdf)[4] <- "LabFlag"
names(plotdf)[5] <- "OtherFlag"
names(plotdf)[6] <- "Depth"
names(plotdf)[7] <- "CharName"
names(plotdf)[8] <- "Units"
names(plotdf)[9] <- "Site"
names(plotdf)[10] <- "ParkCode"
names(plotdf)[11] <- "Park"
names(plotdf)[12] <- "Network"
names(plotdf)[13] <- "Date"

# Convert text to dates and numbers as needed
plotdf$Value <- as.numeric(plotdf$Value)
plotdf$Replicate <- as.numeric(plotdf$Replicate)
plotdf$Depth <- as.numeric(plotdf$Depth)
plotdf$Date <- as.Date(plotdf$Date)

# Remove provisional and QC data. There's probably a more elegant way to do this.
plotdf <- subset(plotdf, OtherFlag != "MQ")
plotdf <- subset(plotdf, OtherFlag != "P")
plotdf <- subset(plotdf, OtherFlag != "PQ")
plotdf <- subset(plotdf, OtherFlag != "Q")

# Apply grouping option
if(GroupingOption == "Median") {
  plotdf <- aggregate(x = plotdf[c("Value","Replicate","Depth")], by=list(Date = 
    plotdf$Date, Site = plotdf$Site, Public = plotdf$Public, LabFlag = 
    plotdf$LabFlag, OtherFlag = plotdf$OtherFlag, CharName = plotdf$CharName, 
    Units = plotdf$Units, ParkCode = plotdf$ParkCode, Park = plotdf$Park, 
    Network = plotdf$Network), FUN = median)
    }
if(GroupingOption == "Mean") {
  plotdf <- aggregate(x = plotdf[c("Value","Replicate","Depth")], by=list(Date = 
    plotdf$Date, Site = plotdf$Site, Public = plotdf$Public, LabFlag = 
    plotdf$LabFlag, OtherFlag = plotdf$OtherFlag, CharName = plotdf$CharName, 
    Units = plotdf$Units, ParkCode = plotdf$ParkCode, Park = plotdf$Park, 
    Network = plotdf$Network), FUN = mean)
    }

# Sort by site name
plotdf <- plotdf[order(plotdf$Site),]
    
## Generate site list and numeric values for each Site in SiteList
SiteList <- unique(plotdf$Site)
SiteIndex <- c(1:length(SiteList))

## Get some basic info for the plots
# Get units of the chosen characteristic
UnitLab <- plotdf[1,"Units"]
ParkName <- plotdf[1,"Park"]

## Begin Box plot with scatter overlay 
# Set x and y axis limits
xmin <- 0.5
xmax <- length(SiteList)+0.5
ymin <- min(plotdf$Value)
ymax <- max(plotdf$Value)

# if ymax is less than 3, labels start to drift off of bottom of plot
ymax <- ifelse (ymax < 3, 3, ymax)
# Need to add the SiteIndex to the data frame, so that the plots can use it
plotdf$SiteIndex <- 0
for (n in 1:length(SiteList)) {
    # First index (,14) is the SiteIndex; second index (,9) is the Site
    plotdf[,"SiteIndex"][which(plotdf[,"Site"]==SiteList[n])]<-n
}

## Create the data frames for the plots.
# plotdf1 is the data frame for the box plot
plotdf1 <- subset(plotdf, Date >= MinDateBox & Date <= MaxDateBox & Depth >= 
  MinDepth & Depth <= MaxDepth)
# plotdf2 is the data frame for the scatter plot
plotdf2 <- subset(plotdf, Date >= MinDateScatter & Date <= MaxDateScatter & 
  Depth >= MinDepth & Depth <= MaxDepth)
# plotdf3 is the data frame for any flagged values
plotdf3 <- subset(plotdf, LabFlag != "" | OtherFlag != "")

## Generate the plot
# Inner and outer margins
par(mar= c(6, 4, 4, 2) + 0.1)
par(oma= c(4, 0, 0, 0))

# Make the box plot
boxplot(Value~SiteIndex, data=plotdf1, main=c(ParkName,CharSelection), xaxt="n", 
  ylab=UnitLab, ylim=c(ymin,ymax))

# Make custom axis with labels at 45 degrees
text(1:length(SiteList), par("usr")[3] - 0.25, srt = 45, adj = 1, labels=SiteList, 
  cex=0.75, xpd = TRUE)

# Make the scatter plot
par(new=T)
plot(plotdf2$SiteIndex, plotdf2$Value, xlab = "", ylab = "", xlim=c(xmin,xmax), 
  ylim=c(ymin,ymax), axes = F, type='p', pch=16,col=3)

# Make the scatter plot where flagged data are labeled
text(plotdf3$SiteIndex, plotdf3$Value, labels=paste0("        ",plotdf$LabFlag,
  plotdf$OtherFlag), cex = 0.75)

mtext(paste("    Filled circles are data from ",MinDateScatter," to ",MaxDateScatter),
  cex=0.75, line=0, side=SOUTH<-1, adj=0, outer=TRUE)
mtext(paste("    Box plots are data from ", MinDateBox, " to ", MaxDateBox),cex=0.75, 
  line=1, side=SOUTH<-1, adj=0, outer=TRUE)  
mtext(paste("    The data aggregation option if there are multiple data points",
  "within a day is: ", GroupingOption),cex=0.75, line=2, side=SOUTH<-1, adj=0,
  outer=TRUE)
mtext(paste("    Any text characters appearing on the plot are data flags, such",
  "as modeled, estimated, or qualified data"),cex=0.75, line=3, side=SOUTH<-1, adj=0,
  outer=TRUE)  
par(new=F)





