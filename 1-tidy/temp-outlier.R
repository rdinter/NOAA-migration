
# ---- Start --------------------------------------------------------------

library(dplyr)
library(stringr)
median_ <- function(x, n) {combn(rev(x), n - 1, FUN = median, na.rm = T)}
sd_     <- function(x, n) {combn(rev(x), n - 1, FUN = sd, na.rm = T)}
# flag_   <- function(x, n, lev = 7) {(abs(x - median_(x, n)) > 
#                                        7*sd_(x, n))}

netmig <- readRDS("1-tidy/Migration/netmigration.rds") %>% 
  mutate(year = as.character(year), fips = str_pad(fips, 5, pad = "0"))

# ---- Exemptions ---------------------------------------------------------

detected_exmpt <- netmig %>%
  group_by(fips) %>%
  # Outlier detection, but ignore current observation with combn
  mutate(flag_in  = (abs(exmpt_in - median(exmpt_in)) > 
                       4*sd(exmpt_in))) %>% 
  ungroup()

flagged_exmpt <- detected_exmpt %>% 
  group_by(fips) %>% 
  mutate(all_flag = n() == sum(!flag_in)) %>% 
  ungroup() %>% 
  filter(!all_flag) %>% 
  arrange(fips)

flagged_exmpt %>% group_by(fips) %>% 
  mutate(mean_in = mean(exmpt_in), sd_in = sd(exmpt_in),
         flag_factor = exmpt_in / mean_in,
         flag = flag_in | flag_out | flag_net) %>% 
  ungroup() %>% 
  filter(flag) %>%
  arrange(year, fips) -> temp
# write.csv(temp, file = "1-Organization/Migration/exmpt_flag.csv", row.names=F)
