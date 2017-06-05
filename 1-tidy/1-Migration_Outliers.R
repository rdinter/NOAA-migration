
# ---- Start --------------------------------------------------------------

library(dplyr)
library(stringr)
median_ <- function(x, n) {as.vector(combn(rev(x), n - 1,
                                           FUN = median, na.rm = T))}
sd_     <- function(x, n) {as.vector(combn(rev(x), n - 1,
                                           FUN = sd, na.rm = T))}
flag_   <- function(x, n, lev = 7) {(abs(x - median_(x, n)) > 
                                       lev*sd_(x, n))}

netmig <- readRDS("1-tidy/Migration/netmigration.rds") %>% 
  mutate(year = as.character(year), fips = str_pad(fips, 5, pad = "0"))

# ---- Exemptions ---------------------------------------------------------

detected_exmpt <- netmig %>%
  group_by(fips) %>%
  # Outlier detection, but ignore current observation with combn
  mutate(flag_in  = flag_(exmpt_in,  n()),
         flag_out = flag_(exmpt_out, n()),
         flag_net = flag_(exmpt_net, n())) %>% 
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

# ---- Exmpt Display ------------------------------------------------------

flagged_exmpt %>% group_by(fips) %>% 
  mutate(mean_in = mean(exmpt_in), sd_in = sd(exmpt_in),
         flag_factor = exmpt_in / mean_in) %>% 
  ungroup() %>% 
  filter(flag_in) %>%
  select(year, fips, exmpt_in, mean_in, sd_in, flag_factor) %>% 
  arrange(year, fips) %>% 
  knitr::kable(digits = 0, format.args = list(big.mark = ","),
               caption = "Flagged Outliers for In")

flagged_exmpt %>% group_by(fips) %>% 
  mutate(mean_out = mean(exmpt_out), sd_out = sd(exmpt_out),
         flag_factor = exmpt_out / mean_out) %>% 
  ungroup() %>% 
  filter(flag_out) %>%
  select(year, fips, exmpt_out, mean_out, sd_out, flag_factor) %>% 
  arrange(year, fips) %>% 
  knitr::kable(digits = 0, format.args = list(big.mark = ","),
               caption = "Flagged Outliers for Out")

flagged_exmpt %>% group_by(fips) %>% 
  mutate(mean_net = mean(exmpt_net), sd_net = sd(exmpt_net),
         flag_factor = exmpt_net / mean_net) %>% 
  ungroup() %>% 
  filter(flag_net) %>%
  select(year, fips, exmpt_net, mean_net, sd_net, flag_factor) %>% 
  arrange(year, fips) %>% 
  knitr::kable(digits = 0, format.args = list(big.mark = ","),
               caption = "Flagged Outliers for Net")


# ---- AGI ----------------------------------------------------------------

detected_agi <- netmig %>%
  group_by(fips) %>%
  # Outlier detection, but ignore current observation with combn
  mutate(flag_in  = flag_(agi_in,  n()),
         flag_out = flag_(agi_out, n()),
         flag_net = flag_(agi_net, n())) %>% 
  ungroup()

flagged_agi <- detected_agi %>% 
  group_by(fips) %>% 
  mutate(all_flag = n() == sum(!flag_net)) %>% 
  ungroup() %>% 
  filter(!all_flag) %>% 
  arrange(fips)

flagged_agi %>% group_by(fips) %>% 
  mutate(mean_in = mean(agi_in), sd_in = sd(agi_in),
         flag_factor = agi_in / mean_in,
         flag = flag_in | flag_out | flag_net) %>% 
  ungroup() %>% 
  filter(flag) %>%
  select(year, fips, agi_in, mean_in, sd_in, flag_factor) %>% 
  arrange(year, fips) -> temp
# write.csv(temp, file = "1-Organization/Migration/agi_flag.csv", row.names=F)


# ---- AGI Display --------------------------------------------------------

flagged_agi %>% group_by(fips) %>% 
  mutate(mean_in = mean(agi_in), sd_in = sd(agi_in),
         flag_factor = agi_in / mean_in) %>% 
  ungroup() %>% 
  filter(flag_in) %>%
  select(year, fips, agi_in, mean_in, sd_in, flag_factor) %>% 
  arrange(year, fips) %>% 
  knitr::kable(digits = 0, format.args = list(big.mark = ","),
               caption = "Flagged Outliers for In")

flagged_agi %>% group_by(fips) %>% 
  mutate(mean_out = mean(agi_out), sd_out = sd(agi_out),
         flag_factor = agi_out / mean_out) %>% 
  ungroup() %>% 
  filter(flag_out) %>%
  select(year, fips, agi_out, mean_out, sd_out, flag_factor) %>% 
  arrange(year, fips) %>% 
  knitr::kable(digits = 0, format.args = list(big.mark = ","),
               caption = "Flagged Outliers for Out")

flagged_agi %>% group_by(fips) %>% 
  mutate(mean_net = mean(agi_net), sd_net = sd(agi_net),
         flag_factor = agi_net / mean_net) %>% 
  ungroup() %>% 
  filter(flag_net) %>%
  select(year, fips, agi_net, mean_net, sd_net, flag_factor) %>% 
  arrange(year, fips) %>% 
  knitr::kable(digits = 0, format.args = list(big.mark = ","),
               caption = "Flagged Outliers for Net")
