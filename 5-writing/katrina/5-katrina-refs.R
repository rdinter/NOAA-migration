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

mod_stargazer <- function(...){
  output <- capture.output(stargazer(...))
  # The first three lines are the ones we want to remove...
  output <- output[4:length(output)]
  # cat out the results - this is essentially just what stargazer does too
  cat(paste(output, collapse = "\n"), "\n")
}

sumn  <- function(x) sum(x, na.rm = T)
meann <- function(x, w) weighted.mean(x, w, na.rm = T)

# Calculate the same variables, but for only the katrina counties
ref_data <- read_rds("1-tidy/migration/katrina_newo.rds") %>% 
  group_by(year) %>% 
  summarise(un_rate_newo = 100*(meann(unemp, exmpt_own) /
                                  meann(unemp + emp, exmpt_own)),
            black_pct_newo = (sumn(black_pct*tot_pop) / sumn(tot_pop)),
            #area_sqm = sumn(area_sqm),
            population_newo = sumn(exmpt_own) / 1000000,
            pop_dense_newo = sumn(exmpt_own) / sumn(area_sqm) /1000,
            pay_newo = meann(pay, exmpt_own) / 1000,
            fmr_newo = meann(fmr, exmpt_own) / 100,
            disasters_newo = meann(disasters, exmpt_own))

k_data <- read_rds("1-tidy/migration/katrina.rds") %>% 
  left_join(ref_data, by = "year") %>% 
  mutate(moved = 1*!is.na(exmpt_katrina),
         katrina = 1*katrina,
         postkat = (year == 2006),
         un_rate = 100*(unemp / (unemp + emp)),
         un_rate_ref = un_rate - un_rate_newo,
         population = exmpt_own / 1000000,
         population_ref = population - population_newo,
         pop_dense = exmpt_own / area_sqm / 1000,
         pop_dense_ref = pop_dense - pop_dense_newo,
         distance = distance / 100,
         black_pct_ref = black_pct - black_pct_newo,
         pay = pay / 1000,
         pay_ref = pay - pay_newo,
         fmr = fmr / 100,
         fmr_ref = fmr - fmr_newo,
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
  #filter(year == 2005) %>% 
  mutate(total = sumn(exmpt_katrina[year != 2005]),
         total_05 = sumn(exmpt_katrina[year == 2005])) %>% 
  group_by(State = stname) %>% 
  summarise(`Migrants in 2005` = sumn(exmpt_katrina[year == 2005]),
            `Percentage of Total in 2005` =
              percent(sumn(exmpt_katrina[year == 2005]) / mean(total_05)),
            `Average Migrants` = round(sumn(exmpt_katrina[year != 2005])/9),
            `Percentage of Total` = 
              percent(sumn(exmpt_katrina[year != 2005]) / mean(total))) %>% 
  arrange(desc(`Migrants in 2005`)) %>% 
  head(n = 10) %>% 
  kable(format.args = list(big.mark = ","),
        caption = paste0("Most Common State Destination for Migrants",
                         " in 2005 \\label{tab:commondeststate}"))


# ---- common-county ------------------------------------------------------

k_data %>% 
  #filter(year == 2005) %>% 
  mutate(total = sumn(exmpt_katrina[year != 2005]),
         total_05 = sumn(exmpt_katrina[year == 2005]),
         ctyname = str_to_title(county)) %>% 
  group_by(FIPS = as.character(fips), County = ctyname, State = stname) %>% 
  summarise(`Migrants in 2005` = sumn(exmpt_katrina[year == 2005]),
            `Percentage of Total in 2005` =
              percent(sumn(exmpt_katrina[year == 2005]) / mean(total_05)),
            `Average Migrants` = round(sumn(exmpt_katrina[year != 2005])/9),
            `Percentage of Total` =
              percent(sumn(exmpt_katrina[year != 2005]) / mean(total))) %>% 
  arrange(desc(`Migrants in 2005`)) %>% 
  head(n = 10) %>% 
  kable(format.args = list(big.mark = ","),
        caption = paste0("Most Common County Destination for Migrants",
                         " in 2005 \\label{tab:commondest}"))

# ---- summary-stats ------------------------------------------------------

# NEED TO TIDY THIS UP
k_data %>% 
  mutate(metro = 1*(metro03 == "metro")) %>% 
  select(exmpt_katrina, distance, population, pop_dense, black_pct,
         un_rate, pay, fmr, metro, disasters) %>% 
  gather(variable, val) %>% 
  group_by(variable) %>% 
  summarise_all(funs(mean, sd, min, max), na.rm = T) %>% 
  mutate(variable = c("Percentage Black",
                      "Number of Disasters","Distance (Hundreds of Miles)",
                      "Migrants from New Orleans",
                      "Average Monthly Rent (Hundreds of USD)",
                      "In a Metro","Average Annual Pay (Thousands of USD)",
                      "Population Density (1,000 per square mile)",
                      "Population (Millions)",
                      "Unemployment Rate")) %>%
  mutate_if(is.numeric, funs(round(.,3)))%>%
  kable(caption = "Summary Statistics \\label{tab:sumstats}")

# ---- summary-stats-locations ---------------------------------------------
katdata <- ref_data %>% 
  mutate(metro = 1,
         chunk = 0,
         chunk = replace(chunk, year < 2005, -1),
         chunk = replace(chunk, year > 2005, 1)) %>%
  select(chunk, population_newo, pop_dense_newo, black_pct_newo,
         un_rate_newo, pay_newo, fmr_newo, metro, disasters_newo) %>%
  group_by(chunk)  %>%
  summarise_all(funs(mean), na.rm = T) %>%
  mutate(ctyname = "New Orleans",
         stname = "Louisiana",
         exmpt_katrina= NA)
names(katdata) <- c("chunk","population","pop_dense","black_pct","un_rate","pay","fmr","metro","disasters","ctyname","stname","exmpt_katrina")

destdata <- k_data %>% 
  filter(fips %in% c(48201, 22033,48113,48439,22105)) %>%
  mutate(metro = 1*(metro03 == "metro"),
         chunk = 0,
         chunk = replace(chunk, year < 2005, -1),
         chunk = replace(chunk, year > 2005, 1),
         ctyname = str_to_title(county)) %>%
  select(chunk, exmpt_katrina, distance, population, pop_dense, black_pct,
         un_rate, pay, fmr, metro, disasters, ctyname, stname) %>%
  group_by(chunk, ctyname, stname) %>%
  summarise_all(funs(mean), na.rm = T) 

summdata <- bind_rows(katdata, destdata) %>%
  mutate(chunk = replace(chunk, chunk == 1, "Post-Katrina"),
         chunk = replace(chunk, chunk == 0, "Katrina"),
         chunk = replace(chunk, chunk == -1, "Pre-Katrina")) 

summdata <- summdata[,c(1,10,11,2,4,5,6,7,8,9,12,13)]
names(summdata) <- c("Time Period","County","State","Population (Millions)",
"Percentage Black"," Unemployment Rate","Average Pay (Thousands of USD)","Average Monthly Rent (Hundreds of USD)",
"In a Metro","Number of Disasters","Migrants from New Orleans","Distance (Hundreds of Miles)")
summdata %<>% mutate_if(is.numeric, funs(round(.,3)))%>%
  kable(caption = "Summary Statistics of Key Counties \\label{tab:sumstats}")

# ---- regressions --------------------------------------------------------

form_base <- formula(exmpt_katrina ~ pop_dense + distance + black_pct +
                       un_rate + pay + fmr + disasters+ metro03 + katrina)
form_05 <- update(form_base, . ~ . + katrina:.)
form_06 <- update(form_base, . ~ .+  postkat:.)
form_all <- update(form_base, . ~ . + katrina:. + postkat:. -katrina:postkat)

form_baser <- formula(exmpt_katrina ~ pop_dense_ref + distance + black_pct_ref+
                        un_rate_ref + pay_ref + fmr_ref + disasters +
                        metro03 + katrina)
form_05r <- update(form_baser, . ~ . + katrina:.)


# Raw Flow
reg_0  <- lm(form_base, data = k_data)
reg_05 <- lm(form_05, data = k_data)
reg_06 <- lm(form_06, data = k_data)
reg_all <- lm(form_all, data = k_data)

reg_05r <- lm(form_05r, data = k_data)

# Inverse Hypersine
ihs_0  <- lm(update(form_base, inv_hypersine(exmpt_katrina) ~.),
             data = k_data)
ihs_05 <- lm(update(form_05, inv_hypersine(exmpt_katrina) ~.), data = k_data)
ihs_06 <- lm(update(form_06, inv_hypersine(exmpt_katrina) ~.), data = k_data)
ihs_all <- lm(update(form_all, inv_hypersine(exmpt_katrina) ~.), data = k_data)

ihs_05r <- lm(update(form_05r, inv_hypersine(exmpt_katrina) ~.), data = k_data)

# Migration percentage
pct_0  <- lm(update(form_base, exmpt_katrina_eyer ~.), data = k_data)
pct_05 <- lm(update(form_05, exmpt_katrina_eyer ~.), data = k_data)
pct_06 <- lm(update(form_06, exmpt_katrina_eyer ~.), data = k_data)
pct_all <- lm(update(form_all, exmpt_katrina_eyer ~.), data = k_data)

pct_05r <- lm(update(form_05r, exmpt_katrina_eyer ~.), data = k_data)


# Linear Probability
lp_0  <- lm(update(form_base, moved ~.), data = k_data)
lp_05 <- lm(update(form_05, moved ~.), data = k_data)
lp_06 <- lm(update(form_06, moved ~.), data = k_data)
lp_all <- lm(update(form_all, moved ~.), data = k_data)

lp_05r <- lm(update(form_05r, moved ~.), data = k_data)


# Logit
logit_0   <- glm(update(form_base, moved ~.), data = k_data,
                 family = binomial(link = "logit"))
logit_05  <- glm(update(form_05, moved ~.), data = k_data,
                 family = binomial(link = "logit"))
logit_06  <- glm(update(form_06, moved ~.), data = k_data,
                 family = binomial(link = "logit"))
logit_all <- glm(update(form_all, moved ~.), data = k_data,
                 family = binomial(link = "logit"))

logit_05r  <- glm(update(form_05r, moved ~.), data = k_data,
                  family = binomial(link = "logit"))


# Poisson?
pois_0  <- glm(update(form_base, exmpt_katrina ~.), data = k_data,
               family = "poisson")
pois_05 <- glm(update(form_05, exmpt_katrina ~.), data = k_data,
               family = "poisson")
pois_06 <- glm(update(form_06, exmpt_katrina ~.), data = k_data,
               family = "poisson")
pois_all <- glm(update(form_all, exmpt_katrina ~.), data = k_data,
                family = "poisson")

pois_05r <- glm(update(form_05r, exmpt_katrina ~.), data = k_data,
                family = "poisson")


# Raw Flow - No Harris County
reg_0_noho  <- lm(form_base, data = k_data,subset = k_data$fips != 48201)
reg_05_noho <- lm(form_05, data = k_data,subset = k_data$fips != 48201)
reg_06_noho <- lm(form_06, data = k_data,subset = k_data$fips != 48201)
reg_all_noho <- lm(form_all, data = k_data,subset = k_data$fips != 48201)

reg_05_nohor <- lm(form_05r, data = k_data,subset = k_data$fips != 48201)


# Inverse Hypersine - No Harris County
ihs_0_noho  <- lm(update(form_base, inv_hypersine(exmpt_katrina) ~.),
                  data = k_data,subset = k_data$fips != 48201)
ihs_05_noho <- lm(update(form_05, inv_hypersine(exmpt_katrina) ~.),
                  data = k_data,subset = k_data$fips != 48201)
ihs_06_noho <- lm(update(form_06, inv_hypersine(exmpt_katrina) ~.),
                  data = k_data,subset = k_data$fips != 48201)
ihs_all_noho <- lm(update(form_all, inv_hypersine(exmpt_katrina) ~.),
                   data = k_data,subset = k_data$fips != 48201)

ihs_05_nohor <- lm(update(form_05r, inv_hypersine(exmpt_katrina) ~.),
                   data = k_data,subset = k_data$fips != 48201)


# Migration percentage - No Harris County
pct_0_noho  <- lm(update(form_base, exmpt_katrina_eyer ~.),
                  data = k_data,subset = k_data$fips != 48201)
pct_05_noho <- lm(update(form_05, exmpt_katrina_eyer ~.),
                  data = k_data,subset = k_data$fips != 48201)
pct_06_noho <- lm(update(form_06, exmpt_katrina_eyer ~.),
                  data = k_data,subset = k_data$fips != 48201)
pct_all_noho <- lm(update(form_all, exmpt_katrina_eyer ~.),
                   data = k_data,subset = k_data$fips != 48201)

pct_05_nohor <- lm(update(form_05r, exmpt_katrina_eyer ~.),
                   data = k_data,subset = k_data$fips != 48201)


# Linear Probability - No Harris County
lp_0_noho  <- lm(update(form_base, moved ~.), data = k_data,
                 subset = k_data$fips != 48201)
lp_05_noho <- lm(update(form_05, moved ~.), data = k_data,
                 subset = k_data$fips != 48201)
lp_06_noho <- lm(update(form_06, moved ~.), data = k_data,
                 subset = k_data$fips != 48201)
lp_all_noho <- lm(update(form_all, moved ~.), data = k_data,
                  subset = k_data$fips != 48201)

lp_05_nohor <- lm(update(form_05r, moved ~.), data = k_data,
                  subset = k_data$fips != 48201)


# Logit
logit_0_noho   <- glm(update(form_base, moved ~.), data = k_data,
                 subset = k_data$fips != 48201, family = binomial(link = "logit"))
logit_05_noho  <- glm(update(form_05, moved ~.), data = k_data,
                 subset = k_data$fips != 48201,family = binomial(link = "logit"))
logit_06_noho  <- glm(update(form_06, moved ~.), data = k_data,
                 subset = k_data$fips != 48201,family = binomial(link = "logit"))
logit_all_noho <- glm(update(form_all, moved ~.), data = k_data,
                 subset = k_data$fips != 48201, family = binomial(link = "logit"))

logit_05r_nohor  <- glm(update(form_05r, moved ~.), data = k_data,
                  subset = k_data$fips != 48201,family = binomial(link = "logit"))



# Poisson - No Harris County
pois_0_noho  <- glm(update(form_base, exmpt_katrina ~.), data = k_data,
                    family = "poisson",subset = k_data$fips != 48201)
pois_05_noho <- glm(update(form_05, exmpt_katrina ~.), data = k_data,
                    family = "poisson",subset = k_data$fips != 48201)
pois_06_noho <- glm(update(form_06, exmpt_katrina ~.), data = k_data,
                    family = "poisson",subset = k_data$fips != 48201)
pois_all_noho <- glm(update(form_all, exmpt_katrina ~.), data = k_data,
                     family = "poisson",subset = k_data$fips != 48201)

pois_05_nohor <- glm(update(form_05r, exmpt_katrina ~.), data = k_data,
                     family = "poisson",subset = k_data$fips != 48201)

# ---- regall ---------------------------------------------------------------

mod_stargazer(reg_05, ihs_05, lp_05, pct_05,
              se = list(sqrt(diag(cluster.vcov(reg_05, cluster = ~fips))),
                        sqrt(diag(cluster.vcov(ihs_05, cluster = ~fips))),
                        sqrt(diag(cluster.vcov(lp_05, cluster = ~fips))),
                        sqrt(diag(cluster.vcov(pct_05 , cluster = ~fips)))),
              omit.stat = c("f","ser"),
              covariate.labels = c("Population Density (1,000 per square mile)",
                                   "Distance (Hundreds of Kilometers)",
                                   "Percentage Black",
                                   "Unemployment Rate", "Average Pay",
                                   "Median Rent", "Number of Disasters",
                                   "Non Metro", "Year 2005",
                                   "Population X 2005", "Distance X 2005",
                                   "Black X 2005",
                                   "Unemployment Rate X 2005 ",
                                   "Average Pay X 2005","Median Rent X 2005",
                                   "Number of Disasters X 2005",
                                   "Non Metro X 2005"),
              font.size = "scriptsize",
              title = paste0("\\label{reg:regmain}Effect of Destination ",
                             "Characteristics on New Orleans ",
                             "Outflow Migration"),
              column.labels = c("Flow", "IHS", "Logit", "Share"),
              model.names = F, dep.var.labels.include = FALSE)


# ---- regall_noho ------------------------------------------------------------


mod_stargazer(reg_05_noho, ihs_05_noho, lp_05_noho, pct_05_noho,
              se = list(sqrt(diag(cluster.vcov(reg_05_noho, cluster = ~fips))),
                        sqrt(diag(cluster.vcov(ihs_05_noho, cluster = ~fips))),
                        sqrt(diag(cluster.vcov(lp_05_noho, cluster = ~fips))),
                        sqrt(diag(cluster.vcov(pct_05_noho , cluster = ~fips)))),
              omit.stat = c("f","ser"),
              covariate.labels = c("Population Density (1,000 per square mile)",
                                   "Distance (Hundreds of Kilometers)",
                                   "Percentage Black",
                                   "Unemployment Rate", "Average Pay",
                                   "Median Rent", "Number of Disasters",
                                   "Non Metro", "Year 2005",
                                   "Population X 2005", "Distance X 2005",
                                   "Black X 2005",
                                   "Unemployment Rate X 2005 ",
                                   "Average Pay X 2005", "Median Rent X 2005",
                                   "Number of Disasters X 2005",
                                   "Non Metro X 2005"),
              font.size = "scriptsize",
              title = paste0("\\label{reg:regnoho}Effect of Destination ",
                             "Characteristics on New Orleans ",
                             "Outflow Migration - Excluding Houston"),
              column.labels = c("Flow", "IHS", "Logit", "Share"),
              model.names = F, dep.var.labels.include = FALSE)

# ---- referee ------------------------------------------------------------



# ---- regallr ---------------------------------------------------------------


mod_stargazer(reg_05r, ihs_05r, logit_05r, pct_05r,
              se = list(sqrt(diag(cluster.vcov(reg_05r, cluster = ~fips))),
                        sqrt(diag(cluster.vcov(ihs_05r, cluster = ~fips))),
                        sqrt(diag(cluster.vcov(lp_05r, cluster = ~fips))),
                        sqrt(diag(cluster.vcov(pct_05r, cluster = ~fips)))),
              omit.stat = c("f","ser"),
              covariate.labels = c("Population Density (1,000 per square mile)",
                                   "Distance (Hundreds of Kilometers)",
                                   "Percentage Black",
                                   "Unemployment Rate", "Average Pay",
                                   "Median Rent", "Number of Disasters",
                                   "Non Metro", "Year 2005",
                                   "Population X 2005", "Distance X 2005",
                                   "Black X 2005",
                                   "Unemployment Rate X 2005 ",
                                   "Average Pay X 2005","Median Rent X 2005",
                                   "Number of Disasters X 2005",
                                   "Non Metro X 2005"),
              font.size = "scriptsize",
              title = paste0("\\label{reg:regmainr}Effect of Destination ",
                             "Characteristics on New Orleans ",
                             "Outflow Migration"),
              column.labels = c("Flow", "IHS", "LP", "Share"),
              model.names = F, dep.var.labels.include = FALSE)


# ---- regall_nohor -----------------------------------------------------------

mod_stargazer(reg_05_nohor, ihs_05_nohor, lp_05_nohor, pct_05_nohor,
              se = list(sqrt(diag(cluster.vcov(reg_05_nohor, cluster = ~fips))),
                        sqrt(diag(cluster.vcov(ihs_05_nohor, cluster = ~fips))),
                        sqrt(diag(cluster.vcov(lp_05_nohor, cluster = ~fips))),
                        sqrt(diag(cluster.vcov(pct_05_nohor, cluster = ~fips)))),
              omit.stat = c("f","ser"),
              covariate.labels = c("Population Density (1,000 per square mile)",
                                   "Distance (Hundreds of Kilometers)",
                                   "Percentage Black",
                                   "Unemployment Rate", "Average Pay",
                                   "Median Rent", "Number of Disasters",
                                   "Non Metro", "Year 2005",
                                   "Population X 2005", "Distance X 2005",
                                   "Black X 2005",
                                   "Unemployment Rate X 2005 ",
                                   "Average Pay X 2005", "Median Rent X 2005",
                                   "Number of Disasters X 2005",
                                   "Non Metro X 2005"),
              font.size = "scriptsize",
              title = paste0("\\label{reg:regnohor}Effect of Destination ",
                             "Characteristics on New Orleans ",
                             "Outflow Migration - Excluding Houston"),
              column.labels = c("Flow", "IHS", "LP", "Share"),
              model.names = F, dep.var.labels.include = FALSE)
