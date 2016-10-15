############ global.R #############
#### All processing that could be done once goes here, because processing in server.R is done everytime the app loads, and drastically slows it down
#### Objects created here are also available to both the ui.R script and the server.R script

library(googlesheets)
library(dplyr)

####DECLARE ANY FUNCTIONS FOR APPJ
#Get trend timeseries for plotting
getTrendSeries <- function(timeSeries, startTs=c(2005, 1)){
	ts(as.data.frame(lapply(timeSeries, function(timeSeries){
		fit <- lm(timeSeries ~ c(1:length(timeSeries)))
		seq(from=coef(fit)[1], by=coef(fit)[2], length.out=length(timeSeries))
	})),frequency=12, start=startTs)
}

##########SETUP Google Sheets
## prepare the OAuth token and set up the target sheet:
##  - do this interactively
##  - do this EXACTLY ONCE

# shiny_token <- gs_auth() # authenticate w/ your desired Google identity here
# saveRDS(shiny_token, "shiny_app_token.rds")

## if you version control your app, don't forget to ignore the token file!
# e.g., put it into .gitignore

getFromGoogleSheets <- F

if(getFromGoogleSheets){

  ##Read in data from google sheets
  gs_auth(token = "shiny_app_token.rds")

  allDataSheet <- gs_title("allData")

  energyData <- as.data.frame(allDataSheet %>% gs_read(ws = "Energy"))
  pcwaste <- as.data.frame(allDataSheet %>% gs_read(ws = "PerCapita"))
  waste <- as.data.frame(allDataSheet %>% gs_read(ws = "Waste"))
  leedBuildings <- as.data.frame(allDataSheet %>% gs_read(ws = "Leed"))
  edibleLandscaping <- as.data.frame(allDataSheet %>% gs_read(ws = "EdibleLandscaping"))

} else {

  energyData <- read.csv(file = "./data/energyData.csv", stringsAsFactors = F)
  pcwaste <- read.csv(file = "./data/pcwaste.csv", stringsAsFactors = F)
  waste <- read.csv(file = "./data/waste.csv", stringsAsFactors = F)
  leedBuildings <- read.csv(file = "./data/leedBuildings.csv", stringsAsFactors = F)
  edibleLandscaping <- read.csv(file = "./data/edibleLandscaping.csv", stringsAsFactors = F)
}

#Process energy data, convert to time series, convert dkt to kwh, calculate energy trends
energyTimeSeries <- ts(energyData[,-c(1,2,3,6,9)], frequency=12, start=c(2005, 1)) #Convert to time series
energyTimeSeries[,2] <- round(energyTimeSeries[,2]/0.0034129563407) #Convert DKT to KWH
colnames(energyTimeSeries) <- c("elecKWH", "gasKWH", "elecExpend", "gasExpend") #

waterSewerTimeSeries <- ts(energyData[,c(6,9)], frequency=12, start=c(2005, 1)) #Convert to time series
colnames(waterSewerTimeSeries) <- c("waterMCF", "waterSewerExpend") #

energyTimeSeries <- ts(energyData[,-c(1,2,3,6,9,10,11)], frequency=12, start=c(2005, 1)) #Convert to time series
energyTimeSeries[,2] <- round(energyTimeSeries[,2]/0.0034129563407) #Convert DKT to KWH
colnames(energyTimeSeries) <- c("elecKWH", "gasKWH", "elecExpend", "gasExpend") #


energyTrends <- getTrendSeries(energyTimeSeries, startTs=c(2005, 1))
pcEnergy <- round(aggregate(energyTimeSeries, nfrequency=1, FUN=sum)/pcwaste[5:10,2],2)

energyTarget <- ts(aggregate(energyTimeSeries, nfrequency=1, FUN=mean)*1.0025, frequency=1, start=c(2011, 1))

######  Waste Data  #####
waste$recycle <- as.numeric(format(round(waste$recycle/2000, 2), nsmall=2))
waste$landfill <-as.numeric(format(round(waste$landfill/2000, 2), nsmall=2))
waste$compost <- as.numeric(format(round(waste$compost/2000, 2), nsmall=2))
wastetimeseries <- ts(waste[,-c(1, 2)], frequency=12, start=c(2006, 1))

### Per capita waste data
pcwaste$FY <- as.numeric(pcwaste$FY)
pcwaste$pcrecycle <- as.numeric(format(round(pcwaste$recycling/pcwaste$fallpop, 2), nsmall=2))
pcwaste$pcwaste <- as.numeric(format(round(pcwaste$waste/pcwaste$fallpop, 2), nsmall=2))
pcwaste$pccompost <- as.numeric(format(round(pcwaste$compost/pcwaste$fallpop, 2), nsmall=2))

wastefit <- getTrendSeries(wastetimeseries[,2], startTs = c(2006, 1))
