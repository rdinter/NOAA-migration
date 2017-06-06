# Robert Dinterman

# ---- Start --------------------------------------------------------------

print(paste0("Started 1-migration_controls_tidy at ", Sys.time()))

# library(dplyr)
# library(maptools)
# library(readr)
# library(tidyr)

# Create a directory for the data
localDir <- "1-tidy/migration"
if (!file.exists(localDir)) dir.create(localDir)

ctycty <- readRDS(paste0(localDir,"/ctycty.rds"))
netmig <- readRDS(paste0(localDir,"/netmigration.rds"))
