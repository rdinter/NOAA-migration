#Robert Dinterman

print(paste0("Started 0-IRS_Mig at ", Sys.time()))

library(dplyr)
library(gdata)
library(readxl)
library(readr)
library(stringr)

#Problem for excel files with "us" from 1998.99 until 2001.2
read_excel1 <- function(file){
  data   <- read_excel(file)
  data   <- data[, c(1:9)]
  #data   <- data[c(8:nrow(data)), c(1:9)]
  return(data)
}
read_excel2 <- function(file){
  data   <- read.xls(file)
  data   <- data[c(4:nrow(data)), c(1:9)]
  return(data)
}
Mode <- function(x) {
  ux <- unique(x)
  ux[which.max(tabulate(match(x, ux)))]
}

read_data1 <- function(j5i, namesi){
  
  indata <- sapply(j5i, function(x){
    data <- tryCatch(read_excel1(x), error = function(e){
      read_excel2(x)
    })
    
    data[,c(1:4,7:9)] <- lapply(data[,c(1:4,7:9)],
                                function(xx){ # Sometimes characters in values
                                  as.numeric(
                                    gsub(",", "", 
                                         gsub("[A-z]", "", xx)))
                                })
    data[,c(5:6)]     <- lapply(data[,c(5:6)], function(xx) toupper(xx) )
    names(data)       <- namesi
    
    data                 <- filter(data, !is.na(state_code_d))
    data$state_code_d <- Mode(data$state_code_d)
    data$ofips <- data$state_code_o*1000 + data$county_code_o
    data$dfips <- data$state_code_d*1000   + data$county_code_d
    data
  }, simplify = F, USE.NAMES = T)
  indata <- bind_rows(indata)
  indata$year <- as.numeric(substr(basename(i), 1, 4))
  return(indata)
}

# Create a directory for the data, ignore for GitHub
localDir <- "0-Data/IRS"
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

allindata  <- data.frame()
alloutdata <- data.frame()

namesi <- c("state_code_d", "county_code_d", "state_code_o", "county_code_o",
            "state_abbrv", "county_name", "return", "exmpt", "AGI")
nameso <- c("state_code_o", "county_code_o", "state_code_d", "county_code_d",
            "state_abbrv", "county_name", "return", "exmpt", "AGI")

for (i in files){  
  unzip(i, exdir = tempDir)
  j5  <- list.dirs(tempDir)
  j5i <- list.files(j5[grepl("Inflow", j5)], full.names = T)
  j5o <- list.files(j5[grepl("Outflow", j5)], full.names = T)
  
  indata  <- read_data1(j5i, namesi)
  outdata <- read_data1(j5o, nameso)
  
  unlink(tempDir, recursive = T)
  allindata  <- bind_rows(allindata, indata)
  alloutdata <- bind_rows(alloutdata, outdata)
  rm(indata, outdata)
  print(paste0("Finished ", basename(i), " at ", Sys.time()))
}
# Problem in 1996 where the indata for total US is coded as 1 instead of 0
allindata <- filter(allindata, !(state_code_d == 1 & state_abbrv == "US"))

write_csv(allindata, paste0(localDir, "/inflows9203.csv"))
write_csv(alloutdata, paste0(localDir, "/outflows9203.csv"))


# ---- Data from 2004 to 2013 ---------------------------------------------

inflows  <- c("countyinflow0405.csv", "countyinflow0506.csv",
              "countyinflow0607.csv", "countyinflow0708.csv",
              "countyinflow0809.csv", "countyinflow0910.csv",
              "countyinflow1011.csv", "countyinflow1112.csv",
              "countyinflow1213.csv", "countyinflow1314.csv")

indata   <- sapply(inflows, function(x){
  file       <- paste0(data_source, "/", x)
  if (!file.exists(file)) (download.file(paste0(url, x), file))
  data       <- read_csv(file, col_names = c("state_code_d", "county_code_d",
                                             "state_code_o", "county_code_o",
                                             "state_abbrv", "county_name",
                                             "return", "exmpt", "AGI"),
                         col_types = "iiiicciii", skip = 1)
  data[,c(5:6)]     <- lapply(data[,c(5:6)],
                              function(xx) toupper(str_trim(xx)) )
  data$year  <- 1999 + as.numeric(substr(x, nchar(x) - 5, nchar(x) - 4))
  data$ofips <- data$state_code_o*1000 + data$county_code_o
  data$dfips <- data$state_code_d*1000   + data$county_code_d
  filter(data, !is.na(state_code_d))
}, simplify = F, USE.NAMES = T)

allin <- bind_rows(indata)

write_csv(allin, paste0(localDir, "/inflows0413.csv"))

outflows <- c("countyoutflow0405.csv", "countyoutflow0506.csv",
              "countyoutflow0607.csv", "countyoutflow0708.csv",
              "countyoutflow0809.csv", "countyoutflow0910.csv",
              "countyoutflow1011.csv", "countyoutflow1112.csv",
              "countyoutflow1213.csv", "countyoutflow1314.csv")
outdata  <- sapply(outflows, function(x){
  file       <- paste0(data_source, "/", x)
  if (!file.exists(file)) (download.file(paste0(url, x), file))
  data       <- read_csv(file, col_names = c("state_code_o", "county_code_o",
                                             "state_code_d", "county_code_d",
                                             "state_abbrv", "county_name",
                                             "return", "exmpt", "AGI"),
                         col_types = "iiiicciii", skip = 1)
  data[,c(5:6)]     <- lapply(data[,c(5:6)],
                              function(xx) toupper(str_trim(xx)) )
  data$year  <- 1999 + as.numeric(substr(x, nchar(x) - 5, nchar(x) - 4))
  data$ofips <- data$state_code_o*1000 + data$county_code_o
  data$dfips <- data$state_code_d*1000   + data$county_code_d
  filter(data, !is.na(state_code_o))
}, simplify = F, USE.NAMES = T)

allout <- bind_rows(outdata)

write_csv(allout, paste0(localDir, "/outflows0413.csv"))

rm(indata, outdata)

allindata  <- bind_rows(allindata, allin)
allindata$return  <- ifelse(is.na(allindata$return), -1, allindata$return)
allindata$exmpt   <- ifelse(is.na(allindata$exmpt), -1, allindata$exmpt)
allindata$AGI     <- ifelse(is.na(allindata$AGI), -1, allindata$AGI)
saveRDS(allindata,  file = paste0(localDir, "/inflows9213.rds"))

alloutdata <- bind_rows(alloutdata, allout)
alloutdata$return <- ifelse(is.na(alloutdata$return), -1, alloutdata$return)
alloutdata$exmpt  <- ifelse(is.na(alloutdata$exmpt), -1, alloutdata$exmpt)
alloutdata$AGI    <- ifelse(is.na(alloutdata$AGI), -1, alloutdata$AGI)
saveRDS(alloutdata, file = paste0(localDir, "/outflows9213.rds"))

allindata$key  <- paste0(allindata$ofips, allindata$dfips, allindata$year)
alloutdata$key <- paste0(alloutdata$ofips, alloutdata$dfips, alloutdata$year)

check1 <- allindata$key %in% alloutdata$key
sum(check1)
sum(!check1)

check2 <- alloutdata$key %in% allindata$key
sum(check2)
sum(!check2)

print(paste0("Finished 0-IRS_Mig at ", Sys.time()))

rm(list = ls())
