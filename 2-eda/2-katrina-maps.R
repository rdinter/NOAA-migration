
# ---- start --------------------------------------------------------------

# devtools::install_github("rdinter/albersusa")
# devtools::install_github("dgrtwo/gganimate")
library(albersusa)
library(gganimate)
library(scales)
library(tidyverse)
library(viridis)

local_dir   <- "2-eda/katrina"
figures     <- paste0(local_dir, "/figures")
if (!file.exists(local_dir)) dir.create(local_dir)
if (!file.exists(figures)) dir.create(figures)

kat_tidy <- read_rds("1-tidy/migration/katrina.rds") %>% 
  select(year, fips, long, lat, return_katrina, exmpt_katrina,
           agi_katrina, disasters)

cty <- counties_composite("aeqd")
gg_base <- fortify(cty, region = "fips") %>%
  mutate(fips = as.numeric(id))

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

# ---- maps ---------------------------------------------------------------

kat_tidy %>% 
  group_by(fips) %>% 
  summarise(disasters = mean(disasters, na.rm = T)) %>% 
  right_join(gg_base) %>% 
  replace_na(list(disasters = 0)) %>% 
  ggplot(aes(long, lat, group = group)) +
  geom_polygon(data = gg_base, fill = "khaki") +
  geom_polygon(aes(fill = disasters)) +
  geom_path(color = "grey25", size = 0.05) +
  scale_fill_viridis(limits = c(0, 15), oob = squish) +
  labs(title = "Number of Disasters Declared per County",
       subtitle = "from 1964 until 2000") +
  katrina_theme
ggsave(paste0(figures, "/disasters_64-00.png"),
       width = 13.3, height = 10)

p <- kat_tidy %>% 
  filter(year > 1999, year < 2011) %>% 
  group_by(fips, year) %>% 
  summarise(mig = sum(exmpt_katrina, na.rm = T)) %>% 
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
gganimate(p, filename = paste0(figures, "/katrina_2000s.gif"),
          ani.width = 768, ani.height = 576)
gganimate(p, filename = paste0(figures, "/katrina_2000s_wide.gif"),
          ani.width = 968, ani.height = 576)

p <- kat_tidy %>% 
  filter(year > 2003, year < 2008) %>% 
  group_by(fips, year) %>% 
  summarise(mig = sum(exmpt_katrina, na.rm = T)) %>% 
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
ggsave(filename = paste0(figures, "/katrina_2000s.png"),
       width = 13.3, height = 10)

p <- kat_tidy %>% 
  filter(year == 2005) %>% 
  group_by(fips) %>% 
  summarise(mig = sum(exmpt_katrina, na.rm = T)) %>% 
  right_join(gg_base) %>% 
  ggplot(aes(long, lat, group = group)) +
  geom_polygon(aes(fill = mig)) +
  geom_path(color = "grey25", size = 0.05) +
  scale_fill_viridis(na.value = "khaki", trans = "log10", labels = comma,
                     oob = squish) +
  labs(title = "Outflow of Migrants in 2005",
       subtitle = "from the 9 counties most affected by Katrina") +
  katrina_theme
ggsave(p, filename = paste0(figures, "/katrina_2005.png"),
       width = 13.3, height = 10)

p <- kat_tidy %>% 
  filter(year == 2004) %>% 
  group_by(fips) %>% 
  summarise(mig = sum(exmpt_katrina, na.rm = T)) %>% 
  right_join(gg_base) %>% 
  ggplot(aes(long, lat, group = group)) +
  geom_polygon(aes(fill = mig)) +
  geom_path(color = "grey25", size = 0.05) +
  scale_fill_viridis(na.value = "khaki", trans = "log10", labels = comma,
                     oob = squish) +
  labs(title = "Outflow of Migrants in 2004",
       subtitle = "from the 9 counties most affected by Katrina") +
  katrina_theme
ggsave(p, filename = paste0(figures, "/katrina_2004.png"),
       width = 13.3, height = 10)

p <- kat_tidy %>% 
  filter(year == 2006) %>% 
  group_by(fips) %>% 
  summarise(mig = sum(exmpt_katrina, na.rm = T)) %>% 
  right_join(gg_base) %>% 
  ggplot(aes(long, lat, group = group)) +
  geom_polygon(aes(fill = mig)) +
  geom_path(color = "grey25", size = 0.05) +
  scale_fill_viridis(na.value = "khaki", trans = "log10", labels = comma,
                     oob = squish) +
  labs(title = "Outflow of Migrants in 2006",
       subtitle = "from the 9 counties most affected by Katrina") +
  katrina_theme
ggsave(p, filename = paste0(figures, "/katrina_2006.png"),
       width = 13.3, height = 10)
