# Katrina Data

library(tidyverse)

mig <- read_rds("1-tidy/migration/ctycty.rds") %>% 
  mutate(dfips = as.numeric(dfips), ofips = as.numeric(ofips),
         year = as.numeric(year))

# Cameron Parish - 023, Orleans Parish - 071, Plaquemines Parish - 075,
#  St. Bernard Parish - 087, and Jefferson Parish - 051
# katrina <- c(22023, 22075, 22071, 22087, 22051)

# Better option: Jefferson - 051, Lafourche - 057, Orleans - 071,
# Plaquemines - 075, St. Bernard - 087, St. Tammany - 103, and Terrebonne - 109
# katrina <- c(22051, 22057, 22071, 22075, 22087, 22103, 22109)

# New Orleans MSA Covers
# Jefferson - 051, Orleans - 071, Plaquemines - 075, St. Bernard - 087,
# St. Charles - 089, St. John the Baptist - 095, and St. Tammany - 103 Parishes
# Extras noted are Lafourche - 057, and Terrebonne - 109
katrina <- c(22051, 22057, 22071, 22075, 22087, 22089, 22095, 22103, 22109)


hurricane <- mig %>% 
  filter(ofips %in% katrina, !(dfips %in% katrina)) %>% 
  select(-ofips, -long_o, -lat_o) %>% 
  group_by(dfips, long_d, lat_d, year) %>% 
  summarise_all(funs(sum(., na.rm = T))) %>% 
  rename(fips = dfips, return_katrina = return,
         exmpt_katrina = exmpt, agi_katrina = agi) %>% 
  arrange(year)

hurricane_newo <- mig %>% 
  filter(dfips %in% katrina, !(ofips %in% katrina)) %>% 
  select(-ofips, -long_o, -lat_o) %>% 
  group_by(dfips, long_d, lat_d, year) %>% 
  summarise_all(funs(sum(., na.rm = T))) %>% 
  rename(fips = dfips, return_katrina = return,
         exmpt_katrina = exmpt, agi_katrina = agi) %>% 
  arrange(year)

hurricane <- hurricane %>% 
  group_by(year) %>% 
  mutate(return_katrina_eyer = return_katrina /
           sum(return_katrina, na.rm = T),
         exmpt_katrina_eyer = exmpt_katrina /
           sum(exmpt_katrina, na.rm = T),
         agi_katrina_eyer = agi_katrina /
           sum(agi_katrina, na.rm = T),
         return_katrina_eyer_noho = return_katrina /
           sum(return_katrina[fips != 48201], na.rm = T),
         exmpt_katrina_eyer_noho = exmpt_katrina /
           sum(exmpt_katrina[fips != 48201], na.rm = T),
         agi_katrina_eyer_noho = agi_katrina /
           sum(agi_katrina[fips != 48201], na.rm = T))

hurricane_newo <- hurricane_newo %>% 
  group_by(year) %>% 
  mutate(return_katrina_eyer = return_katrina /
           sum(return_katrina, na.rm = T),
         exmpt_katrina_eyer = exmpt_katrina /
           sum(exmpt_katrina, na.rm = T),
         agi_katrina_eyer = agi_katrina /
           sum(agi_katrina, na.rm = T),
         return_katrina_eyer_noho = return_katrina /
           sum(return_katrina[fips != 48201], na.rm = T),
         exmpt_katrina_eyer_noho = exmpt_katrina /
           sum(exmpt_katrina[fips != 48201], na.rm = T),
         agi_katrina_eyer_noho = agi_katrina /
           sum(agi_katrina[fips != 48201], na.rm = T))

alternate <- mig %>% 
  group_by(dfips, year) %>% 
  summarise_at(vars(return, exmpt, agi), funs(sum(., na.rm = T))) %>% 
  set_names(c("fips", "year", "return_own", "exmpt_own", "agi_own"))

alternate_newo <- mig %>% 
  group_by(dfips, year) %>% 
  summarise_at(vars(return, exmpt, agi), funs(sum(., na.rm = T))) %>% 
  set_names(c("fips", "year", "return_own", "exmpt_own", "agi_own"))

base <- mig %>% 
  filter(dfips == ofips, !is.na(lat_d)) %>% 
  select(fips = dfips, year, long = long_d, lat = lat_d) %>% 
  left_join(hurricane) %>% 
  left_join(alternate)

base_newo <- mig %>% 
  filter(dfips == ofips, !is.na(lat_d), ofips %in% katrina) %>% 
  select(fips = dfips, year, long = long_d, lat = lat_d) %>% 
  left_join(hurricane_newo) %>% 
  left_join(alternate_newo)

# Euclidean distances are based in kilometers.
base$distance <- sp::spDistsN1(as.matrix(base[,c("long", "lat")]),
                               c(-89.92945,30.06911), longlat = TRUE)

# ---- controls -----------------------------------------------------------

# BLS
base <- read_csv("0-data/random/BLS_lau_mstr.csv") %>% 
  select(fips = full_fips, year, emp = Employed, unemp = Unemployed) %>% 
  right_join(base)

base_newo <- read_csv("0-data/random/BLS_lau_mstr.csv") %>% 
  select(fips = full_fips, year, emp = Employed, unemp = Unemployed) %>% 
  right_join(base_newo)

# Wages
base <- read_csv("0-data/random/BLS_QCEW_redux.csv") %>% 
  rename(fips = FIPS) %>% 
  right_join(base)

base_newo <- read_csv("0-data/random/BLS_QCEW_redux.csv") %>% 
  rename(fips = FIPS) %>% 
  right_join(base_newo)

# Race
base <- read_csv("0-data/random/race_by_county.csv") %>% 
  mutate(fips = as.numeric(fips),
         black_pct = (ba_male + ba_female) / tot_pop,
         female_pct = tot_female / tot_pop,
         county = gsub(" County", "", ctyname),
         county = tolower(gsub(" Parish", "", county))) %>% 
  select(fips, year, tot_pop, black_pct, female_pct, county, stname) %>% 
  right_join(base)

base_newo <- read_csv("0-data/random/race_by_county.csv") %>% 
  mutate(fips = as.numeric(fips),
         black_pct = (ba_male + ba_female) / tot_pop,
         female_pct = tot_female / tot_pop,
         county = gsub(" County", "", ctyname),
         county = tolower(gsub(" Parish", "", county))) %>% 
  select(fips, year, tot_pop, black_pct, female_pct, county, stname) %>% 
  right_join(base_newo)

# Housing
base <- read_csv("0-data/random/medrents_83-17.csv", col_types = "iid") %>%
  rename(fips = FIPS10) %>% 
  right_join(base)

base_newo <- read_csv("0-data/random/medrents_83-17.csv", col_types = "iid") %>%
  rename(fips = FIPS10) %>% 
  right_join(base_newo)

# RUC
base <- read_csv("0-data/random/ruc_codes.csv") %>% 
  right_join(base)

base_newo <- read_csv("0-data/random/ruc_codes.csv") %>% 
  right_join(base_newo)

# FEMA funds
ihp <- read_csv("0-data/FEMA/ihp.csv") %>% 
  select(disasterNumber, year, county, stname,
         totalValidRegistrations:onaAmount) %>% 
  filter(!is.na(stname)) %>% 
  group_by(year, county, stname) %>% 
  summarise_at(vars(-disasterNumber), funs(sum(., na.rm = T)))

base <- left_join(base, ihp)

base_newo <- left_join(base_newo, ihp)

# Disasters by county
disasters <- read_rds("0-data/FEMA/cty_decl_all.rds")

base <- left_join(base, disasters)

base_newo <- left_join(base_newo, disasters)

# Area for each county

ctys <- read_rds("0-data/shapefiles/All_2010_county.rds")
ctys <- select(ctys@data, fips = FIPS, area_sqm = AREA_cty)

base      <- left_join(base, ctys)
base_newo <- left_join(base_newo, ctys)


library(Hmisc)

spline <- rcspline.eval(base$distance, nk = 5, inclx = T)
base$spline1 <- spline[,1]
base$spline2 <- spline[,2]
base$spline3 <- spline[,3]
base$spline4 <- spline[,4]

base$la_dest <- floor(base$fips/1000)==22
base$katrinafips <- base$fips %in% katrina
base$katrina <- base$year == 2005

write_csv(base, "1-tidy/migration/katrina.csv")
write_rds(base, "1-tidy/migration/katrina.rds")

write_csv(base_newo, "1-tidy/migration/katrina_newo.csv")
write_rds(base_newo, "1-tidy/migration/katrina_newo.rds")
