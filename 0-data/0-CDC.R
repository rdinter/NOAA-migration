# Robert Dinterman
# Social Vulnerability Index

library(Hmisc)
library(tidyverse)

local_dir   <- "0-data/CDC"
data_source <- paste0(local_dir, "/raw")
if (!file.exists(local_dir)) dir.create(local_dir)
if (!file.exists(data_source)) dir.create(data_source)

dl <- "https://svi.cdc.gov/Documents/Data/2000_SVI_Data/US_2000_SVI.zip"
cdc_file <- paste(data_source, basename(dl), sep = "/")

if (!file.exists(cdc_file)) download.file(dl, cdc_file)
download.file(paste0("https://svi.cdc.gov/Documents/Data/2000_SVI_Data/",
                     "SVI2000DataDictionary.pdf"),
              paste0(local_dir, "/SVI2000DataDictionary.pdf"))

datar <- mdb.get(unzip("0-data/CDC/raw/US_2000_SVI.zip"))

# How many tables?
names(datar)

# What's in the most important table?
names(datar[["US_National_2000_SVI"]])
glimpse(datar[["US_National_2000_SVI"]])

# How many FIPS?
length(unique(datar[["US_National_2000_SVI"]][["STCOFIPS"]]))

svi_shape <- datar[["US_National_2000_SVI_Shape_Index"]]

