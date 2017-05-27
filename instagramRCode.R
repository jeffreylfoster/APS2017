########################
# Jeffrey L. Foster's code for bulk scraping Twitter feeds from users
# This script runs in 2 steps. First, it loads the variables and packages and connects to Instagram
# Second, it conducts the image and user scrapes in bulk.
# This code heavily relies on the instaR package. 
# be sure to cite the instaR package as below:
# Pablo Barbera, Tiago Dantas and Jonne Guyt (2016). instaR: Access to Instagram API via R. R package version 0.2.4.
# https://CRAN.R-project.org/package=instaR
# contact jeff.foster@westernsydney.edu.au for questions regarding this script
#
# IMPORTANT: Instagram's API has recently required approval for access. I am unfamiliar with the new process for access.
#
# This script requires a Instagram API Dev account with a consumer key and consumer secrety
# The process now requires approval and may require a lot of work to receive
########################

############################################################################################################
#STEP 1
#Loads the packages and sets your variables
#This stage needs your information form the Instagram API Dev account
############################################################################################################

require(instaR)
library(instaR)
app_id <- ("xxxxxx") # <---- From Instagram API account
app_secret <- ("xxxxx") # <---- From Instagram API account
token <- instaOAuth(app_id, app_secret)


#######################################
############ Step 2 below ############
#######################################
locations <- c("Apostles","Kakadu","KingsCanyon","PortArthur","Rottnest")
latits <- c(-38.664251,-13.311555,-24.234183,-43.145940,-32.003816)
longits <- c(143.103907,132.781102,131.553757,147.849481,115.509809)

#Set the latest date in the search
theDate <- as.Date("2016-05-08")
#set how many days before theDate to start (useful if following up form an incomplete search due to ratelimit)
daysStart <- 38
#set how many days before that date we want to include in the search
daysBack <- 250

#Setup rate limit with the numder of days to search before pausing (ratelimitMax; set to 0 to disable)
#Also setup how long it sleeps for (in seconds) using sleepTime
sleepTime <- 900
ratelimitCounter <- 0
ratelimitMax <- 30
#skip how many days between? Set to 0 for all days
DaysSkip <- 0

#for every location, do it all:
for (currentLocation in 1:length(locations)){
  
#for every day we are scraping:
for (newDate in daysStart:daysBack){
  #Do the day skipping
  newDate <- newDate + DaysSkip
  #If there's an error, catch it, drop the day, and spit out the error before continuing on
  tryCatch({
    #The actual image scrape and initial image data
    #Uluru - lat=-25.3454, lng=131.0349
    #Green Island - lat=-16.759, lng=145.972
    #Freycinet National Park (Tassie) - lat=-42.1453863, lng=148.2890264
    #Three Sisters - -33.7319518,150.3117795
    #Rottnest island - that's about the centre of the island - the whole island is about 6-8 kms long 
    #-32.003816, 115.509809 
    #Kings Canyon - not sure what actually constitutes the canyon but from eyeballing it and looking at helicopter images, that seems to be about it 
    #-24.234183, 131.553757
    #Kakadu, Twin Falls 
    #-13.311555, 132.781102
    #Twelve apostles 
    #-38.664251, 143.103907
    #Port Arthur 
    #-43.145940, 147.849481
    
  uluru <- searchInstagram(lat=latits[currentLocation], lng=longits[currentLocation], distance=500, n=150, folder=locations[currentLocation], mindate=(theDate-(newDate+1)), maxdate=(theDate-newDate), token=token)
  #write out the textual data for each image into a csv file labeled Date-(the number of days back we went)
  write.csv(uluru, file=paste("Date-",newDate,"-",locations[currentLocation],".csv", sep = ""))


## Get all of the user information
  
#Get the usernames from image data and set variables to NULL
thenames <- uluru$username
fullList <- NULL
allusers <- NULL

#for each username on this day
for (eachuser in 1:length(thenames)){
  tryCatch({
  #spit the user data into temp
    temp <- getUser(thenames[eachuser], token=token)
  #add temp to the fullList to add in the user to the dataset
    fullList <- rbind(fullList,temp)
  }, error=function(e){cat("ERROR: ",conditionMessage(e),"\n",thenames[eachuser],"\n")})
}
#write out the user profiles into a file starting with Profile-
write.csv(fullList, file=paste("Profile-",newDate,"-",locations[currentLocation],".csv", sep = ""))

## get all of the image comments

#grab the id's of all the images for this day and set variables to NULL
theImages <- uluru$id
fullComments <- NULL
allImages <- NULL
temp <- NULL
fullList <- NULL
#for each image in this day
for (eachImage in 1:length(theImages)){
  tryCatch({
    temp<-NULL
    #comments come in as separate rows, so the datafile will have multiple rows per image. will need to clean this up later.
    temp <- getComments(theImages[eachImage], token=token)
    fullList <- rbind(fullList,temp)
  }, error=function(e){cat("ERROR: ",conditionMessage(e),"\n",theImages[eachImage],"\n")})
}
#write out all the comments to a csv file starting with Comments-
write.csv(fullList, file=paste("Comments-",newDate,"-",locations[currentLocation],".csv", sep = ""))

#Pause for 15 minute after every ratelimitCounter days of scraping - needed for larger searches like 3 sisters


#spit out the error message for the day if there was one
},error=function(e){cat("ERROR: ",conditionMessage(e),"\n",theDate-newDate,"\n")})
  ratelimitCounter <- ratelimitCounter + 1
  if (ratelimitCounter == ratelimitMax){
    Sys.sleep(sleepTime)
    ratelimitCounter <- 0
  }
}
}
#######################################
######### End Step 2 ################
#######################################
