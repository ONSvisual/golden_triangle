## Golden Triangle: Create isochrones ##

library(tidyverse) 
library(rgdal) 
library(stars) 
library(sf) 
library(rnaturalearth) 
library(osrm)

# Region: East Midlands, East of England, London, North East, North West, South West, West Midlands, Yorkshire and The Humber, 
# Countries: Scotland, Wales
id <- "West Midlands"

# 1) Load geospatial data ------------------------------------------------------

# Regions of England
# Source: ONS Open Geography Portal
# URL: https://geoportal.statistics.gov.uk/datasets/regions-december-2020-en-bgc
region <- st_read("https://opendata.arcgis.com/datasets/cfa25518ddd7408a8da5c27eb42dd428_0.geojson") %>% 
  st_transform(27700) %>% 
  filter(RGN20NM == id)

plot(st_geometry(region))

# Scotland / Wales
# Source: Natural Earth
# URL: https://www.naturalearthdata.com
country <- ne_countries(country = 'united kingdom', type = 'map_units', scale = 'large', returnclass = 'sf') %>% 
  filter(geounit == id) %>%
  st_transform(crs = 27700)

plot(st_geometry(country))

# UK population (2011 Census, 1 km x 1 km grid)
# Source: NERC Environmental Information Data Centre
# URL: https://catalogue.ceh.ac.uk/documents/0995e94d-6d42-40c1-8ed4-5090d82471e1
grid <- readGDAL("../../data/raw/UK_residential_population_2011_1_km.asc", p4s = '+init=EPSG:4326') %>%
  st_as_stars() %>%
  st_as_sf(as_points = FALSE, merge = TRUE)

# 2) Intersect population grid centroids with region or country -----------------

centroids <- grid %>%
  st_transform(crs = 27700) %>% 
  st_centroid() %>% 
  st_intersection(region) %>% # enter region or country
  mutate(grid_id = row_number()) %>% 
  select(grid_id, population = band1) %>% 
  st_transform(crs = 4326) 

plot(st_geometry(st_transform(region, 4326)))
plot(st_geometry(centroids), add = T)

# 3) Create 4hr drive-time polygons for every population grid square -----------

# Source: Open Source Routing Machine; OpenStreetMap
# URL: http://map.project-osrm.org
options(osrm.server = "http://localhost:5000/", osrm.profile = "driving")

iso <- select(centroids, -population) %>%
  mutate(iso = map(geometry,
                   osrmIsochrone,
                   breaks = seq(from = 0, to = 240, by = 240),
                   res = 30,
                   returnclass = "sf")) %>%
  st_drop_geometry() %>%
  unnest(iso) %>%
  st_set_geometry("geometry") %>% 
  rename(iso_id = grid_id)

plot(st_geometry(ne_countries(country = 'united kingdom', type = 'countries', scale = 'large', returnclass = 'sf')))
plot(st_geometry(iso), add = T)
# st_write(iso, paste0("../../data/processed/isochrones/", id, ".geojson"))

