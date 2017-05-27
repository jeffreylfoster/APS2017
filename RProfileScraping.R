########################
# Jeffrey L. Foster's code for bulk scraping Twitter feeds from users
# This script runs in 3 steps. First, it loads the variables and packages
# Second, it connects to the Twitter API
# Third, it conducts the profile scrapes in bulk. Step 3 can be run multiple times without steps 1 and 2 after they have been done
# This code heavily relies on Jeff Gentry's twitteR package. 
# be sure to cite Jeff Gentry's twitteR package as below:
# Jeff Gentry (2015). twitteR: R Based Twitter Client. R package version 1.1.9. https://CRAN.R-project.org/package=twitteR
# contact jeff.foster@westernsydney.edu.au for questions regarding this script
#
#
#
# This script requires a Twitter API Dev account with a consumer key and consumer secrety
# Set one up on dev.twitter.com by creating a developer account, and creating a new app on the dev.twitter.com website
# The information you setup the app with doesn't matter, but set the callback URL to 127.0.0.1:1410 . This setting will
# ensure that the information is sent back to your own computer (127.0.0.1 is always your local computer) on port 1410
# so that it goes straight to R. 
########################

############################################################################################################
#STEP 1
#Loads the packages and sets your variables
#This stage needs your information form the Twitter API Dev account
############################################################################################################
#needed packages
require(progress)
require(twitteR)
#load packages
library(progress)
library(twitteR)

########################
#Start Variales
########################

#!!!! The following 3 variables must be set before anything can be collected

#The handles variable needs to be filled with twitter handles as a character list. 
#Currently, it just reads a .csv file filled with twitter handles; could be entered 
#manually as handles <- c('someHandle', 'anotherHandle','morehandles', etc.)
handles <- read.csv("UniqueHandles.csv")
consumerKey <- "XXXXX" #retrieved from your Twitter API Dev account
consumerSecret <- "XXXXX" #retrieved from your Twitter API Dev account

##Set Maximum pull to fit with Twitter limits
setRateLimit <- 30 #number of records to pull before pausing for cooldownperiod
timeoutcounter <- 0
tweetsPerProfile <- 1000 #number of lines of tweets max to pull - can but up to 3000; will affect rate limit
coolDownPeriod <- 600 #seconds to cool down for rate limit. Set higher if hitting limit, lower to speed up
startLength <- 1 #leave at 1 to start at beginning; can set higher for batches
EndLength <-  length(handles) #leave at length(handles) to do them all, can set fewer for batches)

############
#End Variales
############





############################################################################################################
#STEP 2
#This code must be run by itself to ensure the twitter account is setup properly
#This code utilizes a callback URL in twitter API setup, make sure there is once set to 127.0.0.1:1410
############################################################################################################

reqURL <- "https://api.twitter.com/oauth/request_token"
accessURL <- "https://api.twitter.com/oauth/access_token"
authURL <- "https://api.twitter.com/oauth/authorize"

#Main connection here; 
setup_twitter_oauth(consumer_key=consumerKey, consumer_secret=consumerSecret, access_token=NULL, access_secret=NULL)




############################################################################################################
#END STEP 2
############################################################################################################



############################################################################################################
#STEP 3
#May need to crosscheck when done, which handles were successfully pulled, and create a new handles variable
#with just the ones that were not pulled, then re-run this step with the unpulled accounts
#depending on a variaty of factors, may take 3-4 loops to get it all
############################################################################################################

#setup a progress bar so you can see how long it will take
pb <- progress_bar$new(
  format = "(:spin) [:bar] :percent",
  total = length(handles), clear = FALSE, width = 60)
##Do for each user profile in a variable array called ‘handles’
for (theUser in startLength:EndLength){
  pb$tick()
  ##try first, if error, list error and carry on
  tryCatch({
    
    ##Pull up to 300(tweetsPerProfile) most recent tweets from the users timeline, including the RTs
    #set includeRts to FALSE if you want original content only
    you <- userTimeline(as.character(handles[theUser]),n=tweetsPerProfile,maxID=NULL,sinceID=NULL,includeRts=TRUE)
    
    ##convert the tweets into a dataFrame for R to understand
    theUserDF <- twListToDF(you)
    
    #######################################
    #Choose to save as a .csv or a .Rda
    ######################################
    
    ###Save file as a .csv file - easier to work with, may have invalid characters, not recommenced
    #filename1 <- paste(theUserDF$screenName[1],".csv",sep="")
    #write.csv (theUserDF, file=filename1,row.names=FALSE,na='')
    
    #Save as a .Rda (dataframe) file; recommended
    filename2 <- paste(theUserDF$screenName[1],".Rda",sep="")
    save(theUserDF,file=filename2)
    
    
    #######################################
    #End Choice
    ######################################
    
  }
  
  ##if there’s an error, spit it out.
  ,error=function(e){cat("ERROR :",conditionMessage(e), "\n")})
  
  ##tell me where I’m at in this long process
  #print(theUser)
  
  ##pause for cool down due to Twitter rateLimits
  #Below gives a warning when you're just about to the rate limit, and then pauses at the rate limit
  timeoutcounter = timeoutcounter+1
  if (timeoutcounter > (setRateLimit-3)){
    print('Pausing  for Rate Limit')
  }
  if (timeoutcounter > setRateLimit){
    timeoutcounter <- 0
    Sys.sleep(coolDownPeriod)
  }
}

############################################################################################################
#END STEP 3
############################################################################################################