# Robert Dinterman
# https://www.ncdc.noaa.gov/stormevents/ftp.jsp

print(paste0("Started 0-NOAA_Storm at ", Sys.time()))

library(dplyr)
library(lubridate)
library(readr)
library(rvest)

# Create a directory for the data
localDir <- "0-Data/NOAA"
data_source <- paste0(localDir, "/raw")
if (!file.exists(localDir)) dir.create(localDir)
if (!file.exists(data_source)) dir.create(data_source)

# ---- Data Download ------------------------------------------------------

url <- "http://www1.ncdc.noaa.gov/pub/data/swdi/stormevents/csvfiles/"
read_html(url) %>%
  html_nodes("a") %>%
  html_attr("href") -> files

ref    <- files[grep("*.docx", files)]
rfiles <- paste(localDir, rbind(ref, "README_Storm.txt"), sep = "/")
ref    <- rbind(ref, "README")
urls   <- paste0(url, ref)
if (all(sapply(rfiles, function(x) !file.exists(x)))) {
  mapply(download.file, url = urls, destfile = rfiles)
}
rm(ref, rfiles)

# Data
files <- files[grep("*.csv", files)]
files <- paste(data_source, files, sep = "/")
urls  <- paste0(url, basename(files))

if (all(sapply(files, function(x) !file.exists(x)))) {
  mapply(download.file, url = urls, destfile = files)
}

# ---- Split Files --------------------------------------------------------

# # Unsure of the purpose for this file.
# ugc <- files[grep("ugc", files)]
# ugc <- read_csv(ugc)

# ---- Events -------------------------------------------------------------
# Function to correct for the damages abbreviations
abbrev <- function(x){
  val  <- as.numeric(gsub("[[:alpha:]]", "", x))
  val  <- replace(val, is.na(val), 1)
  
  inc  <- tolower(gsub("[^[:alpha:]]", "", x))
  inc  <- replace(inc, inc == "", "1")
  inc  <- replace(inc, inc == "h", "100")
  inc  <- replace(inc, inc == "k", "1000")
  inc  <- replace(inc, inc == "t", "1000")
  inc  <- replace(inc, inc == "m", "1000000")
  inc  <- replace(inc, inc == "b", "1000000000")
  inc  <- as.numeric(inc)
  
  val  <- val * inc
  return(val)
}

fixdate <- function(x, year = 1949){
  require(lubridate)
  m       <- year(x) %% 100
  year(x) <- ifelse(m > year %% 100, 1900 + m, 2000 + m)
  return(x)
}

detail  <- files[grep("StormEvents_details-ftp", files)]
dfun    <- function(x,n) read_csv(x, col_types = strrep("c", n))
devents <- lapply(detail, function(x) dfun(x, 51)) %>% 
  bind_rows() %>% 
  mutate(BEGIN_YEARMONTH = as.numeric(BEGIN_YEARMONTH),
         BEGIN_DAY = as.numeric(BEGIN_DAY), BEGIN_TIME = as.numeric(BEGIN_TIME),
         END_YEARMONTH = as.numeric(END_YEARMONTH),
         END_DAY = as.numeric(END_DAY), END_TIME = as.numeric(END_TIME),
         EPISODE_ID = as.numeric(EPISODE_ID), EVENT_ID = as.numeric(EVENT_ID),
         STATE_FIPS = as.numeric(STATE_FIPS), YEAR = as.numeric(YEAR),
         CZ_FIPS = as.numeric(CZ_FIPS),
         BEGIN_DATE_TIME_ = fixdate(dmy_hms(BEGIN_DATE_TIME)),
         END_DATE_TIME_ = fixdate(dmy_hms(END_DATE_TIME)),
         INJURIES_DIRECT = as.numeric(INJURIES_DIRECT),
         INJURIES_INDIRECT = as.numeric(INJURIES_INDIRECT),
         DEATHS_DIRECT = as.numeric(DEATHS_DIRECT),
         DEATHS_INDIRECT = as.numeric(DEATHS_INDIRECT),
         DAMAGE_PROPERTY = abbrev(DAMAGE_PROPERTY),
         DAMAGE_CROPS = abbrev(DAMAGE_CROPS),
         MAGNITUDE = as.numeric(MAGNITUDE), TOR_LENGTH = as.numeric(TOR_LENGTH),
         TOR_WIDTH = as.numeric(TOR_WIDTH),
         TOR_OTHER_CZ_FIPS = as.numeric(TOR_OTHER_CZ_FIPS),
         BEGIN_RANGE = as.numeric(BEGIN_RANGE),
         END_RANGE = as.numeric(END_RANGE),
         BEGIN_LAT = as.numeric(BEGIN_LAT), BEGIN_LON = as.numeric(BEGIN_LON),
         END_LAT = as.numeric(END_LAT), END_LON = as.numeric(END_LON))

names(devents) <- tolower(names(devents))

saveRDS(devents, paste0(localDir, "/events.rds"))
# write_csv(devents, paste0(localDir, "/events.csv"))
# zip(paste0(localDir, "/events.zip"), paste0(localDir, "/events.csv"))


# ---- Fatalities ---------------------------------------------------------

fatal <- files[grep("StormEvents_fatalities-ftp", files)]
dfat   <- lapply(fatal, function(x) dfun(x, 11)) %>% 
  bind_rows() %>% 
  mutate(FAT_YEARMONTH = as.numeric(FAT_YEARMONTH),
         FAT_DAY = as.numeric(FAT_DAY), FAT_TIME = as.numeric(FAT_TIME),
         FATALITY_ID = as.numeric(FATALITY_ID), EVENT_ID = as.numeric(EVENT_ID),
         FATALITY_DATE_ = fixdate(mdy_hms(FATALITY_DATE)),
         EVENT_YEARMONTH = as.numeric(EVENT_YEARMONTH))

names(dfat) <- tolower(names(dfat))

saveRDS(dfat, paste0(localDir, "/fatalities.rds"))
# write_csv(dfat, paste0(localDir, "/fatalities.csv"))
# zip(paste0(localDir, "/fatalities.zip"), paste0(localDir, "/fatalities.csv"))

# Check for problem EVENT_ID that do not appear
check <- dfat$EVENT_ID %in% devents$EVENT_ID
table(dfat$EVENT_ID[!check])

# ---- Locations ----------------------------------------------------------

location <- files[grep("StormEvents_locations-ftp", files)]
dlocate  <- lapply(location, function(x) dfun(x, 11)) %>% 
  bind_rows() %>% 
  filter(complete.cases(.)) %>%
  mutate(YEARMONTH = as.numeric(YEARMONTH),
         EPISODE_ID = as.numeric(EPISODE_ID),
         EVENT_ID = as.numeric(EVENT_ID),
         RANGE = as.numeric(RANGE),
         LATITUDE = as.numeric(LATITUDE),
         LONGITUDE = as.numeric(LONGITUDE),
         LAT2 = as.numeric(LAT2),
         LON2 = as.numeric(LON2))

names(dlocate) <- tolower(names(dlocate))

saveRDS(dlocate, paste0(localDir, "/location.rds"))
# write_csv(dlocate, paste0(localDir, "/location.csv"))
# zip(paste0(localDir, "/location.zip"), paste0(localDir, "/location.csv"))


# ---- Basic Summary ------------------------------------------------------

devents %>% mutate(fips = state_fips*1000 + cz_fips) %>% 
  filter(cz_type == "C") %>% 
  group_by(year, fips) %>% select(injuries_direct:damage_crops) %>% 
  summarise_each(funs(sum(., na.rm = T))) -> noaabasic

noaabasic <- expand.grid(year = unique(noaabasic$year),
                         fips = unique(noaabasic$fips)) %>% 
  left_join(noaabasic) %>% replace(is.na(.), 0)

saveRDS(noaabasic, file = paste0(localDir, "/noaabasic.rds"))

print(paste0("Finished 0-NOAA_Storm at ", Sys.time()))

rm(list = ls())
