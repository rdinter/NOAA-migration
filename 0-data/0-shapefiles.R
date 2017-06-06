# Robert Dinterman

print(paste0("Started 0-shapefiles at ", Sys.time()))

#library(cleangeo)
library(maptools)
library(rgdal)

# ---- Read in ZCTA Shapefiles ---------------------------------------------

localDir    <- "0-data/shapefiles"
data_source <- paste0(localDir, "/raw")
if (!file.exists(localDir)) dir.create(localDir)
if (!file.exists(data_source)) dir.create(data_source)

# NEED TO FIGURE OUT WHERE TO HOST THESE ZIP FILES

unzip(paste0(localDir, "/zcta2004.zip"), exdir = data_source)
unzip(paste0(localDir, "/zctapoints2004.zip"), exdir = data_source)

zcta  <- readOGR(data_source, layer = "zcta2004")
zctap <- readOGR(data_source, layer = "zctapoints2004")

row.names(zcta)  <- as.character(zcta$ZIP)
zcta$POP2003     <- ifelse(zcta$POP2003 == -99, NA, zcta$POP2003)

zctap            <- zctap[!duplicated(zctap$ZIP), ]
row.names(zctap) <- as.character(zctap$ZIP)

# ---- Clean-up Shapefile -------------------------------------------------
zcta$ZIP  <- as.numeric(as.character(zcta$ZIP))
zctap$ZIP <- as.numeric(as.character(zctap$ZIP))

aea.proj  <- "+proj=longlat"

zcta      <- spTransform(zcta,CRS(aea.proj))
zctap     <- spTransform(zctap,CRS(aea.proj))

# Rename the area so that I know it is the zip code area
names(zcta)[5]  <- "AREA_zcta"
names(zctap)[5] <- "AREA_zctap"

saveRDS(zcta,  file = paste0(localDir, "/zcta2004.rds"))
saveRDS(zctap, file = paste0(localDir, "/zctap2004.rds"))

# ---- State Map ----------------------------------------------------------
tempDir     <- tempdir()

url  <- paste0("http://dds.cr.usgs.gov/pub/data/",
               "nationalatlas/countyp020_nt00009.tar.gz")
file <- paste(localDir, basename(url) ,sep = "/")
if (!file.exists(file)) download.file(url, file)
untar(file, exdir = tempDir)

# Raw File
all          <- readOGR(tempDir, "countyp020", p4s = "+proj=longlat")
all$FIPS     <- as.numeric(as.character(all$FIPS))
names(all)[8]<- "AREA_cty"

# Unmerged
usa          <- subset(all, FIPS < 57000)
usa          <- subset(usa, subset = !(STATE %in% c("AK", "HI")))
usa$remove   <- usa$FIPS - 1000*as.numeric(as.character(usa$STATE_FIPS))
usa          <- subset(usa, subset = remove != 0)

# Useful for States
state        <- unionSpatialPolygons(usa, usa$STATE)
state        <- SpatialPolygonsDataFrame(state,
                                         as.data.frame(row.names(state)),
                                         match.ID = F)
names(state)  <- "STATE"
state@data    <- data.frame(state@data,usa[match(state$STATE, usa$STATE), ])
state         <- state[order(state$STATE), ]
state         <- spTransform(state, CRS(aea.proj))

writeOGR(state, localDir, "state", "ESRI Shapefile", overwrite_layer = T)
saveRDS(state, file = paste0(localDir, "/state.rds"))

# Useful for Counties
USA        <- unionSpatialPolygons(usa, usa$FIPS)
USA        <- SpatialPolygonsDataFrame(USA, as.data.frame(row.names(USA)),
                                       match.ID = F)
names(USA) <- "FIPS"
USA$FIPS   <- as.numeric(as.character(USA$FIPS))
USA@data   <- data.frame(USA@data,usa[match(USA$FIPS, usa$FIPS), ])
USA        <- USA[order(USA$FIPS), ]
USA        <- spTransform(USA, CRS(aea.proj))

writeOGR(USA, localDir, "Lower48_2010_county", "ESRI Shapefile",
         overwrite_layer = T)
saveRDS(USA, file = paste0(localDir, "/Lower48_2010_county.rds"))

All        <- unionSpatialPolygons(all, all$FIPS)
All        <- SpatialPolygonsDataFrame(All, as.data.frame(row.names(All)),
                                       match.ID = F)
names(All) <- "FIPS"
All$FIPS   <- as.numeric(as.character(All$FIPS))
All@data   <- data.frame(All@data, all[match(All$FIPS, all$FIPS), ])
All        <- All[order(All$FIPS), ]
All        <- spTransform(All, CRS(aea.proj))

saveRDS(All, file = paste0(localDir, "/All_2010_county.rds"))

rm(list = ls())

print(paste0("Finished 0-Shapefiles at ", Sys.time()))