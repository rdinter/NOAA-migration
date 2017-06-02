#Robert Dinterman
#Robert Dinterman

excel_sheets <- function(path) {
  quiet_excel_sheets <- purrr::quietly(readxl::excel_sheets)
  out <- quiet_excel_sheets(path)
  if(length(c(out[["warnings"]], out[["messages"]])) == 0)
    return(out[["result"]])
  else readxl::excel_sheets(path)
}

read_excel <-  function(...) {
  quiet_read <- purrr::quietly(readxl::read_excel)
  out <- quiet_read(...)
  if(length(c(out[["warnings"]], out[["messages"]])) == 0)
    return(out[["result"]])
  else readxl::read_excel(...)
}

# ---- 0-IRS_Mig.R --------------------------------------------------------

#Problem for excel files with "us" from 1998.99 until 2001.2
read_excel1 <- function(file){
  require(readxl)
  dat   <- read_excel(file)
  dat   <- dat[, c(1:9)]
  #dat   <- dat[c(8:nrow(dat)), c(1:9)]
  return(dat)
}
read_excel2 <- function(file){
  require(gdata)
  dat   <- read.xls(file)
  dat   <- dat[c(4:nrow(dat)), c(1:9)]
  return(dat)
}
Mode <- function(x) {
  ux <- unique(x)
  ux[which.max(tabulate(match(x, ux)))]
}

read_data1 <- function(j5i, namesi, inflow = T){
  require(gdata)
  require(readxl)
  require(tidyverse)
  indata <- map(j5i, function(x){
    dat <- tryCatch(read_excel1(x), error = function(e){
      read_excel2(x)
    })
    
    dat[,c(1:4,7:9)] <- lapply(dat[,c(1:4,7:9)],
                               function(xx){ # Sometimes characters in values
                                 as.numeric(
                                   gsub(",", "", 
                                        gsub("[A-z]", "", xx)))
                               })
    dat[,c(5:6)]     <- lapply(dat[,c(5:6)], function(xx) toupper(xx) )
    names(dat)       <- namesi
    
    if (inflow) {
      dat           <- filter(dat, !is.na(st_fips_d))
      dat$st_fips_d <- Mode(dat$st_fips_d)
    } else {
      dat           <- filter(dat, !is.na(st_fips_o))
      dat$st_fips_o <- Mode(dat$st_fips_o)
    }
    
    
    dat$ofips <- dat$st_fips_o*1000 + dat$cty_fips_o
    dat$dfips <- dat$st_fips_d*1000   + dat$cty_fips_d
    dat
  }, simplify = F, USE.NAMES = T)
  indata      <- bind_rows(indata)
  indata$year <- as.numeric(substr(basename(i), 1, 4))
  return(indata)
}

print(paste0("Started 0-IRS_Mig at ", Sys.time()))

library(tidyverse)

source("0-Data/0-functions.R")


# Create a directory for the data, ignore for GitHub
localDir <- "0-Data/IRS"
data_source <- paste0(localDir, "/raw")
if (!file.exists(localDir)) dir.create(localDir)
if (!file.exists(data_source)) dir.create(data_source)

tempDir  <- tempfile()

# ---- IRS Migration Data for 1992 to 2004 --------------------------------
#http://www.irs.gov/uac/SOI-Tax-Stats-Migration-Data

year   <- 1992:2003 #the 90 to 92 data are in text files
urls   <- paste0("http://www.irs.gov/file_source/pub/irs-soi/",
                 year, "to", year + 1, "countymigration.zip")
files  <- paste(data_source, basename(urls), sep = "/")

map2(urls, files, function(urls, files){
  if (!file.exists(files)) download.file(urls, files, method = "libcurl")
})



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
