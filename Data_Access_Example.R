## Install required libraries
#install.packages("jsonlite", repos="http://cran.r-project.org")
#install.packages('curl')

## Load libraries
library (jsonlite)

## Call data services and generate data frame
# Example shown gets all characteristics for one site: Long Pond (MDI)
targetURL <- "http://irmadevservices.nps.gov/WaterQualityDataServices/OData/Data?$expand=Characteristic,Site,Date&$filter=Site/SiteName eq 'Long Pond (MDI)'"
targetURL <- gsub(" ", "%20", targetURL)
#targetURL <- "http://irmadevservices.nps.gov/WaterQualityDataServices/OData/Data?$expand=Characteristic,Site,Date&$filter=Site/SiteName%20eq%20%27Long%20Pond%20(MDI)%27"

# Create object data frame (plotdf) that contains the requested data
plotdf <- try(fromJSON(targetURL))
if (inherits(plotdf,'try-error')) {
  Head <- 'fromJSON error'
  return(list(Flag='fromJSON error',
              Query=targetURL,
              Messages=message()
  ))
} else {

# Print data frame
print(plotdf)
}


