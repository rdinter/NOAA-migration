# Katrina Regressions

# library(lmtest)
# library(mfx)
# library(pglm)
library(broom)
library(lmtest)
library(multiwayvcov)
library(plm)
library(tidyverse)
inv_hypersine <- function(x){
  log(x+(x+1)^0.5)
}
star_pval <- function(p.value) {
  unclass(symnum(p.value, corr = FALSE, na = FALSE,
                 cutpoints = c(0, 0.01, 0.05, 0.1, 1),
                 symbols = c("***", "**", "*", " ")))
}

k_data <- read_rds("1-Organization/Migration/katrina.rds") %>% 
  mutate(moved = 1*!is.na(exmpt_katrina),
         katrina = 1*katrina,
         un_rate = unemp / (unemp + emp),
         population = exmpt_own / 1000000,
         distance = distance / 100,
         pay = pay / 1000,
         fmr = fmr / 100,
         exmpt_katrina_eyer = exmpt_katrina_eyer*100) %>% 
  filter(year > 1999, year < 2011) %>% 
  replace_na(list(return_katrina = 0, exmpt_katrina = 0, agi_katrina = 0,
                  return_katrina_eyer = 0, exmpt_katrina_eyer = 0,
                  agi_katrina_eyer = 0))

# Get rid of fips which don't have full set of obs
k_data <- k_data %>% 
  group_by(fips) %>% 
  filter(!any(is.na(exmpt_own) | is.na(distance) | is.na(un_rate) |
                is.na(pay) | is.na(fmr) | is.na(black_pct) | is.na(metro03)),
         n() == 11)

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


# ---- tidy ---------------------------------------------------------------

m1 <- coeftest(reg_0, vcov = cluster.vcov(reg_0, cluster = ~fips)) %>% 
  tidy() %>% mutate(model = "Flow")
m2 <- coeftest(ihs_0, vcov = cluster.vcov(ihs_0, cluster = ~fips)) %>% 
  tidy() %>% mutate(model = "IHS")
m3 <- coeftest(pct_0, vcov = cluster.vcov(pct_0, cluster = ~fips)) %>% 
  tidy() %>% mutate(model = "Share")
m4 <- coeftest(lp_0, vcov = cluster.vcov(lp_0, cluster = ~fips)) %>% 
  tidy() %>% mutate(model = "LP")

all_models <- bind_rows(m1, m2, m3, m4)

ols_table <- all_models %>%
  mutate(est = paste0(round(estimate, 4), star_pval(p.value)),
         se = paste0("(", round(std.error, 4), ")")) %>% 
  select(model, term, est, se) %>%
  gather(key, value, est:se) %>%
  spread(model, value)

terms <- c("distance", "population", "katrina")
term_names <- c("Distance (hundreds of km)",
                "Population (millions)",
                "Katrina")

ols_table %>% 
  filter(term %in% terms) %>% 
  mutate(term = factor(term, terms, term_names)) %>% 
  select(-key) %>% 
  arrange(term) %>% 
  bind_rows(data.frame(term = "Adjusted R-Squared",
                       Flow = as.character(round(summary(reg_0)$adj.r.squared, 3)), 
                       IHS = as.character(round(summary(ihs_0)$adj.r.squared, 3)), 
                       LP = as.character(round(summary(lp_0)$adj.r.squared, 3)), 
                       Share = as.character(round(summary(pct_0)$adj.r.squared, 3)))) %>% 
  knitr::kable()

terms <- c("un_rate", "pay", "fmr")

term_names <- c("Unemployment Rate",
                "Average Annual Pay (in thousands)",
                "Median Monthly Rent (in hundreds)")
ols_table %>% 
  filter(term %in% terms) %>% 
  mutate(term = factor(term, terms, term_names)) %>% 
  select(-key) %>% 
  arrange(term) %>% 
  bind_rows(data.frame(term = "Adjusted R-Squared",
                       Flow = as.character(round(summary(reg_0)$adj.r.squared, 3)), 
                       IHS = as.character(round(summary(ihs_0)$adj.r.squared, 3)), 
                       LP = as.character(round(summary(lp_0)$adj.r.squared, 3)), 
                       Share = as.character(round(summary(pct_0)$adj.r.squared, 3)))) %>% 
  knitr::kable()


# ---- interaction --------------------------------------------------------

m1 <- coeftest(reg_05, vcov = cluster.vcov(reg_05, cluster = ~fips)) %>% 
  tidy() %>% mutate(model = "Flow")
m2 <- coeftest(ihs_05, vcov = cluster.vcov(ihs_05, cluster = ~fips)) %>% 
  tidy() %>% mutate(model = "IHS")
m3 <- coeftest(pct_05, vcov = cluster.vcov(pct_05, cluster = ~fips)) %>% 
  tidy() %>% mutate(model = "Share")
m4 <- coeftest(lp_05, vcov = cluster.vcov(lp_05, cluster = ~fips)) %>% 
  tidy() %>% mutate(model = "LP")

all_models <- bind_rows(m1, m2, m3, m4)

ols_table <- all_models %>%
  mutate(est = paste0(round(estimate, 4), star_pval(p.value)),
         se = paste0("(", round(std.error, 4), ")")) %>% 
  select(model, term, est, se) %>%
  gather(key, value, est:se) %>%
  spread(model, value)

terms <- c("distance", "distance:katrina",
           "population", "population:katrina",
           "katrina")
term_names <- c("Distance (hundreds of km)", "Dist Interaction",
                "Population (millions)", "Pop Interaction",
                "Katrina")

ols_table %>% 
  filter(term %in% terms) %>% 
  mutate(term = factor(term, terms, term_names)) %>% 
  select(-key) %>% 
  arrange(term) %>% 
  bind_rows(data.frame(term = "Adjusted R-Squared",
                       Flow = as.character(round(summary(reg_05)$adj.r.squared, 3)), 
                       IHS = as.character(round(summary(ihs_05)$adj.r.squared, 3)), 
                       LP = as.character(round(summary(lp_05)$adj.r.squared, 3)), 
                       Share = as.character(round(summary(pct_05)$adj.r.squared, 3)))) %>% 
  knitr::kable()

terms <- c("un_rate", "un_rate:katrina",
           "pay", "pay:katrina",
           "fmr", "fmr:katrina")
term_names <- c( "Unemployment Rate", "Un. Interaction",
                 "Average Annual Pay (in thousands)", "A Interaction",
                 "Median Monthly Rent (in hundreds)", "M Interaction")

ols_table %>% 
  filter(term %in% terms) %>% 
  mutate(term = factor(term, terms, term_names)) %>% 
  select(-key) %>% 
  arrange(term) %>% 
  bind_rows(data.frame(term = "Adjusted R-Squared",
                       Flow = as.character(round(summary(reg_05)$adj.r.squared, 3)), 
                       IHS = as.character(round(summary(ihs_05)$adj.r.squared, 3)), 
                       LP = as.character(round(summary(lp_05)$adj.r.squared, 3)), 
                       Share = as.character(round(summary(pct_05)$adj.r.squared, 3)))) %>% 
  knitr::kable()
