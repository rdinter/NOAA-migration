# Robert Dinterman
# Let's download all of the IRS data and then worry about formatting in a 
#  different format. It's from a few places:
# https://www.irs.gov/uac/soi-tax-stats-migration-data
# http://www.irs.gov/uac/SOI-Tax-Stats-County-Data
# http://tinyurl.com/jxnkr73

# ----- start -------------------------------------------------------------

# Create a directory for the data, ignore for GitHub
localDir <- "0-data/IRS"
data_source <- paste0(localDir, "/raw")
if (!file.exists(localDir)) dir.create(localDir)
if (!file.exists(data_source)) dir.create(data_source)

# 1990 up until 2004
# https://www.irs.gov/pub/irs-soi/1990to1991countymigration.zip

year   <- 1990:2003 #the 90 to 92 data are in text files
urls   <- paste0("http://www.irs.gov/file_source/pub/irs-soi/",
                 year, "to", year + 1, "countymigration.zip")
files  <- paste(data_source, paste0("migration", year+1, ".zip"), sep = "/")

map2(urls, files, function(urls, files){
  if (!file.exists(files)) download.file(urls, files, method = "libcurl")
})

# From 2005 fo 2011
# https://www.irs.gov/pub/irs-soi/county0405.zip
# https://www.irs.gov/pub/irs-soi/county1011.zip

dyears   <- c("0405", "0506", "0607", "0708", "0809",
              "0910", "1011", "1112", "1213", "1314")

# From 2012 to beyond
# https://www.irs.gov/pub/irs-soi/1112migrationdata.zip
# https://www.irs.gov/pub/irs-soi/1415migrationdata.zip

tempDir  <- tempfile()
#http://www.irs.gov/uac/SOI-Tax-Stats-Migration-Data

