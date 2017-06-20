# Finalized tables, figures, and results

# ---- start --------------------------------------------------------------

library(censReg)
library(lmtest)
library(stringr)
library(tidyverse)

inv_hypersine <- function(x){
  log(x+(x^2+1)^0.5)
}

k_data <- read_rds("1-tidy/migration/katrina.rds") %>% 
  mutate(moved = 1*!is.na(exmpt_katrina),
         katrina = 1*katrina,
         postkat = (year == 2006),
         un_rate = 100*(unemp / (unemp + emp)),
         population = exmpt_own / 1000000,
         distance = distance / 100,
         pay = pay / 1000,
         fmr = fmr / 100,
         exmpt_katrina_eyer = exmpt_katrina_eyer*100)

# Get rid of fips which don't have full set of obs and katrina counties
k_data <- k_data %>% 
  filter(year > 1999, year < 2011, katrinafips == F) %>% 
  replace_na(list(return_katrina = 0, exmpt_katrina = 0, agi_katrina = 0,
                  return_katrina_eyer = 0, exmpt_katrina_eyer = 0,
                  agi_katrina_eyer = 0)) %>% 
  group_by(fips) %>% 
  filter(!any(is.na(exmpt_own) | is.na(distance) | is.na(un_rate) |
                is.na(pay) | is.na(fmr) | is.na(black_pct) | is.na(metro03)),
         n() == 11) %>% 
  ungroup()

# ---- regressions --------------------------------------------------------

form     <- formula(exmpt_katrina ~ population + distance + #la_dest +
                      un_rate + pay + fmr + metro03 + katrina)
form_05  <- update(form, . ~ . + katrina:.)
form_06  <- update(form, . ~ .+  postkat:.)
form_all <- update(form, . ~ . + katrina:. + postkat:. -katrina:postkat)

# Raw Flow
reg_0   <- lm(form, data = k_data)
reg_05  <- lm(form_05, data = k_data)
reg_06  <- lm(form_06, data = k_data)
reg_all <- lm(form_all, data = k_data)

# Inverse Hypersine
ihs_0   <- lm(update(form, inv_hypersine(exmpt_katrina) ~.), data = k_data)
ihs_05  <- lm(update(form_05, inv_hypersine(exmpt_katrina) ~.), data = k_data)
ihs_06  <- lm(update(form_06, inv_hypersine(exmpt_katrina) ~.), data = k_data)
ihs_all <- lm(update(form_all, inv_hypersine(exmpt_katrina) ~.), data = k_data)

# Migration percentage
pct_0   <- lm(update(form, exmpt_katrina_eyer ~.), data = k_data)
pct_05  <- lm(update(form_05, exmpt_katrina_eyer ~.), data = k_data)
pct_06  <- lm(update(form_06, exmpt_katrina_eyer ~.), data = k_data)
pct_all <- lm(update(form_all, exmpt_katrina_eyer ~.), data = k_data)

# ---- tobit --------------------------------------------------------------

tob1     <- censReg(form, data = k_data)
tob1_ihs <- censReg(update(form, inv_hypersine(exmpt_katrina) ~.),
                    data = k_data)
tob1_pct <- censReg(update(form, exmpt_katrina_eyer ~.),
                    data = k_data)

# Compare some results here
summary(reg_0)
summary(tob1)

summary(ihs_0)
summary(tob1_ihs)

summary(pct_0)
summary(tob1_pct)

# https://stats.idre.ucla.edu/r/dae/tobit-models/
# This works, but it's confusing results so I will ignore it
# library(VGAM)
# summary(m <- vglm(form, tobit(Lower = 0), data = k_data))

# ---- count --------------------------------------------------------------

# Poisson
pois_0   <- glm(update(form, exmpt_katrina ~.), data = k_data,
                family = "poisson")
pois_05  <- glm(update(form_05, exmpt_katrina ~.), data = k_data,
                family = "poisson")
pois_06  <- glm(update(form_06, exmpt_katrina ~.), data = k_data,
                family = "poisson")
pois_all <- glm(update(form_all, exmpt_katrina ~.), data = k_data,
                family = "poisson")

# Truncated Poisson
library(pscl)
# Add the components for the zero process, let's make it only gravity based
trunc         <- update(form, ~. | population + distance + katrina)
trunc[[3]]    <- trunc[[3]][[2]] # annoying quirk with parenthesis
trunc_05      <- update(form_05, ~. | population + distance + katrina)
trunc_05[[3]] <- trunc_05[[3]][[2]]

tpois_0  <- zeroinfl(trunc, data = k_data)
tpois_05 <- zeroinfl(trunc_05, data = k_data)

summary(pois_0)
summary(tpois_0)


summary(pois_05)
summary(tpois_05)

