# Robert Dinterman

# Download the FEMA declarations by year

library(lubridate)
library(rvest)
library(stringr)
library(tidyverse)
library(zoo)

# Problem reading in number of fema declarations by year

# fema <- "https://www.fema.gov/disasters/year" %>%
#   read_html() %>%
#   html_nodes(".views-summary") %>% 
#   html_text()
# 
# # fema <- read_delim(fema, col_names = F, delim = "\n")
# 
# fema_year <- gsub("\n              ", ",", fema)
# fema_year <- gsub("\n          \n", "\n", fema_year)
# fema_year <- gsub("\\(", " ", fema_year)
# fema_year <- gsub(")", " ", fema_year)
# 
# 
# fema <- read_csv(fema_year, col_names = F) %>% 
#   mutate_all(funs(as.numeric)) %>% 
#   filter(!is.na(X1))
# 
# names(fema) <- c("year", "declarations")
# 
# write_csv(fema, "0-data/NOAA/fema_declarations.csv")

# ---- openfema -----------------------------------------------------------

local_dir   <- "0-data/FEMA"
data_source <- paste0(local_dir, "/raw")
if (!file.exists(local_dir)) dir.create(local_dir)
if (!file.exists(data_source)) dir.create(data_source)

declarations <- paste0("https://www.fema.gov/api/open/v1/",
                       "DisasterDeclarationsSummaries.csv")
download.file(declarations, paste0(data_source, "/declarations_raw.csv"))

ihp <- paste0("https://www.fema.gov/api/open/v1/",
              "RegistrationIntakeIndividualsHouseholdPrograms.csv")
download.file(ihp, paste0(data_source, "/ihp_raw.csv"))

# Counties data
fips <- read_csv("0-data/random/race_by_county.csv") %>% 
  select(st_name = stname, cty_name = ctyname,
         st_fips = state, cty_fips = county) %>% 
  mutate(st_abrv = state.abb[match(st_name, state.name)]) %>% 
  distinct()

st_fips <- fips %>% 
  select(st_name, st_abrv, st_fips) %>% 
  distinct()

counties <- read_csv(paste0(data_source, "/declarations_raw.csv")) %>% 
  mutate(date = as.Date(substr(declarationDate, 1, 10), "%Y-%m-%d"),
         year = as.numeric(str_sub(date, 1, 4)),
         cty_fips = str_sub(placeCode, -3)) %>% 
  rename(st_abrv = state) %>% 
  left_join(st_fips) %>% 
  left_join(fips)

counties$fips <- 1000*as.numeric(counties$st_fips) +
  as.numeric(counties$cty_fips)

# THERE NEEDS TO BE A CHANGE TO THE FIPS CODES AT SOME POINT
counties$fips <- ifelse(counties$fips == 12025, 12086, counties$fips)

counties_year <- counties %>% 
  filter(!is.na(fips), year > 1963) %>% 
  group_by(year, fips, st_fips, st_abrv, st_name, cty_fips, cty_name) %>% 
  summarise(disasters = n_distinct(disasterNumber),
            ihp = sum(ihProgramDeclared),
            iap = sum(iaProgramDeclared),
            pap = sum(paProgramDeclared),
            hmp = sum(hmProgramDeclared))

# Grab all of the disasters by county prior to 2000....
counties_all <- counties %>% 
  filter(!is.na(fips), year > 1963, year < 2000) %>% 
  group_by(fips, st_fips, st_abrv, st_name, cty_fips, cty_name) %>% 
  summarise(disasters = n_distinct(disasterNumber),
            ihp = sum(ihProgramDeclared),
            iap = sum(iaProgramDeclared),
            pap = sum(paProgramDeclared),
            hmp = sum(hmProgramDeclared))

write_csv(counties_year, paste0(local_dir, "/cty_decl_year.csv"))
write_csv(counties_all, paste0(local_dir, "/cty_decl_all.csv"))
write_rds(counties_year, paste0(local_dir, "/cty_decl_year.rds"))
write_rds(counties_all, paste0(local_dir, "/cty_decl_all.rds"))

# Rest

declarations <- read_csv(paste0(data_source, "/declarations_raw.csv")) %>% 
  mutate(date = as.Date(substr(declarationDate, 1, 10), "%Y-%m-%d"),
         yearmon = as.yearmon(date),
         year = as.numeric(substr(date, 1, 4))) %>% 
  select(date, yearmon, year, disasterNumber, incidentType) %>% 
  distinct()

# Add in the ihp values from the declarations
ihp <- read_csv(paste0(data_source, "/ihp_raw.csv")) %>%
  mutate(county = tolower(gsub("\\s*\\(.*", "", county)),
         stname = state.name[match(state, state.abb)]) %>% 
  select(-hash, -lastRefresh, -state) %>% 
  left_join(declarations)

write_csv(ihp, paste0(local_dir, "/ihp.csv"))
