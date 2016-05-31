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

allindata  <- readRDS("0-Data/IRS/inflows9213.rds")
alloutdata <- readRDS("0-Data/IRS/outflows9213.rds")
allshp     <- readRDS("0-Data/Shapefiles/All_2010_county.rds")

# ---- Clean --------------------------------------------------------------

# Need to make sure to change the -1 to NA in the flows data, then change
#  classification of values
nonmig <- allindata$state_code_o==63 & allindata$county_code_o==50
allin  <- allindata %>%
  select(year, state_code_d:AGI) %>% 
  mutate(return = replace(return, return == -1 | is.na(return),NA),
         exmpt = replace(exmpt, exmpt == -1 | is.na(exmpt), NA),
         AGI = replace(AGI, is.na(return), NA),
         # Total Migration
         county_code_o = replace(county_code_o,
                                      state_code_o == 0, 0),
         state_code_o = replace(state_code_o,
                                     state_code_o == 0, 96),
         
         # Non-migrants
         state_code_o = replace(state_code_o, nonmig,
                                     state_code_d[nonmig]),
         county_code_o = replace(county_code_o, nonmig,
                                      county_code_d[nonmig]),
         
         # Same State
         state_code_o = replace(state_code_o, state_code_o==63 &
                                       county_code_o %in% c(10, 20), 58),
         county_code_o = replace(county_code_o,state_code_o==63&
                                        county_code_o %in% c(10, 20), 0),
         # Different State
         state_code_o = replace(state_code_o, state_code_o==63 &
                                       county_code_o %in% c(10, 20), 59),
         county_code_o = replace(county_code_o,state_code_o==63&
                                        county_code_o %in% c(10, 20), 0),
         # Northeast
         state_code_o = replace(state_code_o, state_code_o==63 &
                                       county_code_o == 11, 59),
         county_code_o = replace(county_code_o,state_code_o==63&
                                        county_code_o == 11, 1),
         # Midwest
         state_code_o = replace(state_code_o, state_code_o==63 &
                                       county_code_o == 12, 59),
         county_code_o = replace(county_code_o,state_code_o==63&
                                        county_code_o == 12, 3),
         # South
         state_code_o = replace(state_code_o, state_code_o==63 &
                                       county_code_o == 13, 59),
         county_code_o = replace(county_code_o,state_code_o==63&
                                        county_code_o == 13, 5),
         # West
         state_code_o = replace(state_code_o, state_code_o==63 &
                                       county_code_o == 14, 59),
         county_code_o = replace(county_code_o,state_code_o==63&
                                        county_code_o == 14, 7),
         # Foreign Other
         state_code_o = replace(state_code_o, state_code_o==63 &
                                       county_code_o == 15, 57),
         county_code_o = replace(county_code_o,state_code_o==63&
                                        county_code_o == 15, 9)
         )

# Next, need to add in summed foreign values
# NEED TO DEAL WITH THE -1 AND NA VALUES
temp <- allin %>% 
  filter(state_code_o == 57, year < 1995) %>% 
  group_by(year, state_code_d, county_code_d) %>% 
  summarise_each(funs(sum(., na.rm = T)), return:AGI)
temp$state_code_o  <- 98
temp$county_code_o <- 0
allin                   <- bind_rows(allin, temp)

# Finally, we need the US values of 97000 
temp <- allin %>% 
  select(year:county_code_o, return:AGI) %>% 
  filter(state_code_o %in% c(96, 98), year < 1995) %>% 
  gather(key, value, return:AGI) %>% 
  unite(temp, key, state_code_o) %>% 
  spread(temp, value) %>% 
  mutate(return = ifelse(is.na(return_96) & is.na(return_98), NA,
                             ifelse(is.na(return_98), return_96,
                                    return_96 - return_98)),
         exmpt = ifelse(is.na(exmpt_96) & is.na(exmpt_98), NA,
                            ifelse(is.na(exmpt_98), exmpt_96,
                                   exmpt_96 - exmpt_98)),
         AGI = ifelse(is.na(AGI_96) & is.na(AGI_98), NA,
                           ifelse(is.na(AGI_98), AGI_96,
                                  AGI_96 - AGI_98))) %>% 
  select(year:county_code_o, return:AGI)

temp$state_code_o  <- 97
temp$county_code_o <- 0
allin                   <- bind_rows(allin, temp)

allin$fips_o <- 1000*allin$state_code_o + allin$county_code_o
allin$fips_d <- 1000*allin$state_code_d + allin$county_code_d

# OUT DATA
nonmig <- alloutdata$state_code_d == 63 & alloutdata$county_code_d == 50
allout <- alloutdata %>%
  select(year, state_code_o:AGI) %>% 
  mutate(return = replace(return, return == -1 | is.na(return),NA),
         exmpt = replace(exmpt, exmpt == -1 | is.na(exmpt), NA),
         AGI = replace(AGI, is.na(return), NA),
         # Total Migration
         county_code_d = replace(county_code_d,
                                    state_code_d == 0, 0),
         state_code_d = replace(state_code_d,
                                   state_code_d == 0, 96),
         
         # Non-migrants
         state_code_d = replace(state_code_d, nonmig,
                                   state_code_o[nonmig]),
         county_code_d = replace(county_code_d, nonmig,
                                    county_code_o[nonmig]),
         
         # Same State
         state_code_d = replace(state_code_d, state_code_d==63&
                                     county_code_d %in% c(10, 20), 58),
         county_code_d = replace(county_code_d, state_code_d==63&
                                      county_code_d %in% c(10, 20), 0),
         # Different State
         state_code_d = replace(state_code_d, state_code_d==63&
                                     county_code_d %in% c(10, 20), 59),
         county_code_d = replace(county_code_d, state_code_d==63&
                                      county_code_d %in% c(10, 20), 0),
         # Northeast
         state_code_d = replace(state_code_d, state_code_d==63&
                                     county_code_d == 11, 59),
         county_code_d = replace(county_code_d, state_code_d==63&
                                      county_code_d == 11, 1),
         # Midwest
         state_code_d = replace(state_code_d, state_code_d==63&
                                     county_code_d == 12, 59),
         county_code_d = replace(county_code_d, state_code_d==63&
                                      county_code_d == 12, 3),
         # South
         state_code_d = replace(state_code_d, state_code_d==63&
                                     county_code_d == 13, 59),
         county_code_d = replace(county_code_d, state_code_d==63&
                                      county_code_d == 13, 5),
         # West
         state_code_d = replace(state_code_d, state_code_d==63&
                                     county_code_d == 14, 59),
         county_code_d = replace(county_code_d, state_code_d==63&
                                      county_code_d == 14, 7),
         # Foreign Other
         state_code_d = replace(state_code_d, state_code_d==63&
                                     county_code_d == 15, 57),
         county_code_d = replace(county_code_d, state_code_d==63&
                                      county_code_d == 15, 9)
  ) -> allout
# Next, need to add in summed foreign values
# NEED TO DEAL WITH THE -1 AND NA VALUES
temp <- allout %>% 
  filter(state_code_d == 57, year < 1995) %>% 
  group_by(year, state_code_o, county_code_o) %>% 
  summarise_each(funs(sum(., na.rm = T)), return:AGI)
temp$state_code_d  <- 98
temp$county_code_d <- 0
allout                <- bind_rows(allout, temp)

# Finally, we need the US values of 97000 
temp <- allout %>% 
  select(year:county_code_d, return:AGI) %>% 
  filter(state_code_d %in% c(96, 98), year < 1995) %>% 
  gather(key, value, return:AGI) %>% 
  unite(temp, key, state_code_d) %>% 
  spread(temp, value) %>% 
  mutate(return = ifelse(is.na(return_96) & is.na(return_98), NA,
                             ifelse(is.na(return_98), return_96,
                                    return_96 - return_98)),
         exmpt = ifelse(is.na(exmpt_96) & is.na(exmpt_98), NA,
                            ifelse(is.na(exmpt_98), exmpt_96,
                                   exmpt_96 - exmpt_98)),
         AGI = ifelse(is.na(AGI_96) & is.na(AGI_98), NA,
                           ifelse(is.na(AGI_98), AGI_96,
                                  AGI_96 - AGI_98))) %>% 
  select(year:county_code_d, return:AGI)
temp$state_code_d  <- 97
temp$county_code_d <- 0
allout                <- bind_rows(allout, temp)

allout$fips_o <- 1000*allout$state_code_o + allout$county_code_o
allout$fips_d <- 1000*allout$state_code_d + allout$county_code_d

rm(allindata, alloutdata)

# ---- FIPS Issues --------------------------------------------------------

# Checks: when did: Yuma (4027), Broomfield (8014), Cibola (35006) begin;
# 30113 for yellowstone (1990)
trubs <- c("4027", "8014", "35006", "30113")
allin %>%
  filter(fips_d %in% trubs) %>%
  xtabs(~fips_d + year, data = .) # Broomfield not until 2002, checks out.

# AK mentions:
trubs <- c("2070", "2185", "2261", "2030", "2040", "2065", "2120", "2160",
           "2190", "2200", "2230", "2250", "2260",
           
           "2013", "2010", "2016", "2164", "2070", "2188", "2140", "2185",
           
           "2068", "2290", "2240", "2232", "2231", "2282",
           
           "2275", "2280", "2201", "2195", "2198", "2130", "2230", "2232",
           "2105",
           
           "2195", "2105", "2158", "2270")
allin %>%
  filter(fips_d %in% trubs) %>%
  xtabs(~fips_d + year, data = .)

# Next step is to fix any county issues ... new counties and merged counties!
# Need to consider how to do this ... likely just SUM but ignore NA ...
trubs <- c("51013", "51510", "51515", "51520", "51530", "51540", "51560",
           "51570", "51580", "51590", "51595", "51600", "51610", "51620",
           "51630", "51640", "51660", "51670", "51678", "51683", "51685",
           "51690", "51720", "51730", "51750", "51770", "51775", "51780",
           "51790", "51820", "51840")
allin %>%
  filter(fips_d %in% trubs) %>%
  xtabs(~fips_d + year, data = .)
allin %>%
  filter(fips_o %in% trubs) %>%
  xtabs(~fips_o + year, data = .)

allout %>% 
  filter(fips_o %in% trubs) %>% 
  xtabs(~fips_o + year, data = .)

source("1-Organization/1-Migration_functions.R")

allin <- allin %>% 
  mutate(fips_d = fipchange(fips_d), fips_o = fipchange(fips_o)) %>%
  group_by(year, fips_d, fips_o) %>%
  summarise_each(funs(sum(., na.rm = T)), return, exmpt, AGI)
allin$return <- ifelse(allin$return == 0, NA, allin$return)
allin$exmpt  <- ifelse(is.na(allin$return), NA, allin$exmpt)
allin$AGI   <- ifelse(is.na(allin$return), NA, allin$AGI)

allout <- allout %>% 
  mutate(fips_d = fipchange(fips_d), fips_o = fipchange(fips_o)) %>%
  group_by(year, fips_d, fips_o) %>%
  summarise_each(funs(sum(., na.rm = T)), return, exmpt, AGI)
allout$return <- ifelse(allout$return == 0, NA, allout$return)
allout$exmpt  <- ifelse(is.na(allout$return), NA, allout$exmpt)
allout$AGI   <- ifelse(is.na(allout$return), NA, allout$AGI)


# ---- Aggregate Migration ------------------------------------------------

# Two groups: one with only 96000 and the other with cty-cty (incl. 98000)

allintotal  <- allin %>% 
  filter(fips_o == 96000, fips_d < 57000, fips_d %% 1000 != 0) %>% 
  rename(fips = fips_d, IN_Return = return, IN_Exmpt = exmpt,
         IN_AGI = AGI)

allouttotal <- allout %>% 
  filter(fips_d == 96000, fips_o < 57000, fips_o %% 1000 != 0) %>% 
  rename(fips = fips_o, OUT_Return = return, OUT_Exmpt = exmpt,
         OUT_AGI = AGI)

aggdata <- full_join(allintotal, allouttotal)
aggdata <- aggdata %>% 
  select(-fips_d, -fips_o) %>% 
  mutate(NET_Return = IN_Return - OUT_Return,
         NET_Exmpt = IN_Exmpt - OUT_Exmpt,
         NET_AGI = IN_AGI - OUT_AGI)
aggdata <- as.data.frame(aggdata)

save(aggdata, file = paste0(localDir, "/netmigration.Rda"))
write_csv(aggdata, paste0(localDir, "/netmigration.csv"))
rm(allintotal, allouttotal)

# ---- cty2cty ------------------------------------------------------------

incty <- allin %>% 
  filter(fips_d %% 1000 != 0|fips_d == 98000, fips_d < 56999|fips_d == 98000,
         fips_o %% 1000 != 0|fips_o == 98000, fips_o < 56999|fips_o == 98000) %>% 
  mutate(return = replace(return, is.na(return), -1),
         exmpt  = replace(exmpt, is.na(exmpt), -1),
         AGI   = replace(AGI, is.na(AGI), -1)) %>% 
  rename(IN_Return = return, IN_Exmpt = exmpt, IN_AGI = AGI)

outcty <- allout %>% 
  filter(fips_d %% 1000 != 0|fips_d == 98000, fips_d < 56999|fips_d == 98000,
         fips_o %% 1000 != 0|fips_o == 98000, fips_o < 56999|fips_o == 98000) %>% 
  mutate(return = replace(return, is.na(return), -1),
         exmpt  = replace(exmpt, is.na(exmpt), -1),
         AGI   = replace(AGI, is.na(AGI), -1)) %>% 
  rename(OUT_Return = return, OUT_Exmpt = exmpt, OUT_AGI = AGI)

data <- full_join(incty, outcty)

# ----

# Evaluate the matches of IN versus OUT
data %>% 
  group_by(year) %>% 
  summarise(Total = n(),
            Return = sum(IN_Return == OUT_Return, na.rm = T),
            Exmpt  = sum(IN_Exmpt == OUT_Exmpt, na.rm = T),
            AGI    = sum(IN_AGI == OUT_AGI, na.rm = T),
            Match  = paste0(round(100*Return / Total, 1), "%")) %>%
  knitr::kable()

data %>% 
  group_by(year) %>% 
  summarise(Total = n(),
            SupIN  = sum((IN_Return == -1 | is.na(IN_Return)) &
                           (!is.na(OUT_Return)), na.rm = T),
            SupOUT = sum((OUT_Return == -1 | is.na(OUT_Return)) &
                           (!is.na(IN_Return)), na.rm = T),
            BadMatch = paste0(round(100*(SupIN + SupOUT) / Total, 1),
                              "%")) %>%
  knitr::kable()

# ----

data <- data %>% 
  mutate(Return = ifelse(!is.na(IN_Return), IN_Return, OUT_Return),
         Exmpt  = ifelse(!is.na(IN_Exmpt), IN_Exmpt, OUT_Exmpt),
         AGI    = ifelse(!is.na(IN_AGI), IN_AGI, OUT_AGI))
temp <- data$Return == -1
ctycty <- data %>% 
  as.data.frame() %>% 
  select(year:fips_o, Return:AGI) %>% 
  mutate(Return = replace(Return, temp, NA),
         Exmpt  = replace(Exmpt, temp, NA),
         AGI    = replace(AGI, temp, NA))

allshp <- subset(allshp, FIPS < 57000)

check <- ctycty$fips_d %in% allshp$FIPS
unique(ctycty$fips_d[!check])
# [1]  2195  2198  2230  2105  2275 98000

check <- allshp$FIPS %in% ctycty$fips_d
unique(allshp$FIPS[!check])
# [1]  2000  2201  2232  2280 17000 18000 23000 26000 27000 36000 39000
# [12] 42000 53000 55000

coords        <- data.frame(coordinates(allshp))
names(coords) <- c("long", "lat")
coords$fips   <- as.numeric(row.names(coords))

ctycty <- ctycty %>% 
  left_join(coords, by = c("fips_o" = "fips")) %>% 
  rename(long_o = long, lat_o = lat) %>% 
  left_join(coords, by = c("fips_d" = "fips")) %>% 
  rename(long_d = long, lat_d = lat)

write_csv(ctycty, paste0(localDir, "/ctycty.csv"))
save(ctycty, file = paste0(localDir, "/ctycty.Rda"))

rm(list = ls())

print(paste0("Finished 1-Migration_Tidy at ", Sys.time()))