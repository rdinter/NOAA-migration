# Finalized tables, figures, and results

# ---- start --------------------------------------------------------------

library(broom)
library(lmtest)
library(knitr)
library(multiwayvcov)
library(plm)
library(scales)
library(stringr)
library(tidyverse)
library(stargazer)

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
         postkat = (year == 2006),
         un_rate = 100*(unemp / (unemp + emp)),
         population = exmpt_own / 1000000,
         distance = distance / 100,
         pay = pay / 1000,
         fmr = fmr / 100,
         exmpt_katrina_eyer = exmpt_katrina_eyer*100,
         exmpt_katrina_eyer_noho = exmpt_katrina_eyer_noho*100)

# Extract the counties used in analysis, for reference in RMarkdown
katrina_counties <- k_data$county[k_data$katrinafips] %>% 
  na.omit() %>% 
  unique() %>% 
  str_to_title()

katrina_counties[length(katrina_counties)] <- 
  paste0("and ", katrina_counties[length(katrina_counties)])

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


# ---- common-states ------------------------------------------------------

k_data %>% 
  filter(year == 2005) %>% 
  mutate(total = sum(exmpt_katrina, na.rm = T)) %>% 
  group_by(State = stname) %>% 
  summarise(Migrants = sum(exmpt_katrina, na.rm = T),
            `Percentage of Total` = percent(sum(exmpt_katrina, na.rm = T) /
                                              mean(total))) %>% 
  arrange(desc(Migrants)) %>% 
  head(n = 5) %>% 
  kable(format.args = list(big.mark = ","),
        caption = paste0("Most Common State Destination for Migrants",
                         " in 2005 \\label{tab:commondeststate}"))


# ---- common-county ------------------------------------------------------

k_data %>% 
  filter(year == 2005) %>% 
  mutate(total = sum(exmpt_katrina, na.rm = T),
         ctyname = str_to_title(county)) %>% 
  group_by(FIPS = as.character(fips), County = ctyname, State = stname) %>% 
  summarise(Migrants = sum(exmpt_katrina, na.rm = T),
            `Percentage of Total` = percent(sum(exmpt_katrina, na.rm = T) /
                                              mean(total))) %>% 
  arrange(desc(Migrants)) %>% 
  head(n = 10) %>% 
  kable(format.args = list(big.mark = ","),
        caption = paste0("Most Common County Destination for Migrants",
                         " in 2005 \\label{tab:commondest}"))

# ---- summary-stats ------------------------------------------------------

# NEED TO TIDY THIS UP
k_data %>% 
  mutate(metro = 1*(metro03 == "metro")) %>% 
  select(exmpt_katrina, distance, population, un_rate, pay, fmr, metro, disasters) %>% 
  gather(variable, val) %>% 
  group_by(variable) %>% 
  summarise_all(funs(mean, sd, min, max), na.rm = T) %>% 
  mutate(variable = c("Number of Disasters","Distance (Hundreds of Miles)", "Migrants from New Orleans",
                      "Average Monthly Rent (Hundreds of USD)", "In a Metro","Average Annual Pay (Thousands of USD)", "Population (Millions)",
                      "Unemployment Rate")) %>%
  mutate_if(is.numeric, funs(round(.,3)))%>%
  kable(caption = "Summary Statistics \\label{tab:sumstats}")

# ---- regressions --------------------------------------------------------

form_base <- formula(exmpt_katrina ~ population + distance + #la_dest +
                       un_rate + pay + fmr + disasters+ metro03 + katrina)
form_05 <- update(form_base, . ~ . + katrina:.)
form_06 <- update(form_base, . ~ .+  postkat:.)
form_all <- update(form_base, . ~ . + katrina:. + postkat:. -katrina:postkat)


# Raw Flow
reg_0  <- lm(form_base, data = k_data)
reg_05 <- lm(form_05, data = k_data)
reg_06 <- lm(form_06, data = k_data)
reg_all <- lm(form_all, data = k_data)

# Inverse Hypersine
ihs_0  <- lm(update(form_base, inv_hypersine(exmpt_katrina) ~.),
             data = k_data)
ihs_05 <- lm(update(form_05, inv_hypersine(exmpt_katrina) ~.), data = k_data)
ihs_06 <- lm(update(form_06, inv_hypersine(exmpt_katrina) ~.), data = k_data)
ihs_all <- lm(update(form_all, inv_hypersine(exmpt_katrina) ~.), data = k_data)

# Migration percentage
pct_0  <- lm(update(form_base, exmpt_katrina_eyer ~.), data = k_data)
pct_05 <- lm(update(form_05, exmpt_katrina_eyer ~.), data = k_data)
pct_06 <- lm(update(form_06, exmpt_katrina_eyer ~.), data = k_data)
pct_all <- lm(update(form_all, exmpt_katrina_eyer ~.), data = k_data)

# Linear Probability
lp_0  <- lm(update(form_base, moved ~.), data = k_data)
lp_05 <- lm(update(form_05, moved ~.), data = k_data)
lp_06 <- lm(update(form_06, moved ~.), data = k_data)
lp_all <- lm(update(form_all, moved ~.), data = k_data)

# Poisson?
pois_0  <- glm(update(form_base, exmpt_katrina ~.), data = k_data,
               family = "poisson")
pois_05 <- glm(update(form_05, exmpt_katrina ~.), data = k_data,
               family = "poisson")
pois_06 <- glm(update(form_06, exmpt_katrina ~.), data = k_data,
               family = "poisson")
pois_all <- glm(update(form_all, exmpt_katrina ~.), data = k_data,
                family = "poisson")

# Raw Flow - No Harris County
reg_0_noho  <- lm(form_base, data = k_data,subset = k_data$fips != 48201)
reg_05_noho <- lm(form_05, data = k_data,subset = k_data$fips != 48201)
reg_06_noho <- lm(form_06, data = k_data,subset = k_data$fips != 48201)
reg_all_noho <- lm(form_all, data = k_data,subset = k_data$fips != 48201)

# Inverse Hypersine - No Harris County
ihs_0_noho  <- lm(update(form_base, inv_hypersine(exmpt_katrina) ~.),
             data = k_data,subset = k_data$fips != 48201)
ihs_05_noho <- lm(update(form_05, inv_hypersine(exmpt_katrina) ~.), data = k_data,subset = k_data$fips != 48201)
ihs_06_noho <- lm(update(form_06, inv_hypersine(exmpt_katrina) ~.), data = k_data,subset = k_data$fips != 48201)
ihs_all_noho <- lm(update(form_all, inv_hypersine(exmpt_katrina) ~.), data = k_data,subset = k_data$fips != 48201)

# Migration percentage - No Harris County
pct_0_noho  <- lm(update(form_base, exmpt_katrina_eyer ~.), data = k_data,subset = k_data$fips != 48201)
pct_05_noho <- lm(update(form_05, exmpt_katrina_eyer ~.), data = k_data,subset = k_data$fips != 48201)
pct_06_noho <- lm(update(form_06, exmpt_katrina_eyer ~.), data = k_data,subset = k_data$fips != 48201)
pct_all_noho <- lm(update(form_all, exmpt_katrina_eyer ~.), data = k_data,subset = k_data$fips != 48201)

# Linear Probability - No Harris County
lp_0_noho  <- lm(update(form_base, moved ~.), data = k_data,subset = k_data$fips != 48201)
lp_05_noho <- lm(update(form_05, moved ~.), data = k_data,subset = k_data$fips != 48201)
lp_06_noho <- lm(update(form_06, moved ~.), data = k_data,subset = k_data$fips != 48201)
lp_all_noho <- lm(update(form_all, moved ~.), data = k_data,subset = k_data$fips != 48201)

# Poisson - No Harris County
pois_0_noho  <- glm(update(form_base, exmpt_katrina ~.), data = k_data,
               family = "poisson",subset = k_data$fips != 48201)
pois_05_noho <- glm(update(form_05, exmpt_katrina ~.), data = k_data,
               family = "poisson",subset = k_data$fips != 48201)
pois_06_noho <- glm(update(form_06, exmpt_katrina ~.), data = k_data,
               family = "poisson",subset = k_data$fips != 48201)
pois_all_noho <- glm(update(form_all, exmpt_katrina ~.), data = k_data,
                family = "poisson",subset = k_data$fips != 48201)


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

varnames <- c("Intercept", "Population (Millions)",
              "Distance (Hundreds of Kilometers)", "Unemployment Rate",
              "Annual Pay (Thousands of USD)", "Median Monthly Rent",
              "Non-Metro", "Is 2005")
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

r_squared <- function(x) as.character(round(summary(x)$adj.r.squared, 3))
n_obs <- function(x) prettyNum(nobs(x), big.mark = ",")

ols_table %>% 
  select(-key) %>% 
  bind_rows(data.frame(term = "Adjusted R-Squared",
                       Flow = r_squared(reg_0), 
                       IHS = r_squared(ihs_0), 
                       LP = r_squared(lp_0), 
                       Share = r_squared(pct_0))) %>% 
  bind_rows(data.frame(term = "Observations",
                       Flow = n_obs(reg_0),
                       IHS = n_obs(ihs_0),
                       LP = n_obs(lp_0),
                       Share = n_obs(pct_0))) %>%
  kable(caption = paste0("\\label{tab:reg_main}Effect of Destination County",
                         " Characteristics on New Orleans Outflow"))

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

varnames <- c("Intercept", "Population (Millions)",
              "Distance (Hundreds of Kilometers)", "Unemployment Rate",
              "Annual Pay (Thousands of USD)", "Median Monthly Rent",
              "Non-Metro", "Is 2005", "Population x 2005", "Distance x 2005",
              "Unemployment Rate x 2005", "Pay x 2005", "Monthly Rent x 2005",
              "Non-Metro x 2005")
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
                       Flow = r_squared(reg_05),
                       IHS = r_squared(ihs_05),
                       LP = r_squared(lp_05),
                       Share = r_squared(pct_05))) %>% 
  bind_rows(data.frame(term = "Observations",
                       Flow = n_obs(reg_05),
                       IHS = n_obs(ihs_05),
                       LP = n_obs(lp_05),
                       Share = n_obs(pct_05))) %>%
  kable(caption = paste0("\\label{tab:reg2005}Effect of Destination",
                         " County Characteristics on",
                         " New Orleans Outflow - 2005 Interactions"))

# ---- regall ---------------------------------------------------------------
mod_stargazer <- function(...){
  output <- capture.output(stargazer(...))
  # The first three lines are the ones we want to remove...
  output <- output[4:length(output)]
  # cat out the results - this is essentially just what stargazer does too
  cat(paste(output, collapse = "\n"), "\n")
}


mod_stargazer(reg_05, ihs_05, lp_05, pct_05,
              se = list(sqrt(diag(cluster.vcov(reg_05, cluster = ~fips))),
                        sqrt(diag(cluster.vcov(ihs_05, cluster = ~fips))),
                        sqrt(diag(cluster.vcov(lp_05, cluster = ~fips))),
                        sqrt(diag(cluster.vcov(pct_05 , cluster = ~fips)))),
              omit.stat = c("f","ser"),
              covariate.labels = c("Population (Millions)",
                                   "Distance (Hundreds of Kilometers)",
                                   "Unemployment Rate", "Average Pay",
                                   "Median Rent", "Number of Disasters","Non Metro", "Year 2005",
                                   "Population X 2005", "Distance X 2005",
                                   "Unemployment Rate X 2005 ",
                                   "Average Pay X 2005","Median Rent X 2005",
                                   "Number of Disasters X 2005","Non Metro X 2005"),
              font.size = "scriptsize",
              title = paste0("\\label{reg:regmain}Effect of Destination ",
                             "Characteristics on New Orleans ",
                             "Outflow Migration"),
              column.labels = c("Flow", "IHS", "LP", "Share"),
              model.names = F, dep.var.labels.include = FALSE)


# ---- regall_noho ---------------------------------------------------------------
mod_stargazer <- function(...){
  output <- capture.output(stargazer(...))
  # The first three lines are the ones we want to remove...
  output <- output[4:length(output)]
  # cat out the results - this is essentially just what stargazer does too
  cat(paste(output, collapse = "\n"), "\n")
}


mod_stargazer(reg_05_noho, ihs_05_noho, lp_05_noho, pct_05_noho,
              se = list(sqrt(diag(cluster.vcov(reg_05_noho, cluster = ~fips))),
                        sqrt(diag(cluster.vcov(ihs_05_noho, cluster = ~fips))),
                        sqrt(diag(cluster.vcov(lp_05_noho, cluster = ~fips))),
                        sqrt(diag(cluster.vcov(pct_05_noho , cluster = ~fips)))),
              omit.stat = c("f","ser"),
              covariate.labels = c("Population (Millions)",
                                   "Distance (Hundreds of Kilometers)",
                                   "Unemployment Rate", "Average Pay",
                                   "Median Rent", "Number of Disasters","Non Metro", "Year 2005",
                                   "Population X 2005", "Distance X 2005",
                                   "Unemployment Rate X 2005 ",
                                   "Average Pay X 2005", "Median Rent X 2005",
                                   "Number of Disasters X 2005","Non Metro X 2005"),
              font.size = "scriptsize",
              title = paste0("\\label{reg:regnoho}Effect of Destination ",
                             "Characteristics on New Orleans ",
                             "Outflow Migration - Excluding Houston"),
              column.labels = c("Flow", "IHS", "LP", "Share"),
              model.names = F, dep.var.labels.include = FALSE)
