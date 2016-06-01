#Robert Dinterman

print(paste0("Started 0-IRS_Pop_ZIP at ", Sys.time()))

# THERE IS A PROBLEM WITH THE "agi_stub" VARIABLE WHICH STRATIFIES THE SAMPLE

library(dplyr)
library(readxl)
library(readr)
source("0-Data/0-functions.R")

# Create a directory for the data
localDir <- "0-Data/IRS"
data_source <- paste0(localDir, "/Raw")
if (!file.exists(localDir)) dir.create(localDir)
if (!file.exists(data_source)) dir.create(data_source)

tempDir  <- tempfile()


# ---- Data from 2011 to 2013 ---------------------------------------------

# http://tinyurl.com/jxnkr73

url    <- "http://www.irs.gov/file_source/pub/irs-soi/"
years  <- 2011:2013
urls   <- paste0(url, 11:13, "zpallnoagi.csv")
files  <- paste(data_source, basename(urls), sep = "/")

if (!all(sapply(files, function(x) file.exists(x)))) {
  mapply(download.file, url = urls, destfile = files)
}

j5 <- read_csv(files[1])

urls   <- paste0(url, 11:13, "zpallagi.csv")
files  <- paste(data_source, basename(urls), sep = "/")

if (!all(sapply(files, function(x) file.exists(x)))) {
  mapply(download.file, url = urls, destfile = files)
}

j5 <- read_csv(files[1])

# 
# tirs <- data.frame()
# for (i in files){
#   unlink(tempDir, recursive = T)
#   unzip(i, exdir = tempDir)
#   j5     <- list.files(tempDir, pattern = "*noagi.csv", full.names = T)
#   # The 2010 and 2011 are .csv but 2012 is .xls
#   if (length(j5) == 0){
#     j5     <- list.files(tempDir, pattern = "*all.xls", full.names = T)
#     irs   <- read_excel(j5, skip = 5)
#     irs   <- irs[, c(1, 3, 4, 5, 10, 12, 14, 18, 16)]
#   } else{
#     irs   <- read_csv(j5)
#     irs   <- irs[, c("STATEFIPS", "ZIPCODE", "agi_stub", "N1", "N2",
#                        "A00100", "A00200", "A00600", "A00300")]
#   }
#   
#   names(irs) <- c("st_fips", "cty_fips", "county_name", "return",
#                    "exmpt", "agi", "wages", "dividends", "interest")
#   
#   irs$st_fips  <- as.numeric(irs$st_fips)
#   irs$cty_fips <- as.numeric(irs$cty_fips)
#   
#   year      <- as.numeric(substr(basename(i), 1, 4))
#   if (is.na(year)) year <- 2013 # QUICK FIX
#   irs$year <- year
#   irs$fips <- irs$st_fips*1000 + irs$cty_fips
#   
#   # Add in total
#   add   <- ((irs$fips %% 1000) == 0)
#   addt  <- apply(irs[add, c(4:9)], 2, function(x) sum(x, na.rm = T))
#   add   <- c(0, 0, NA, addt, year, 0)
#   names(add) <- names(irs)
#   
#   # 2012 already has a total...
#   if (year != 2012)  irs    <- bind_rows(irs, as.data.frame(t(add)))
#   
#   tirs   <- bind_rows(tirs, irs)
#   
#   tirs$county_name[tirs$fips == 0] <- "Total" #Correct for NA name
#   
#   print(paste0("Finished ", basename(i), " at ", Sys.time()))
# }
# # Remove NAs
# tirs   <- tirs[!is.na(tirs$st_fips),]
# 
# 
# 
# # ---- IRS Population Data for 1998 to 2010 -------------------------------
# 
# years  <- c(1998, 2001, 2002, 2004, 2005, 2006, 2007, 2008, 2009, 2010)
# urls   <- paste0(url, years, "zipcode.zip")
# files  <- paste(data_source, basename(urls), sep = "/")
# if (all(sapply(files, function(x) !file.exists(x)))) {
#   mapply(download.file, url = urls, destfile = files)
# }
# 
# # ALL OF THESE HAVE DIFFERENT STRUCTURES OF VALUES!!!!
# 
# ################################################
# ################################################
# ################################################
# ################################################
# ################################################
# ################################################
# 
# # Documentation changes in 1997...added "Gross rents" and "Total money income"
# allirs  <- data.frame()
# 
# for (i in files){
#   unlink(tempDir, recursive = T)
#   unzip(i, exdir = tempDir)
#   
#   # some .zip do not have folders
#   xlscheck <- list.files(tempDir, pattern = "\\.xls$", full.names = T)
#   
#   if (length(xlscheck) == 0){
#     j5        <- list.dirs(tempDir, recursive = F)
#     
#     xlscheck2 <- list.files(j5, pattern = "\\.xls$") #check if 2007 messes up
#     if (length(xlscheck2) == 0){
#       j5.    <- list.dirs(j5, recursive = F)
#       j6     <- list.files(j5., pattern = "\\.xls$", full.names = T)
#     } else{
#       j6     <- list.files(j5, pattern = "\\.xls$", full.names = T)
#     }
#     
#   } else { # if .zip contains xls files in main folder...
#     j5 <- NULL
#     j6 <- xlscheck
#   }
#   
#   yirs <- data.frame()
#   for (j in j6){
#     irs   <- read_pop1(j)
#     
#     irs[,c(1:2, 4:9)] <- lapply(irs[,c(1:2, 4:9)],
#                                  function(x){ # Sometimes characters in values
#                                    as.numeric(
#                                      gsub(",", "", 
#                                           gsub("[A-z]", "", x)))
#                                  })
#     irs[, 3]     <- sapply(irs[, 3], function(x){as.character(x)})
#     year          <- as.numeric(substr(basename(i), 1, 4))
#     irs$year     <- year
#     
#     # PROBLEM, in 1989 IRS defines Cali st_fips as 90, but it's 6
#     #  further...sometimes the State fips is NA when it shouldn't be
#     st <- median(irs$st_fips, na.rm = T)
#     irs$st_fips[is.na(irs$st_fips)]   <- st
#     irs$cty_fips[is.na(irs$cty_fips)] <- 0
#     if (st == 90) {
#       irs$fips <- 6000 + irs$cty_fips
#     }    else{
#       irs$fips <- st*1000 + irs$cty_fips
#     }
#     
#     ind    <- apply(irs, 1, function(x) all(is.na(x)))
#     irs   <- irs[!ind, ]
#     yirs  <- bind_rows(yirs, irs)
#     
#     print(paste0("Finished ", basename(j), " at ", Sys.time()))
#   }
#   bfile <- gsub('.{4}$', '', basename(i))
#   yirs <- yirs[!is.na(yirs$county_name), ]  #Remove the pesky NAs
#   # Remove duplicates
#   dupes <- duplicated(yirs)
#   yirs <- yirs[!dupes, ]
#   
#   # Add in total
#   add   <- ((yirs$fips %% 1000) == 0)
#   addt  <- apply(yirs[add, c(4:9)], 2, function(x) sum(x, na.rm = T))
#   add   <- c(0, 0, NA, addt, year, 0)
#   names(add) <- names(yirs)
#   
#   yirs <- bind_rows(yirs, as.data.frame(t(add)))
#   
#   yirs$county_name[yirs$fips == 0] <- "Total" #Correct for NA name
#   
#   write_csv(yirs, paste0(data_source, "/", bfile,".csv"))
#   
#   allirs  <- bind_rows(allirs, yirs)
#   
#   print(paste0("Finished ", basename(i), " at ", Sys.time()))
# }
# # Issue with a few counties being messed up, leave it be
# # allirs[!complete.cases(allirs),]
# # allirs <- allirs[complete.cases(allirs),]
# 
# # write_csv(allirs, paste0(localDir, "/countyincome8909.csv"))
# 
# IRS_POP <- bind_rows(allirs, tirs)
# rm(allirs, irs, tirs, yirs)
# 
# IRS_POP <- filter(IRS_POP, !is.na(return), !is.na(exmpt))
# 
# IRS_POP %>% filter(fips == 11000, year == 2012) %>%
#   mutate(fips = 11001, cty_fips = 1) %>% bind_rows(IRS_POP) -> IRS_POP
# 
# IRS_POP$fips <- ifelse(IRS_POP$fips == 12025, 12086, IRS_POP$fips)
# ind          <- IRS_POP == -1 & !is.na(IRS_POP) # Turn suppressed into NA
# IRS_POP[ind] <- NA
# rm(ind)
# 
# # Add in state totals...?
# 
# IRS_POP %>%
#   filter(fips %% 1000 != 0) %>%
#   group_by(year, st_fips) %>%
#   summarise(cty_fips = 0, return = sum(return, na.rm = T),
#             exmpt = sum(exmpt, na.rm = T),
#             agi = sum(agi, na.rm = T),
#             wages = sum(wages, na.rm = T),
#             dividends = sum(dividends, na.rm = T),
#             interest = sum(interest, na.rm = T)) -> states
# states$fips        <- 1000*states$st_fips
# states$county_name <- "State Total"
# 
# IRS_POP %>%
#   filter(fips %% 1000 != 0) %>%
#   bind_rows(states) -> IRS_POP
# 
# IRS_POP <- select(IRS_POP, fips, year, pop_IRS = exmpt,
#                   HH_IRS = return, agi_IRS = agi, wages_IRS = wages,
#                   dividends_IRS = dividends, interest_IRS = interest)
# 
# # Problem with 51515, 51560, 51780:
# IRS_POP <- fipssues(IRS_POP, 51019, c(51019, 51515))
# IRS_POP <- fipssues(IRS_POP, 51005, c(51005, 51560))
# IRS_POP <- fipssues(IRS_POP, 51083, c(51083, 51780))
# 
# # 
# # write_csv(IRS_POP, paste0(localDir, "/countyincome8913.csv"))
# # save(IRS_POP, file = paste0(localDir, "/CTYPop.Rda"))

print(paste0("Finished 0-IRS_Pop_ZIP at ", Sys.time()))

rm(list = ls())
