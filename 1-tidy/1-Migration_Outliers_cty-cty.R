
# ---- Start --------------------------------------------------------------

library(dplyr)
library(stringr)
library(tidyr)
median_ <- function(x, n) {as.vector(combn(rev(x), n - 1,
                                           FUN = median, na.rm = T))}
sd_     <- function(x, n) {as.vector(combn(rev(x), n - 1,
                                           FUN = sd, na.rm = T))}
flag_   <- function(x, n, lev = 7) {(abs(x - median_(x, n)) > 
                                       lev*sd_(x, n))}

ctymig <- readRDS("1-tidy/Migration/ctycty.rds") %>% 
  mutate(year = as.character(year), dfips = str_pad(dfips, 5, pad = "0"),
         ofips = str_pad(ofips, 5, pad = "0"))

# --- Exemptions ----------------------------------------------------------

ctymig %>% 
  replace_na(list(return = 1, exmpt = 1, agi = 0)) %>% 
  mutate(hh_agi = agi / return)  %>% 
  filter(hh_agi < -100) -> flag
