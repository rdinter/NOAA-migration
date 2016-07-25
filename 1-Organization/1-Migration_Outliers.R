
# ---- Start --------------------------------------------------------------

library(dplyr)

netmig <- readRDS("1-Organization/Migration/netmigration.rds")

detected <- netmig %>%
  group_by(fips) %>%
  # Outlier detection, but ignore current observation with combn
  mutate(flag = (abs(return_in - combn(rev(return_in), n()-1, FUN = median)) >
                   7*combn(rev(return_in), n()-1, FUN = sd))) %>% 
  ungroup()

flagged <- detected %>% 
  group_by(fips) %>% 
  mutate(all_flag = n() == sum(!flag)) %>% 
  ungroup() %>% 
  filter(!all_flag) %>% 
  arrange(fips)

# ---- Display ------------------------------------------------------------

flagged %>% group_by(fips) %>% 
  mutate(mean_in = mean(return_in), sd_in = sd(return_in),
         flag_factor = return_in / mean_in) %>% 
  ungroup() %>% 
  filter(flag) %>%
  select(year, fips, return_in, mean_in, sd_in, flag_factor) %>% 
  arrange(year, fips) %>% 
  knitr::kable(digits = 0)