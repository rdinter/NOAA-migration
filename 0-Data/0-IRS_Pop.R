#Robert Dinterman

print(paste0("Started 0-IRS_Pop at ", Sys.time()))

# THERE IS A PROBLEM WITH THE "agi_stub" VARIABLE WHICH STRATIFIES THE SAMPLE
# this begins in 2010

library(dplyr)
library(readr)
source("0-Data/0-functions.R")

# Create a directory for the data
localDir <- "0-Data/IRS"
data_source <- paste0(localDir, "/raw")
if (!file.exists(localDir)) dir.create(localDir)
if (!file.exists(data_source)) dir.create(data_source)

tempDir  <- tempfile()

#####
# IRS Population Data for 1989 to 2009
# http://www.irs.gov/uac/SOI-Tax-Stats-County-Data

url    <- "http://www.irs.gov/file_source/pub/irs-soi/"
years  <- 1989:2009

urls   <- paste0(url, years, "countyincome.zip")
files  <- paste(data_source, basename(urls), sep = "/")
if (all(sapply(files, function(x) !file.exists(x)))) {
  mapply(download.file, url = urls, destfile = files)
}

# Documentation changes in 1997...added "Gross rents" and "Total money income"
allirs  <- data.frame()

for (i in files){
  unlink(tempDir, recursive = T)
  unzip(i, exdir = tempDir)
  
  # some .zip do not have folders
  xlscheck <- list.files(tempDir, pattern = "\\.xls$", full.names = T)
  
  if (length(xlscheck) == 0){
    j5        <- list.dirs(tempDir, recursive = F)
    
    xlscheck2 <- list.files(j5, pattern = "\\.xls$") #check if 2007 messes up
    if (length(xlscheck2) == 0){
      j5_     <- list.dirs(j5, recursive = F)
      j6      <- list.files(j5_, pattern = "\\.xls$", full.names = T)
    } else{
      j6      <- list.files(j5, pattern = "\\.xls$", full.names = T)
    }
    
  } else { # if .zip contains xls files in main folder...
    j5 <- NULL
    j6 <- xlscheck
  }
  
  yirs <- data.frame()
  for (j in j6){
    irs   <- read_pop1(j)
    
    irs[,c(1:2, 4:9)] <- lapply(irs[,c(1:2, 4:9)],
                                 function(x){ # Sometimes characters in values
                                   as.numeric(
                                     gsub(",", "", 
                                          gsub("[A-z]", "", x)))
                                 })
    irs[, 3] <- sapply(irs[, 3], function(x){as.character(x)})
    year     <- as.numeric(substr(basename(i), 1, 4))
    irs$year <- year
    
    # PROBLEM, in 1989 IRS defines Cali st_fips as 90, but it's 6
    #  further...sometimes the State fips is NA when it shouldn't be
    st <- median(irs$st_fips, na.rm = T)
    irs$st_fips[is.na(irs$st_fips)]   <- st
    irs$cty_fips[is.na(irs$cty_fips)] <- 0
    
    if (st == 90) {
      irs$fips <- 6000 + irs$cty_fips
    }    else{
      irs$fips <- st*1000 + irs$cty_fips
    }
    
    ind  <- apply(irs, 1, function(x) all(is.na(x)))
    irs  <- irs[!ind, ]
    yirs <- bind_rows(yirs, irs)
    
    print(paste0("Finished ", basename(j), " at ", Sys.time()))
  }
  bfile <- gsub('.{4}$', '', basename(i))
  yirs  <- yirs[!is.na(yirs$county_name), ]  #Remove the pesky NAs
  # Remove duplicates
  dupes <- duplicated(yirs)
  yirs  <- yirs[!dupes, ]
  
  # Add in total
  add   <- ((yirs$fips %% 1000) == 0)
  addt  <- apply(yirs[add, c(4:9)], 2, function(x) sum(x, na.rm = T))
  add   <- c(0, 0, NA, addt, year, 0)
  names(add) <- names(yirs)
  
  yirs  <- bind_rows(yirs, as.data.frame(t(add)))
  
  yirs$county_name[yirs$fips == 0] <- "Total" #Correct for NA name
  
  write_csv(yirs, paste0(data_source, "/", bfile,".csv"))
  
  allirs  <- bind_rows(allirs, yirs)
  
  print(paste0("Finished ", basename(i), " at ", Sys.time()))
}

# Data from 2010 to 2013
# Problem with 2013, it's called county.zip not countydata.zip
years  <- 2010:2012
urls   <- paste0(url, years, "countydata.zip")
urls[4]<- paste0(url, "county", 2013, ".zip")
files  <- paste(data_source, basename(urls), sep = "/")

if (!all(sapply(files, function(x) file.exists(x)))) {
  mapply(download.file, url = urls, destfile = files)
}

# NEED TO ADD IN THE agi_stub HERE
tirs <- data.frame()
for (i in files){
  unlink(tempDir, recursive = T)
  unzip(i, exdir = tempDir)
  
  j5     <- list.files(tempDir, pattern = "*noagi.csv", full.names = T)
  
  # The 2010 and 2011 are .csv but 2012 is .xls
  if (length(j5) == 0){
    j5  <- list.files(tempDir, pattern = "*all.xls", full.names = T)
    irs <- read_excel(j5, skip = 5)
    irs <- irs[, c(1, 3, 4, 5, 10, 12, 14, 18, 16)]
  } else{
    irs <- read_csv(j5)
    irs <- irs[, c("STATEFIPS", "COUNTYFIPS", "COUNTYNAME", "N1", "N2",
                   "A00100", "A00200", "A00600", "A00300")]
  }
  
  names(irs) <- c("st_fips", "cty_fips", "county_name", "return",
                   "exmpt", "agi", "wages", "dividends", "interest")
  
  irs$st_fips  <- as.numeric(irs$st_fips)
  irs$cty_fips <- as.numeric(irs$cty_fips)
  
  year      <- as.numeric(substr(basename(i), 1, 4))
  if (is.na(year)) year <- 2013 # QUICK FIX
  irs$year <- year
  irs$fips <- irs$st_fips*1000 + irs$cty_fips
  
  # Add in total
  add   <- ((irs$fips %% 1000) == 0)
  addt  <- apply(irs[add, c(4:9)], 2, function(x) sum(x, na.rm = T))
  add   <- c(0, 0, NA, addt, year, 0)
  names(add) <- names(irs)
  
  # 2012 already has a total...
  if (year != 2012)  irs <- bind_rows(irs, as.data.frame(t(add)))
  
  tirs   <- bind_rows(tirs, irs)
  
  tirs$county_name[tirs$fips == 0] <- "Total" # Correct for NA name
  
  print(paste0("Finished ", basename(i), " at ", Sys.time()))
}
# Remove NAs
tirs         <- tirs[!is.na(tirs$st_fips),]

irs_pop      <- bind_rows(allirs, tirs)
rm(allirs, irs, tirs, yirs)

irs_pop      <- filter(irs_pop, !is.na(return), !is.na(exmpt))

irs_pop %>% filter(fips == 11000, year == 2012) %>%
  mutate(fips = 11001, cty_fips = 1) %>% bind_rows(irs_pop) -> irs_pop

irs_pop$fips <- ifelse(irs_pop$fips == 12025, 12086, irs_pop$fips)
ind          <- irs_pop == -1 & !is.na(irs_pop) # Turn suppressed into NA
irs_pop[ind] <- NA
rm(ind)

# Add in state totals

irs_pop %>%
  filter(fips %% 1000 != 0) %>%
  group_by(year, st_fips) %>%
  summarise(cty_fips  = 0, return = sum(return, na.rm = T),
            exmpt     = sum(exmpt, na.rm = T),
            agi       = sum(agi, na.rm = T),
            wages     = sum(wages, na.rm = T),
            dividends = sum(dividends, na.rm = T),
            interest  = sum(interest, na.rm = T)) -> states
states$fips        <- 1000*states$st_fips
states$county_name <- "State Total"

irs_pop %>%
  filter(fips %% 1000 != 0) %>%
  bind_rows(states) -> irs_pop

irs_pop <- select(irs_pop, fips, year, pop_irs = exmpt,
                  hh_irs = return, agi_irs = agi, wages_irs = wages,
                  dividends_irs = dividends, interest_irs = interest)

# Problem with 51515, 51560, 51780:
irs_pop <- fipssues(irs_pop, 51019, c(51019, 51515))
irs_pop <- fipssues(irs_pop, 51005, c(51005, 51560))
irs_pop <- fipssues(irs_pop, 51083, c(51083, 51780))

write_csv(irs_pop, paste0(localDir, "/countyincome8913.csv"))
saveRDS(irs_pop, file = paste0(localDir, "/cty_pop.rds"))

print(paste0("Finished 0-IRS_Pop at ", Sys.time()))

rm(list = ls())