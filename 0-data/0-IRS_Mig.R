#Robert Dinterman

print(paste0("Started 0-IRS_Mig at ", Sys.time()))

library(dplyr)
library(readr)
library(stringr)
source("0-data/0-functions.R")


# Create a directory for the data, ignore for GitHub
localDir <- "0-data/IRS"
data_source <- paste0(localDir, "/raw")
if (!file.exists(localDir)) dir.create(localDir)
if (!file.exists(data_source)) dir.create(data_source)

tempDir  <- tempfile()

# ---- IRS Migration Data for 1992 to 2004 --------------------------------
#http://www.irs.gov/uac/SOI-Tax-Stats-Migration-Data

url    <- "http://www.irs.gov/file_source/pub/irs-soi/"
year   <- 1992:2003 #the 90 to 92 data are in text files
urls   <- paste0(url, year, "to", year + 1, "countymigration.zip")
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

# Problem with 2003 Illinois
prob <- allinflow$year == 2003 & allinflow$dfips == 17017 &
  allinflow$county_name == "TOTAL MIG - US & FOR"
allinflow$cty_fips_d[prob] <- 0
allinflow$dfips[prob]      <- 17000

# Duplicated issues, add leading zeros to fips:
allinflow$key  <- paste0(str_pad(allinflow$ofips, 5, pad = "0"),
                         str_pad(allinflow$dfips, 5, pad = "0"),
                         allinflow$year)
alloutflow$key <- paste0(str_pad(alloutflow$ofips, 5, pad = "0"),
                         str_pad(alloutflow$dfips, 5, pad = "0"),
                         alloutflow$year)
alloutflow <- filter(alloutflow, !duplicated(key))

write_csv(allinflow, paste0(localDir, "/inflows9203.csv"))
write_csv(alloutflow, paste0(localDir, "/outflows9203.csv"))


# ---- Data from 2004 to 2013 ---------------------------------------------
dyears   <- c("0405", "0506", "0607", "0708", "0809",
              "0910", "1011", "1112", "1213", "1314")
infiles  <- paste0("countyinflow", dyears, ".csv")

inflow   <- sapply(infiles, function(x){
  file          <- paste0(data_source, "/", x)
  
  if (!file.exists(file)) (download.file(paste0(url, x), file))
  
  flow          <- read_csv(file, namesi, col_types = "iiiicciii", skip = 1)
  flow[,c(5:6)] <- lapply(flow[,c(5:6)], function(xx) toupper(str_trim(xx)))
  flow$year     <- 1999 + as.numeric(substr(x, nchar(x) - 5, nchar(x) - 4))
  flow$ofips    <- flow$st_fips_o*1000 + flow$cty_fips_o
  flow$dfips    <- flow$st_fips_d*1000 + flow$cty_fips_d
  
  filter(flow, !is.na(st_fips_d))
}, simplify = F, USE.NAMES = T)

allin     <- bind_rows(inflow)
allin$key <- paste0(str_pad(allin$ofips, 5, pad = "0"),
                    str_pad(allin$dfips, 5, pad = "0"),
                    allin$year)
# Duplicate problem:
# allin %>% 
#   filter(duplicated(key) | duplicated(key, fromLast = T)) %>%
#   group_by(key) %>%
#   mutate(check = mean(return) - return, count = n()) %>% 
#   ungroup %>% arrange(desc(count)) %>% 
#   filter(check != 0) -> j5
allin <- filter(allin, !duplicated(key))

write_csv(allin, paste0(localDir, "/inflows0413.csv"))

outfiles <- paste0("countyoutflow", dyears, ".csv")

outflow  <- sapply(outfiles, function(x){
  file       <- paste0(data_source, "/", x)
  
  if (!file.exists(file)) (download.file(paste0(url, x), file))
  
  flow          <- read_csv(file, nameso, col_types = "iiiicciii", skip = 1)
  flow[,c(5:6)] <- lapply(flow[,c(5:6)], function(xx) toupper(str_trim(xx)))
  flow$year     <- 1999 + as.numeric(substr(x, nchar(x) - 5, nchar(x) - 4))
  flow$ofips    <- flow$st_fips_o*1000 + flow$cty_fips_o
  flow$dfips    <- flow$st_fips_d*1000 + flow$cty_fips_d
  
  filter(flow, !is.na(st_fips_o))
}, simplify = F, USE.NAMES = T)

allout     <- bind_rows(outflow)
allout$key <- paste0(str_pad(allout$ofips, 5, pad = "0"),
                     str_pad(allout$dfips, 5, pad = "0"),
                     allout$year)
# Duplicate problem:
# allout %>%
#   filter(duplicated(key) | duplicated(key, fromLast = T)) %>%
#   group_by(key) %>%
#   mutate(check = mean(return) - return, count = n()) %>%
#   ungroup %>% arrange(desc(count)) %>%
#   filter(check != 0) -> j5
allout <- filter(allout, !duplicated(key))

write_csv(allout, paste0(localDir, "/outflows0413.csv"))

rm(inflow, outflow)

allinflow         <- bind_rows(allinflow, allin)
allinflow$return  <- ifelse(is.na(allinflow$return), -1, allinflow$return)
allinflow$exmpt   <- ifelse(is.na(allinflow$exmpt), -1, allinflow$exmpt)
allinflow$agi     <- ifelse(is.na(allinflow$agi), -1, allinflow$agi)
saveRDS(allinflow,  file = paste0(localDir, "/inflows9213.rds"))

alloutflow        <- bind_rows(alloutflow, allout)
alloutflow$return <- ifelse(is.na(alloutflow$return), -1, alloutflow$return)
alloutflow$exmpt  <- ifelse(is.na(alloutflow$exmpt), -1, alloutflow$exmpt)
alloutflow$agi    <- ifelse(is.na(alloutflow$agi), -1, alloutflow$agi)
saveRDS(alloutflow, file = paste0(localDir, "/outflows9213.rds"))

allinflow$key  <- paste0(allinflow$ofips, allinflow$dfips, allinflow$year)
alloutflow$key <- paste0(alloutflow$ofips, alloutflow$dfips, alloutflow$year)

check1 <- allinflow$key %in% alloutflow$key
sum(check1)
sum(!check1)

check2 <- alloutflow$key %in% allinflow$key
sum(check2)
sum(!check2)

print(paste0("Finished 0-IRS_Mig at ", Sys.time()))

rm(list = ls())
