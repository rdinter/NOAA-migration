# Robert Dinterman

# ---- Start --------------------------------------------------------------

print(paste0("Started 1-Migration_Tidy at ", Sys.time()))

library(dplyr)
library(maptools)
library(readr)
library(tidyr)

# Create a directory for the data
localDir <- "1-Organization/Migration"
if (!file.exists(localDir)) dir.create(localDir)

allinflow  <- readRDS("0-Data/IRS/inflows9213.rds")
alloutflow <- readRDS("0-Data/IRS/outflows9213.rds")
allshp     <- readRDS("0-Data/Shapefiles/All_2010_county.rds")

# ---- Clean --------------------------------------------------------------

# Need to make sure to change the -1 to NA in the flows data, then change
#  classification of values
nonmig <- allinflow$st_fips_o == 63 & allinflow$cty_fips_o==50
allin  <- allinflow %>%
  select(year, st_fips_d:agi) %>% 
  mutate(return = replace(return, return == -1 | is.na(return),NA),
         exmpt = replace(exmpt, exmpt == -1 | is.na(exmpt), NA),
         agi = replace(agi, is.na(return), NA),
         # Total Migration
         cty_fips_o = replace(cty_fips_o, st_fips_o == 0, 0),
         st_fips_o  = replace(st_fips_o, st_fips_o == 0, 96),
         
         # Non-migrants
         st_fips_o  = replace(st_fips_o, nonmig, st_fips_d[nonmig]),
         cty_fips_o = replace(cty_fips_o, nonmig, cty_fips_d[nonmig]),
         
         # Same State
         st_fips_o  = replace(st_fips_o,
                              st_fips_o == 63 & cty_fips_o %in% c(10, 20), 58),
         cty_fips_o = replace(cty_fips_o,
                              st_fips_o == 63 & cty_fips_o %in% c(10, 20), 0),
         # Different State
         st_fips_o  = replace(st_fips_o,
                              st_fips_o == 63 & cty_fips_o %in% c(10, 20), 59),
         cty_fips_o = replace(cty_fips_o,
                              st_fips_o == 63 & cty_fips_o %in% c(10, 20), 0),
         # Northeast
         st_fips_o  = replace(st_fips_o,st_fips_o == 63 & cty_fips_o == 11, 59),
         cty_fips_o = replace(cty_fips_o,st_fips_o == 63 & cty_fips_o == 11, 1),
         # Midwest
         st_fips_o  = replace(st_fips_o,st_fips_o == 63 & cty_fips_o == 12, 59),
         cty_fips_o = replace(cty_fips_o,st_fips_o == 63 & cty_fips_o == 12, 3),
         # South
         st_fips_o  = replace(st_fips_o,st_fips_o == 63 & cty_fips_o == 13, 59),
         cty_fips_o = replace(cty_fips_o,st_fips_o == 63 & cty_fips_o == 13, 5),
         # West
         st_fips_o  = replace(st_fips_o,st_fips_o == 63 & cty_fips_o == 14, 59),
         cty_fips_o = replace(cty_fips_o,st_fips_o == 63 & cty_fips_o == 14, 7),
         # Foreign Other
         st_fips_o  = replace(st_fips_o,st_fips_o == 63 & cty_fips_o == 15, 57),
         cty_fips_o = replace(cty_fips_o,st_fips_o == 63 & cty_fips_o == 15, 9)
         )

# Next, need to add in summed foreign values
# NEED TO DEAL WITH THE -1 AND NA VALUES
temp <- allin %>% 
  filter(st_fips_o == 57, year < 1995) %>% 
  group_by(year, st_fips_d, cty_fips_d) %>% 
  summarise_each(funs(sum(., na.rm = T)), return:agi)
temp$st_fips_o  <- 98
temp$cty_fips_o <- 0
allin           <- bind_rows(allin, temp)

# Finally, we need the US values of 97000 
temp <- allin %>% 
  select(year:cty_fips_o, return:agi) %>% 
  filter(st_fips_o %in% c(96, 98), year < 1995) %>% 
  gather(key, value, return:agi) %>% 
  unite(temp, key, st_fips_o) %>% 
  spread(temp, value) %>% 
  mutate(return = ifelse(is.na(return_96) & is.na(return_98), NA,
                             ifelse(is.na(return_98), return_96,
                                    return_96 - return_98)),
         exmpt = ifelse(is.na(exmpt_96) & is.na(exmpt_98), NA,
                            ifelse(is.na(exmpt_98), exmpt_96,
                                   exmpt_96 - exmpt_98)),
         agi = ifelse(is.na(agi_96) & is.na(agi_98), NA,
                           ifelse(is.na(agi_98), agi_96,
                                  agi_96 - agi_98))) %>% 
  select(year:cty_fips_o, return:agi)

temp$st_fips_o  <- 97
temp$cty_fips_o <- 0
allin           <- bind_rows(allin, temp)

allin$ofips <- 1000*allin$st_fips_o + allin$cty_fips_o
allin$dfips <- 1000*allin$st_fips_d + allin$cty_fips_d

# OUT DATA
nonmig <- alloutflow$st_fips_d == 63 & alloutflow$cty_fips_d == 50
allout <- alloutflow %>%
  select(year, st_fips_o:agi) %>% 
  mutate(return = replace(return, return == -1 | is.na(return),NA),
         exmpt  = replace(exmpt, exmpt == -1 | is.na(exmpt), NA),
         agi    = replace(agi, is.na(return), NA),
         # Total Migration
         cty_fips_d = replace(cty_fips_d, st_fips_d == 0, 0),
         st_fips_d  = replace(st_fips_d, st_fips_d == 0, 96),
         
         # Non-migrants
         st_fips_d  = replace(st_fips_d, nonmig, st_fips_o[nonmig]),
         cty_fips_d = replace(cty_fips_d, nonmig, cty_fips_o[nonmig]),
         
         # Same State
         st_fips_d  = replace(st_fips_d,
                              st_fips_d == 63 & cty_fips_d %in% c(10, 20), 58),
         cty_fips_d = replace(cty_fips_d,
                              st_fips_d == 63 & cty_fips_d %in% c(10, 20), 0),
         # Different State
         st_fips_d = replace(st_fips_d,
                             st_fips_d == 63 & cty_fips_d %in% c(10, 20), 59),
         cty_fips_d = replace(cty_fips_d,
                              st_fips_d == 63 & cty_fips_d %in% c(10, 20), 0),
         # Northeast
         st_fips_d = replace(st_fips_d,st_fips_d == 63 & cty_fips_d == 11, 59),
         cty_fips_d = replace(cty_fips_d,st_fips_d == 63 & cty_fips_d == 11, 1),
         # Midwest
         st_fips_d = replace(st_fips_d,st_fips_d == 63 & cty_fips_d == 12, 59),
         cty_fips_d = replace(cty_fips_d,st_fips_d == 63 & cty_fips_d == 12, 3),
         # South
         st_fips_d = replace(st_fips_d,st_fips_d == 63 & cty_fips_d == 13, 59),
         cty_fips_d = replace(cty_fips_d,st_fips_d == 63 & cty_fips_d == 13, 5),
         # West
         st_fips_d = replace(st_fips_d,st_fips_d == 63 & cty_fips_d == 14, 59),
         cty_fips_d = replace(cty_fips_d,st_fips_d == 63 & cty_fips_d == 14, 7),
         # Foreign Other
         st_fips_d = replace(st_fips_d,st_fips_d == 63 & cty_fips_d == 15, 57),
         cty_fips_d = replace(cty_fips_d,st_fips_d == 63 & cty_fips_d == 15, 9)
  )

# Next, need to add in summed foreign values
# NEED TO DEAL WITH THE -1 AND NA VALUES
temp <- allout %>% 
  filter(st_fips_d == 57, year < 1995) %>% 
  group_by(year, st_fips_o, cty_fips_o) %>% 
  summarise_each(funs(sum(., na.rm = T)), return:agi)
if (nrow(temp) > 0){
  temp$st_fips_d  <- 98
  temp$cty_fips_d <- 0
  allout          <- bind_rows(allout, temp)
}

# Finally, we need the US values of 97000 
temp <- allout %>% 
  select(year:cty_fips_d, return:agi) %>% 
  filter(st_fips_d %in% c(96, 98), year < 1995)
if (nrow(temp) > 0) {
  temp <- temp %>% 
    gather(key, value, return:agi) %>% 
    unite(temp, key, st_fips_d) %>% 
    spread(temp, value) %>% 
    mutate(return = ifelse(is.na(return_96) & is.na(return_98), NA,
                           ifelse(is.na(return_98), return_96,
                                  return_96 - return_98)),
           exmpt = ifelse(is.na(exmpt_96) & is.na(exmpt_98), NA,
                          ifelse(is.na(exmpt_98), exmpt_96,
                                 exmpt_96 - exmpt_98)),
           agi = ifelse(is.na(agi_96) & is.na(agi_98), NA,
                        ifelse(is.na(agi_98), agi_96,
                               agi_96 - agi_98))) %>% 
    select(year:cty_fips_d, return:agi)
  temp$st_fips_d  <- 97
  temp$cty_fips_d <- 0
  allout          <- bind_rows(allout, temp)
}

allout$ofips <- 1000*allout$st_fips_o + allout$cty_fips_o
allout$dfips <- 1000*allout$st_fips_d + allout$cty_fips_d

rm(allinflow, alloutflow)

# ---- FIPS Issues --------------------------------------------------------

# Checks: when did: Yuma (4027), Broomfield (8014), Cibola (35006) begin;
# 30113 for yellowstone (1990)
trubs <- c("4027", "8014", "35006", "30113")
allin %>%
  filter(dfips %in% trubs) %>%
  xtabs(~dfips + year, data = .) # Broomfield not until 2002, checks out.

# AK mentions:
trubs <- c("2070", "2185", "2261", "2030", "2040", "2065", "2120", "2160",
           "2190", "2200", "2230", "2250", "2260",
           
           "2013", "2010", "2016", "2164", "2070", "2188", "2140", "2185",
           
           "2068", "2290", "2240", "2232", "2231", "2282",
           
           "2275", "2280", "2201", "2195", "2198", "2130", "2230", "2232",
           "2105",
           
           "2195", "2105", "2158", "2270")
allin %>%
  filter(dfips %in% trubs) %>%
  xtabs(~dfips + year, data = .)

# Next step is to fix any county issues ... new counties and merged counties!
# Need to consider how to do this ... likely just SUM but ignore NA ...
trubs <- c("51013", "51510", "51515", "51520", "51530", "51540", "51560",
           "51570", "51580", "51590", "51595", "51600", "51610", "51620",
           "51630", "51640", "51660", "51670", "51678", "51683", "51685",
           "51690", "51720", "51730", "51750", "51770", "51775", "51780",
           "51790", "51820", "51840")
allin %>%
  filter(dfips %in% trubs) %>%
  xtabs(~dfips + year, data = .)
allin %>%
  filter(ofips %in% trubs) %>%
  xtabs(~ofips + year, data = .)

allout %>% 
  filter(ofips %in% trubs) %>% 
  xtabs(~ofips + year, data = .)

source("1-Organization/1-Migration_functions.R")

allin         <- allin %>% 
  mutate(dfips = fipchange(dfips), ofips = fipchange(ofips)) %>%
  group_by(year, dfips, ofips) %>%
  summarise_each(funs(sum(., na.rm = T)), return, exmpt, agi)
allin$return  <- ifelse(allin$return == 0, NA, allin$return)
allin$exmpt   <- ifelse(is.na(allin$return), NA, allin$exmpt)
allin$agi     <- ifelse(is.na(allin$return), NA, allin$agi)

allout        <- allout %>% 
  mutate(dfips = fipchange(dfips), ofips = fipchange(ofips)) %>%
  group_by(year, dfips, ofips) %>%
  summarise_each(funs(sum(., na.rm = T)), return, exmpt, agi)
allout$return <- ifelse(allout$return == 0, NA, allout$return)
allout$exmpt  <- ifelse(is.na(allout$return), NA, allout$exmpt)
allout$agi    <- ifelse(is.na(allout$return), NA, allout$agi)


# ---- Aggregate Migration ------------------------------------------------

# Two groups: one with only 96000 and the other with cty-cty (incl. 98000)

allintotal  <- allin %>% 
  filter(ofips == 96000, dfips < 57000, dfips %% 1000 != 0) %>% 
  rename(fips = dfips, return_in = return, exmpt_in = exmpt, agi_in = agi)

allouttotal <- allout %>% 
  filter(dfips == 96000, ofips < 57000, ofips %% 1000 != 0) %>% 
  rename(fips = ofips, return_out = return, exmpt_out = exmpt, agi_out = agi)

aggflow <- full_join(allintotal, allouttotal)
aggflow <- aggflow %>% 
  select(-dfips, -ofips) %>% 
  mutate(return_net = return_in - return_out,
         exmpt_net = exmpt_in - exmpt_out,
         agi_net = agi_in - agi_out)
aggflow <- as.data.frame(aggflow)

saveRDS(aggflow, file = paste0(localDir, "/netmigration.rds"))
write_csv(aggflow, paste0(localDir, "/netmigration.csv"))
rm(allintotal, allouttotal)

# ---- cty2cty ------------------------------------------------------------

incty <- allin %>% 
  filter(dfips %% 1000 != 0|dfips == 98000, dfips < 56999|dfips == 98000,
         ofips %% 1000 != 0|ofips == 98000, ofips < 56999|ofips == 98000) %>% 
  mutate(return = replace(return, is.na(return), -1),
         exmpt  = replace(exmpt, is.na(exmpt), -1),
         agi   = replace(agi, is.na(agi), -1)) %>% 
  rename(return_in = return, exmpt_in = exmpt, agi_in = agi)

outcty <- allout %>% 
  filter(dfips %% 1000 != 0|dfips == 98000, dfips < 56999|dfips == 98000,
         ofips %% 1000 != 0|ofips == 98000, ofips < 56999|ofips == 98000) %>% 
  mutate(return = replace(return, is.na(return), -1),
         exmpt  = replace(exmpt, is.na(exmpt), -1),
         agi   = replace(agi, is.na(agi), -1)) %>% 
  rename(return_out = return, exmpt_out = exmpt, agi_out = agi)

flow <- full_join(incty, outcty)

# ----

# Evaluate the matches of IN versus OUT
flow %>% 
  group_by(year) %>% 
  summarise(Total = n(),
            return = sum(return_in == return_out, na.rm = T),
            exmpt  = sum(exmpt_in == exmpt_out, na.rm = T),
            agi    = sum(agi_in == agi_out, na.rm = T),
            Match  = paste0(round(100*return / Total, 1), "%")) %>%
  knitr::kable()

flow %>% 
  group_by(year) %>% 
  summarise(Total = n(),
            SupIN  = sum((return_in == -1 | is.na(return_in)) &
                           (!is.na(return_out)), na.rm = T),
            SupOUT = sum((return_out == -1 | is.na(return_out)) &
                           (!is.na(return_in)), na.rm = T),
            BadMatch = paste0(round(100*(SupIN + SupOUT) / Total, 1),
                              "%")) %>%
  knitr::kable()

# ----

flow <- flow %>% 
  mutate(return = ifelse(!is.na(return_in), return_in, return_out),
         exmpt  = ifelse(!is.na(exmpt_in), exmpt_in, exmpt_out),
         agi    = ifelse(!is.na(agi_in), agi_in, agi_out))
temp <- flow$return == -1
ctycty <- flow %>% 
  as.data.frame() %>% 
  select(year:ofips, return:agi) %>% 
  mutate(return = replace(return, temp, NA),
         exmpt  = replace(exmpt, temp, NA),
         agi    = replace(agi, temp, NA))

allshp <- subset(allshp, FIPS < 57000)

check <- ctycty$dfips %in% allshp$FIPS
unique(ctycty$dfips[!check])
# [1]  2195  2198  2230  2105  2275 98000

check <- allshp$FIPS %in% ctycty$dfips
unique(allshp$FIPS[!check])
# [1]  2000  2201  2232  2280 17000 18000 23000 26000 27000 36000 39000
# [12] 42000 53000 55000

coords        <- data.frame(coordinates(allshp))
names(coords) <- c("long", "lat")
coords$fips   <- as.numeric(row.names(coords))

ctycty <- ctycty %>% 
  left_join(coords, by = c("ofips" = "fips")) %>% 
  rename(long_o = long, lat_o = lat) %>% 
  left_join(coords, by = c("dfips" = "fips")) %>% 
  rename(long_d = long, lat_d = lat)

write_csv(ctycty, paste0(localDir, "/ctycty.csv"))
saveRDS(ctycty, file = paste0(localDir, "/ctycty.rds"))

print(paste0("Finished 1-Migration_Tidy at ", Sys.time()))

rm(list = ls())

