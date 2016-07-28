
# ---- Start --------------------------------------------------------------

library(dplyr)

netmig <- readRDS("1-Organization/Migration/netmigration.rds")

# ---- Exemptions ---------------------------------------------------------

detected_exmpt <- netmig %>%
  group_by(fips) %>%
  # Outlier detection, but ignore current observation with combn
  mutate(flag_in = (abs(exmpt_in - combn(rev(exmpt_in),n()-1,FUN=median)) >
                      7*combn(rev(exmpt_in), n()-1, FUN = sd)),
         flag_out = (abs(exmpt_out - combn(rev(exmpt_out),n()-1,FUN=median)) >
                       7*combn(rev(exmpt_out), n()-1, FUN = sd)),
         flag_net = (abs(exmpt_net - combn(rev(exmpt_net),n()-1,FUN=median)) >
                       7*combn(rev(exmpt_net), n()-1, FUN = sd))) %>% 
  ungroup()

flagged_exmpt <- detected_exmpt %>% 
  group_by(fips) %>% 
  mutate(all_flag = n() == sum(!flag_in)) %>% 
  ungroup() %>% 
  filter(!all_flag) %>% 
  arrange(fips)

flagged_exmpt %>% group_by(fips) %>% 
  mutate(mean_in = mean(exmpt_in), sd_in = sd(exmpt_in),
         flag_factor = exmpt_in / mean_in) %>% 
  ungroup() %>% 
  filter(flag_in) %>%
  select(year, fips, exmpt_in, mean_in, sd_in, flag_factor) %>% 
  arrange(year, fips) %>% 
  knitr::kable(digits = 0)

# ---- AGI ----------------------------------------------------------------

detected_agi <- netmig %>%
  group_by(fips) %>%
  # Outlier detection, but ignore current observation with combn
  mutate(flag_in = (abs(agi_in - combn(rev(agi_in),n()-1,FUN=median)) >
                      7*combn(rev(agi_in), n()-1, FUN = sd)),
         flag_out = (abs(agi_out - combn(rev(agi_out),n()-1,FUN=median)) >
                       7*combn(rev(agi_out), n()-1, FUN = sd)),
         flag_net = (abs(agi_net - combn(rev(agi_net),n()-1,FUN=median)) >
                       7*combn(rev(agi_net), n()-1, FUN = sd))) %>% 
  ungroup()

flagged_agi <- detected_agi %>% 
  group_by(fips) %>% 
  mutate(all_flag = n() == sum(!flag_net)) %>% 
  ungroup() %>% 
  filter(!all_flag) %>% 
  arrange(fips)

flagged_agi %>% group_by(fips) %>% 
  mutate(mean_in = mean(agi_in), sd_in = sd(agi_in),
         flag_factor = agi_in / mean_in) %>% 
  ungroup() %>% 
  filter(flag_net) %>%
  select(year, fips, agi_in, mean_in, sd_in, flag_factor) %>% 
  arrange(year, fips) %>% 
  knitr::kable(digits = 0)
