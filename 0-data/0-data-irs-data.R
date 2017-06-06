# Robert Dinterman
# Let's download all of the IRS data and then worry about formatting in a 
#  different format. It's from:
# https://www.irs.gov/uac/soi-tax-stats-migration-data

# ----- start -------------------------------------------------------------

# Create a directory for the data, ignore for GitHub
localDir <- "0-data/IRS"
data_source <- paste0(localDir, "/raw")
if (!file.exists(localDir)) dir.create(localDir)
if (!file.exists(data_source)) dir.create(data_source)

# 1990 up until 2004
# https://www.irs.gov/pub/irs-soi/1990to1991countymigration.zip

# From 2005 fo 2011
# https://www.irs.gov/pub/irs-soi/county0405.zip
# https://www.irs.gov/pub/irs-soi/county1011.zip

# From 2012 to beyond
# https://www.irs.gov/pub/irs-soi/1112migrationdata.zip
# https://www.irs.gov/pub/irs-soi/1415migrationdata.zip

tempDir  <- tempfile()
#http://www.irs.gov/uac/SOI-Tax-Stats-Migration-Data

year   <- 1992:2003 #the 90 to 92 data are in text files
urls   <- paste0("http://www.irs.gov/file_source/pub/irs-soi/",
                 year, "to", year + 1, "countymigration.zip")
files  <- paste(data_source, basename(urls), sep = "/")

map2(urls, files, function(urls, files){
  if (!file.exists(files)) download.file(urls, files, method = "libcurl")
})
