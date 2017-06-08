# Finalized tables, figures, and results

# ---- start --------------------------------------------------------------

library(broom)
library(lmtest)
library(multiwayvcov)
library(plm)
library(scales)
library(stringr)
library(tidyverse)

inv_hypersine <- function(x){
  log(x+(x^2+1)^0.5)
}

star_pval <- function(p.value) {
  unclass(symnum(p.value, corr = FALSE, na = FALSE,
                 cutpoints = c(0, 0.01, 0.05, 0.1, 1),
                 symbols = c("***", "**", "*", " ")))
}

k_data <- read_rds("1-tidy/migration/katrina.rds") %>% 
  mutate(moved = 1*!is.na(exmpt_katrina),
         katrina = 1*katrina,
         un_rate = 100*(unemp / (unemp + emp)),
         population = exmpt_own / 1000000,
         distance = distance / 100,
         pay = pay / 1000,
         fmr = fmr / 100,
         exmpt_katrina_eyer = exmpt_katrina_eyer*100) %>% 
  filter(year > 1999, year < 2011, katrinafips == F) %>% 
  replace_na(list(return_katrina = 0, exmpt_katrina = 0, agi_katrina = 0,
                  return_katrina_eyer = 0, exmpt_katrina_eyer = 0,
                  agi_katrina_eyer = 0))

# Get rid of fips which don't have full set of obs and afflicted counties
k_data <- k_data %>% 
  group_by(fips) %>% 
  filter(!any(is.na(exmpt_own) | is.na(distance) | is.na(un_rate) |
                is.na(pay) | is.na(fmr) | is.na(black_pct) | is.na(metro03)),
         n() == 11) %>% 
  ungroup()


# ---- common-states ------------------------------------------------------

k_data %>% 
  filter(year == 2005) %>% 
  mutate(total = sum(exmpt_katrina, na.rm = T)) %>% 
  group_by(State = stname) %>% 
  summarise(Migrants = sum(exmpt_katrina, na.rm = T),
            `Percentage of Total` = percent(sum(exmpt_katrina, na.rm = T) / mean(total))) %>% 
  arrange(desc(Migrants)) %>% 
  head() %>% 
  knitr::kable(format.args = list(big.mark = ","),
               caption = "Most Common State Destination for Migrants in 2005 \\label{tab:commondeststate}")


# ---- common-county ------------------------------------------------------

k_data %>% 
  filter(year == 2005) %>% 
  mutate(total = sum(exmpt_katrina, na.rm = T),
         ctyname = str_to_title(county)) %>% 
  group_by(FIPS = as.character(fips), County = ctyname, State = stname) %>% 
  summarise(Migrants = sum(exmpt_katrina, na.rm = T),
            `Percentage of Total` = percent(sum(exmpt_katrina, na.rm = T) / mean(total))) %>% 
  arrange(desc(Migrants)) %>% 
  head(n = 10) %>% 
  knitr::kable(format.args = list(big.mark = ","),
               caption = "Most Common County Destination for Migrants in 2005 \\label{tab:commondest}")


# ---- regressions --------------------------------------------------------

form_base <- formula(exmpt_katrina ~ population + distance + #la_dest +
                       un_rate + pay + fmr + metro03 + katrina)
form_05 <- update(form_base, . ~ . + katrina:(population + distance +
                                                #la_dest +
                                                un_rate + pay + fmr))
form_06 <- update(form_base, . ~ . + I(year == 2006):(exmpt_own + distance +
                                                        #la_dest +
                                                        un_rate + pay + fmr))

# Raw Flow
reg_0  <- lm(form_base, data = k_data)
reg_05 <- lm(form_05, data = k_data)
reg_06 <- lm(form_06, data = k_data)

# Inverse Hypersine
ihs_0  <- lm(update(form_base, inv_hypersine(exmpt_katrina) ~.),
             data = k_data)
ihs_05 <- lm(update(form_05, inv_hypersine(exmpt_katrina) ~.), data = k_data)
ihs_06 <- lm(update(form_06, inv_hypersine(exmpt_katrina) ~.), data = k_data)

# Migration percentage
pct_0  <- lm(update(form_base, exmpt_katrina_eyer ~.), data = k_data)
pct_05 <- lm(update(form_05, exmpt_katrina_eyer ~.), data = k_data)
pct_06 <- lm(update(form_06, exmpt_katrina_eyer ~.), data = k_data)

# Linear Probability
lp_0  <- lm(update(form_base, moved ~.), data = k_data)
lp_05 <- lm(update(form_05, moved ~.), data = k_data)
lp_06 <- lm(update(form_06, moved ~.), data = k_data)

# Poisson?
pois_0  <- glm(update(form_base, exmpt_katrina ~.), data = k_data,
               family = "poisson")
pois_05 <- glm(update(form_05, exmpt_katrina ~.), data = k_data,
               family = "poisson")
pois_06 <- glm(update(form_06, exmpt_katrina ~.), data = k_data,
               family = "poisson")


# ---- reg1 ---------------------------------------------------------------

m1 <- coeftest(reg_0, vcov = cluster.vcov(reg_0, cluster = ~fips)) %>% 
  tidy() %>% mutate(model = "Flow")
m2 <- coeftest(ihs_0, vcov = cluster.vcov(ihs_0, cluster = ~fips)) %>% 
  tidy() %>% mutate(model = "IHS")
m3 <- coeftest(pct_0, vcov = cluster.vcov(pct_0, cluster = ~fips)) %>% 
  tidy() %>% mutate(model = "Share")
m4 <- coeftest(lp_0, vcov = cluster.vcov(lp_0, cluster = ~fips)) %>% 
  tidy() %>% mutate(model = "LP")

all_models <- bind_rows(m1, m2, m3, m4)

varnames <- c("Intercept","Population (Millions)","Distance (Hundreds of Miles)","Unemployment Rate","Annual Pay (Thousands of USD)","Median Monthly Rent", "Non-Metro","Is 2005")
term_order <- c(m1$term, "",varnames) # for ordering variables

ols_table <- all_models %>%
  mutate(est = paste0(round(estimate, 4), star_pval(p.value)),
         se = paste0("(", round(std.error, 4), ")")) %>% 
  select(model, term, est, se) %>%
  gather(key, value, est:se) %>%
  spread(model, value) %>% 
  mutate(term = factor(term, levels =  term_order)) %>% 
  arrange(term) # last one orders by the factor order, ignoring S.E.

# Remove every other term
ols_table[seq(2, nrow(ols_table), 2), "term"] <- ""
# Rename variables for presentation
ols_table[seq(1,nrow(ols_table),2), "term"] <- varnames

ols_table %>% 
  select(-key) %>% 
  bind_rows(data.frame(term = "Adjusted R-Squared",
                       Flow = as.character(round(summary(reg_0)$adj.r.squared, 3)), 
                       IHS = as.character(round(summary(ihs_0)$adj.r.squared, 3)), 
                       LP = as.character(round(summary(lp_0)$adj.r.squared, 3)), 
                       Share = as.character(round(summary(pct_0)$adj.r.squared, 3)))) %>% 
  bind_rows(data.frame(term = "Observations",
                       Flow = as.character(nobs(reg_0)), 
                       IHS = as.character(nobs(ihs_0)), 
                       LP = as.character(nobs(lp_0)), 
                       Share = as.character(nobs(pct_0)))) %>%
  knitr::kable(caption = "\\label{tab:reg_main}Effect of Destination County Characteristics on New Orleans Outflow")

# ---- reg2 ---------------------------------------------------------------

m1 <- coeftest(reg_05, vcov = cluster.vcov(reg_05, cluster = ~fips)) %>% 
  tidy() %>% mutate(model = "Flow")
m2 <- coeftest(ihs_05, vcov = cluster.vcov(ihs_05, cluster = ~fips)) %>% 
  tidy() %>% mutate(model = "IHS")
m3 <- coeftest(pct_05, vcov = cluster.vcov(pct_05, cluster = ~fips)) %>% 
  tidy() %>% mutate(model = "Share")
m4 <- coeftest(lp_05, vcov = cluster.vcov(lp_05, cluster = ~fips)) %>% 
  tidy() %>% mutate(model = "LP")

all_models <- bind_rows(m1, m2, m3, m4)

varnames <- c("Intercept","Population (Millions)","Distance (Hundreds of Miles)","Unemployment Rate","Annual Pay (Thousands of USD)","Median Monthly Rent","Non-Metro","Is 2005","Population x 2005","Distance x 2005","Unemployment Rate x 2005","Pay x 2005","Monthly Rent x 2005")
term_order <- c(m1$term, "",varnames) # for ordering variables

ols_table <- all_models %>%
  mutate(est = paste0(round(estimate, 4), star_pval(p.value)),
         se = paste0("(", round(std.error, 4), ")")) %>% 
  select(model, term, est, se) %>%
  gather(key, value, est:se) %>%
  spread(model, value) %>% 
  mutate(term = factor(term, levels =  term_order)) %>% 
  arrange(term) # last one orders by the factor order, ignoring S.E.
  
  
# Remove every other term
ols_table[seq(2, nrow(ols_table), 2), "term"] <- ""
# Rename variables for presentation
ols_table[seq(1,nrow(ols_table),2), "term"] <- varnames

ols_table %>% 
  select(-key) %>% 
  bind_rows(data.frame(term = "Adjusted R-Squared",
                       Flow = as.character(round(summary(reg_05)$adj.r.squared, 3)), 
                       IHS = as.character(round(summary(ihs_05)$adj.r.squared, 3)), 
                       LP = as.character(round(summary(lp_05)$adj.r.squared, 3)), 
                       Share = as.character(round(summary(pct_05)$adj.r.squared, 3)))) %>% 
  bind_rows(data.frame(term = "Observations",
                       Flow = as.character(nobs(reg_05)), 
                       IHS = as.character(nobs(ihs_05)), 
                       LP = as.character(nobs(lp_05)), 
                       Share = as.character(nobs(pct_05)))) %>%
  knitr::kable(caption = "\\label{tab:reg2005}Effect of Destination County Characteristics on New Orleans Outflow - 2005 Interactions")

