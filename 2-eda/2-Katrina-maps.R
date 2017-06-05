# devtools::install_github("rdinter/albersusa")
# devtools::install_github("dgrtwo/gganimate")
library(albersusa)
library(gganimate)
library(scales)
library(tidyverse)
library(viridis)

mig <- read_rds("1-tidy/Migration/ctycty.rds") %>% 
  mutate(dfips = as.numeric(dfips), ofips = as.numeric(ofips),
         year = as.numeric(year))

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


hurricane <- mig %>% 
  filter(ofips %in% katrina, !(dfips %in% katrina)) %>% 
  select(-ofips, long_o, lat_o) %>% 
  group_by(dfips, long_d, lat_d, year) %>% 
  summarise_each(funs(sum(., na.rm = T)))

cty <- counties_composite("aeqd")
gg_base <- fortify(cty, region = "fips") %>%
  mutate(fips = as.numeric(id))

# hurricane <- hurricane %>% 
#   expand(dfips = unique(cty$fips), year = 1992:2013) %>% 
#   left_join(hurricane)

katrina_theme <-   theme(panel.background = element_rect(fill = "transparent"),
                         plot.background = element_rect(fill = "transparent"),
                         panel.grid = element_blank(),
                         axis.line = element_blank(),
                         axis.title = element_blank(),
                         axis.ticks = element_blank(),
                         axis.text = element_blank(),
                         legend.position = "bottom",
                         legend.title = element_blank(),
                         legend.key.width = unit(5, "cm"),
                         legend.text = element_text(size = 14),
                         plot.title = element_text(size = 20),
                         plot.subtitle = element_text(size = 14))

p <- hurricane %>% 
  rename(fips = dfips) %>% 
  filter(year > 1999, year < 2011) %>% 
  group_by(fips, year) %>% 
  summarise(mig = sum(exmpt, na.rm = T)) %>% 
  right_join(gg_base) %>% 
  ggplot(aes(long, lat, group = group)) +
  geom_polygon(data = gg_base, fill = "khaki") +
  geom_polygon(aes(fill = mig, frame = year)) +
  geom_path(color = "grey25", size = 0.05) +
  scale_fill_viridis(na.value = "khaki", trans = "log10",
                     labels = comma, oob = squish) +
  labs(title = "Outflow of Migrants in",
       subtitle = "from the 9 counties most affected by Katrina") +
  katrina_theme
gganimate(p, filename = "2-eda/katrina_2000s.gif",
          ani.width = 768, ani.height = 576)
gganimate(p, filename = "2-eda/katrina_2000s_wide.gif",
          ani.width = 968, ani.height = 576)

p <- hurricane %>% 
  rename(fips = dfips) %>% 
  filter(year > 2003, year < 2008) %>% 
  group_by(fips, year) %>% 
  summarise(mig = sum(exmpt, na.rm = T)) %>% 
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
ggsave(filename = "2-eda/katrina_2000s.png",
       width = 13.3, height = 10)

p <- hurricane %>% 
  rename(fips = dfips) %>% 
  filter(year == 2005) %>% 
  group_by(fips) %>% 
  summarise(mig = sum(exmpt, na.rm = T)) %>% 
  right_join(gg_base) %>% 
  ggplot(aes(long, lat, group = group)) +
  geom_polygon(aes(fill = mig)) +
  geom_path(color = "grey25", size = 0.05) +
  scale_fill_viridis(na.value = "khaki", trans = "log10", labels = comma,
                     oob = squish) +
  labs(title = "Outflow of Migrants in 2005",
       subtitle = "from the 9 counties most affected by Katrina") +
  katrina_theme
ggsave(p, filename = "2-eda/katrina_2005.png",
       width = 13.3, height = 10)


p <- hurricane %>% 
  rename(fips = dfips) %>% 
  filter(year == 2004) %>% 
  group_by(fips) %>% 
  summarise(mig = sum(exmpt, na.rm = T)) %>% 
  right_join(gg_base) %>% 
  ggplot(aes(long, lat, group = group)) +
  geom_polygon(aes(fill = mig)) +
  geom_path(color = "grey25", size = 0.05) +
  scale_fill_viridis(na.value = "khaki", trans = "log10", labels = comma,
                     oob = squish) +
  labs(title = "Outflow of Migrants in 2004",
       subtitle = "from the 9 counties most affected by Katrina") +
  katrina_theme
ggsave(p, filename = "2-eda/katrina_2004.png",
       width = 13.3, height = 10)

p <- hurricane %>% 
  rename(fips = dfips) %>% 
  filter(year == 2006) %>% 
  group_by(fips) %>% 
  summarise(mig = sum(exmpt, na.rm = T)) %>% 
  right_join(gg_base) %>% 
  ggplot(aes(long, lat, group = group)) +
  geom_polygon(aes(fill = mig)) +
  geom_path(color = "grey25", size = 0.05) +
  scale_fill_viridis(na.value = "khaki", trans = "log10", labels = comma,
                     oob = squish) +
  labs(title = "Outflow of Migrants in 2006",
       subtitle = "from the 9 counties most affected by Katrina") +
  katrina_theme
ggsave(p, filename = "2-eda/katrina_2006.png",
       width = 13.3, height = 10)
