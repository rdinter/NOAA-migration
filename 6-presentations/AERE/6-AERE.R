# Robert Dinterman

# ---- start --------------------------------------------------------------

# devtools::install_github("rdinter/albersusa")
# devtools::install_github("dgrtwo/gganimate")
library(albersusa)
library(gganimate)
library(scales)
library(tidyverse)
library(viridis)

fema <- read_csv("0-Data/NOAA/fema_declarations.csv") %>% 
  mutate(date = as.Date(paste0(year, "-12-31")))

hurricane <- read_rds("1-Organization/migration/katrina.rds")

# Cameron Parish - 023, Orleans Parish - 071, Plaquemines Parish - 075,
#  St. Bernard Parish - 087, and Jefferson Parish - 051
# katrina <- c(22023, 22075, 22071, 22087, 22051)

# Better option: Jefferson - 051, Lafourche - 057, Orleans - 071, Plaquemines - 075,
#  St. Bernard - 087, St. Tammany - 103, and Terrebonne - 109
# katrina <- c(22051, 22057, 22071, 22075, 22087, 22103, 22109)

# New Orleans MSA Covers
# Jefferson - 051, Orleans - 071, Plaquemines - 075, St. Bernard - 087,
# St. Charles - 089, St. John the Baptist - 095, and St. Tammany - 103 Parishes
# Extras noted are Lafourche - 057, and Terrebonne - 109
katrina <- c(22051, 22057, 22071, 22075, 22087, 22089, 22095, 22103, 22109)

cty <- counties_composite("aeqd")
gg_base <- fortify(cty, region = "fips") %>%
  mutate(fips = as.numeric(id))

la_base <- cty %>% 
  subset(state == "Louisiana") %>% 
  fortify(region = "fips") %>%
  mutate(fips = as.numeric(id),
         katrina = ifelse(fips %in% katrina, TRUE, FALSE))

katrina_theme <-   theme(panel.background = element_rect(fill = "transparent", color = NA),
                         panel.grid.minor = element_blank(), 
                         panel.grid.major = element_blank(),
                         plot.background = element_rect(fill = "transparent", color = NA),
                         panel.grid = element_blank(),
                         axis.line = element_blank(),
                         axis.title = element_blank(),
                         axis.ticks = element_blank(),
                         axis.text = element_blank(),
                         legend.position = "bottom",
                         legend.title = element_blank(),
                         legend.key.width = unit(3, "cm"))#,
                         # legend.text = element_text(size = 14),
                         # plot.title = element_text(size = 20),
                         # plot.subtitle = element_text(size = 14))


# ---- la -----------------------------------------------------------------

p <- hurricane %>% 
  filter(year == 2005, la_dest) %>% 
  group_by(fips) %>% 
  summarise(housing = sum(ihpAmount, na.rm = T)+1) %>% 
  right_join(la_base) %>% 
  ggplot(aes(long, lat, group = group)) +
  geom_polygon(aes(fill = housing)) +
  geom_path(color = "grey25", size = 0.25) +
  geom_path(data = subset(la_base, katrina), color = "red") +
  scale_fill_viridis(limits = c(0, 1e8), oob = squish, labels = dollar) +
  labs(subtitle = "FEMA Individuals and Households Program Assistance",
       title = "Post-Katrina") +
  katrina_theme
p

# ---- static-1 -----------------------------------------------------------

p <- hurricane %>% 
  # rename(fips = dfips) %>% 
  filter(year %in% c(2004, 2005), !is.na(exmpt_katrina)) %>% 
  group_by(fips, year) %>% 
  summarise(mig = sum(exmpt_katrina, na.rm = T)+1) %>% 
  right_join(gg_base) %>% 
  filter(!is.na(year)) %>% 
  # replace_na(list(mig = 0)) %>% 
  ggplot(aes(long, lat, group = group)) +
  geom_polygon(data = gg_base, color = "grey25", size = .05, fill = "khaki") +
  geom_polygon(aes(fill = mig)) +
  facet_wrap(~year) +
  scale_fill_viridis(trans = "log10", labels = comma, oob = squish) +
  labs(title = "Outflow of Migrants",
       subtitle = "from the 9 counties most affected by Katrina") +
  katrina_theme
p

# ---- static-2 -----------------------------------------------------------

p <- hurricane %>% 
  #rename(fips = dfips) %>% 
  filter(year %in% c(2005, 2006), !is.na(exmpt_katrina)) %>% 
  group_by(fips, year) %>% 
  summarise(mig = sum(exmpt_katrina, na.rm = T)+1) %>% 
  right_join(gg_base) %>% 
  filter(!is.na(year)) %>% 
  # replace_na(list(mig = 0)) %>% 
  ggplot(aes(long, lat, group = group)) +
  geom_polygon(data = gg_base, color = "grey25", size = .05, fill = "khaki") +
  geom_polygon(aes(fill = mig)) +
  facet_wrap(~year) +
  scale_fill_viridis(trans = "log10", labels = comma, oob = squish) +
  labs(title = "Outflow of Migrants",
       subtitle = "from the 9 counties most affected by Katrina") +
  katrina_theme
p
