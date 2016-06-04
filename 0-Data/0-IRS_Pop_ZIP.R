#Robert Dinterman

print(paste0("Started 0-IRS_Pop_ZIP at ", Sys.time()))

# THERE IS A PROBLEM WITH THE "agi_stub" VARIABLE WHICH STRATIFIES THE SAMPLE

library(dplyr)
library(readxl)
library(readr)
source("0-Data/0-functions.R")

# Create a directory for the data
localDir <- "0-Data/IRS"
data_source <- paste0(localDir, "/raw")
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

irs <- mapply(function(files, years){
  dat         <- read_csv(files)
  dat         <- select(dat, st_fips = STATEFIPS, zip = ZIPCODE,
                        agi_stub = AGI_STUB, return = N1, exmpt = N2,
                        agi = A00100, wages = A00200, dividends = A00600,
                        interest = A00300)
  dat$year    <- years
  dat$st_fips <- as.numeric(dat$st_fips)
  
  return(dat)
}, files = files, years = years, SIMPLIFY = F) %>% 
  bind_rows()

saveRDS(irs, paste0(localDir, "/ZIP_population.rds"))

urls   <- paste0(url, 11:13, "zpallagi.csv")
files  <- paste(data_source, basename(urls), sep = "/")

if (!all(sapply(files, function(x) file.exists(x)))) {
  mapply(download.file, url = urls, destfile = files)
}

irs_agi <- mapply(function(files, years){
  dat         <- read_csv(files)
  names(dat)  <- toupper(names(dat)) # inconsistent var names
  dat         <- select(dat, st_fips = STATEFIPS, zip = ZIPCODE, 
                        agi_stub = AGI_STUB, return = N1, exmpt = N2,
                        agi = A00100, wages = A00200, dividends = A00600,
                        interest = A00300)
  dat$year    <- years
  dat$st_fips <- as.numeric(dat$st_fips)

  return(dat)
}, files = files, years = years, SIMPLIFY = F) %>% 
  bind_rows() %>% 
  bind_rows(irs)

saveRDS(irs_agi, paste0(localDir, "/ZIP_population_agi_classes.rds"))

# ---- IRS Population Data for 1998 to 2010 -------------------------------

years  <- c(1998, 2001, 2002, 2004, 2005, 2006, 2007, 2008, 2009, 2010)
urls   <- paste0(url, years, "zipcode.zip")
files  <- paste(data_source, basename(urls), sep = "/")
if (all(sapply(files, function(x) !file.exists(x)))) {
  mapply(download.file, url = urls, destfile = files)
}

for (i in files){
  unlink(tempDir, recursive = T)
  unzip(i, exdir = tempDir)
  
  print(i)
  print(list.files(tempDir))
  #print(list.dirs(tempDir))
  
}

# ALL OF THESE HAVE DIFFERENT STRUCTURES OF VALUES!!!!
# 1998 - folder
# 2001 - folder
# 2002 - files with zptab00xx.xls || NO FOLDERS!!!
# 2004 - folder
# 2005 - 05zpdoc.xls / folder / zipcode05.csv || START OF csv FILES
# 2006 - 06zpdoc.xls / folder / zipcode06.csv
# 2007 - zipcode07.csv / .xls
# 2008 - folder
# 2009 - allagi.csv / allnoagi.csv
# 2010 - allagi.csv / allnoagi.csv

alldat <- data.frame()
for (i in files[5:10]){
  unlink(tempDir, recursive = T)
  unzip(i, exdir = tempDir)
  
  
  if (i != "0-Data/IRS/raw/2008zipcode.zip") { # 2008 is a folder w/o csv
    j5  <- list.files(tempDir, pattern = "\\.csv$", full.names = T)
  } else {
     j5 <- list.dirs(tempDir)
     j5 <- list.files(j5[2], pattern = "\\.csv$", full.names = T)
  }
  
  if (length(j5) == 1) {# & i != "0-Data/IRS/raw/2005zipcode.zip") {
    dat <- read_csv(j5)
    names(dat) <- toupper(names(dat))
    dat$ZIPCODE <- as.character(dat$ZIPCODE)
    dat$year    <- as.numeric(gsub("[^[:digit:]]", "", basename(i)))
  # } else if (length(j5) == 1 & i == "0-Data/IRS/raw/2005zipcode.zip"){
  #   # Problem with reading in 2005
  #   dat <- read_csv(j5, col_types = paste0("c", strrep("i", 37), "ccc"))
  #   names(dat) <- toupper(names(dat))
  #   dat$ZIPCODE <- as.numeric(dat$ZIPCODE)
  } else {
    dat <- sapply(j5, function(x) {
      dats <- read_csv(x)
      names(dats) <- toupper(names(dats))
      return(dats)
    }, simplify = F)
    dat <- bind_rows(dat)
    dat$ZIPCODE <- as.character(dat$ZIPCODE)
    dat$year    <- as.numeric(gsub("[^[:digit:]]", "", basename(i)))
  }
  
  alldat <- bind_rows(alldat, dat)
}

print(paste0("Finished 0-IRS_Pop_ZIP at ", Sys.time()))

rm(list = ls())
