# Robert Dinterman - Wildfire Data
# source: http://wildfire.cr.usgs.gov/firehistory/data.html
# descrip: http://wildfire.cr.usgs.gov/firehistory/firehistory_1980_2015.xml

print(paste0("Started 0-Wildfire at ", Sys.time()))

# library(dplyr)
# library(readr)
# library(stringr)
# source("0-Data/0-functions.R")

# Create a directory for the data, ignore for GitHub
localDir <- "0-data/Wildfire"
data_source <- paste0(localDir, "/raw")
if (!file.exists(localDir)) dir.create(localDir)
if (!file.exists(data_source)) dir.create(data_source)

tempDir  <- tempfile()

# ---- USGS Compiled ------------------------------------------------------
# http://wildfire.cr.usgs.gov/firehistory/data/fh_all.zip

url    <- "http://wildfire.cr.usgs.gov/firehistory/data/"
urls   <- paste0(url, c("fh_all.zip", "fh_all_gdb.zip"))
files  <- paste(data_source, basename(urls), sep = "/")
if (all(sapply(files, function(x) !file.exists(x)))) {
  mapply(download.file, url = urls, destfile = files, method = "libcurl")
}

allinflow  <- data.frame()
alloutflow <- data.frame()

namesi <- c("st_fips_d", "cty_fips_d", "st_fips_o", "cty_fips_o",
            "state_abbrv", "county_name", "return", "exmpt", "agi")
nameso <- c("st_fips_o", "cty_fips_o", "st_fips_d", "cty_fips_d",
            "state_abbrv", "county_name", "return", "exmpt", "agi")

for (i in files){  
  unzip(i, exdir = tempDir)
  j5         <- list.dirs(tempDir)
  j5i        <- list.files(j5[grepl("Inflow", j5)], full.names = T)
  j5o        <- list.files(j5[grepl("Outflow", j5)], full.names = T)
  
  inflow     <- read_data1(j5i, namesi)
  outflow    <- read_data1(j5o, nameso, inflow = F)
  
  unlink(tempDir, recursive = T)
  allinflow  <- bind_rows(allinflow, inflow)
  alloutflow <- bind_rows(alloutflow, outflow)
  rm(inflow, outflow)
  print(paste0("Finished ", basename(i), " at ", Sys.time()))
}
# Problem in 1996 where the inflow for total US is coded as 1 instead of 0
allinflow <- filter(allinflow, !(st_fips_d == 1 & state_abbrv == "US"))
