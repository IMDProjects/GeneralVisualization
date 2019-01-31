## Install required libraries
#install.packages("jsonlite", repos="http://cran.r-project.org")
#install.packages('curl')

## Load libraries
library (jsonlite)

## DATA QUERY SECTION ###
## Call data services and generate data frame
# Example shown gets all characteristics for one site: Long Pond (MDI)
# Construct data request URL
targetURL <- "http://irmadevservices.nps.gov/WaterQualityDataServices/OData/Data?$expand=Characteristic,Site,Date&$filter=Site/SiteName eq 'Long Pond (MDI)'"
# Replace spaces with escape character
targetURL <- gsub(" ", "%20", targetURL)

# Create data frame (plotdf) that contains the requested data
plotdf <- try(fromJSON(targetURL, flatten=TRUE))[[2]]
if (inherits(plotdf,'try-error')) {
  Head <- 'fromJSON error'
  return(list(Flag='fromJSON error',
              Query=targetURL,
              Messages=message()
  ))
} else {

### DATA FRAME SECTION ###
# Print data frame
print(plotdf)
}


