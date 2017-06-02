# Robert Dinterman

# Download the FEMA declarations by year

library(lubridate)
library(rvest)
library(tidyverse)
library(zoo)

fema <- "https://www.fema.gov/disasters/grid/year" %>%
  read_html() %>%
  html_nodes(".views-summary") %>% 
  html_text()

# fema <- read_delim(fema, col_names = F, delim = "\n")

fema_year <- gsub("\n              ", ",", fema)
fema_year <- gsub("\n          \n", "\n", fema_year)
fema_year <- gsub("\\(", " ", fema_year)
fema_year <- gsub(")", " ", fema_year)


fema <- read_csv(fema_year, col_names = F) %>% 
  mutate_each(funs(as.numeric)) %>% 
  filter(!is.na(X1))

names(fema) <- c("year", "declarations")

write_csv(fema, "0-Data/NOAA/fema_declarations.csv")

# ---- openfema -----------------------------------------------------------

local_dir   <- "0-Data/FEMA"
data_source <- paste0(local_dir, "/raw")
if (!file.exists(local_dir)) dir.create(local_dir)
if (!file.exists(data_source)) dir.create(data_source)

declarations <- "https://www.fema.gov/api/open/v1/DisasterDeclarationsSummaries.csv"
download.file(declarations, paste0(data_source, "/declarations_raw.csv"))

ihp <- "https://www.fema.gov/api/open/v1/RegistrationIntakeIndividualsHouseholdPrograms.csv"
download.file(ihp, paste0(data_source, "/ihp_raw.csv"))

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
