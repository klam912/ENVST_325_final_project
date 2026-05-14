library(tidyverse)
library(sf)
library(viridis)

# Data processing ----

# Load datasets
data_centers <- read.csv("~/Desktop/ENVST325/final_project/ENVST_325_final_project/data_repo/im3_open_source_data_center_atlas_v2026.02.09/im3_open_source_data_center_atlas_v2026.02.09.csv")
eji <- read.csv("~/Desktop/ENVST325/final_project/ENVST_325_final_project/data_repo/EJI_2024_United_States_CSV/EJI_2024_United_States.csv")

# Filter for relevant states and clean EJI IDs
eji_needed <- eji %>%
  filter(STATEABBR %in% c("CA", "TX", "VA")) %>%
  mutate(GEOID_2020 = trimws(as.character(GEOID_2020)))

# Function to process state shapefiles and join with data center points
process_state_data <- function(state_abb, shp_path) {
  # Load shapefile
  shapefile <- st_read(shp_path) %>% mutate(GEOID = trimws(as.character(GEOID)))
  
  # Fix California GEOIDs (remove leading zero to match EJI's GEOID format)
  if(state_abb == "CA") {
    shapefile <- shapefile %>% mutate(GEOID = sub("^0", "", GEOID))
  }
  
  # Process data center points
  points <- data_centers %>%
    filter(state_abb == !!state_abb) %>%
    st_as_sf(coords = c("lon", "lat"), crs = 4326) %>%
    st_transform(crs = st_crs(shapefile))
  
  # Assign tract GEOID to each data center
  points_final <- st_join(points, shapefile)
  
  return(list(shape = shapefile, points = points_final))
}

# Process each state
ca_data <- process_state_data("CA", "~/Desktop/ENVST325/final_project/ENVST_325_final_project/data_repo/tl_2020_06_tract/tl_2020_06_tract.shp")
tx_data <- process_state_data("TX", "~/Desktop/ENVST325/final_project/ENVST_325_final_project/data_repo/tl_2020_48_tract/tl_2020_48_tract.shp")
va_data <- process_state_data("VA", "~/Desktop/ENVST325/final_project/ENVST_325_final_project/data_repo/tl_2020_51_tract/tl_2020_51_tract.shp")

# Combine data center points and join with EJI modules
data_centers_combined <- bind_rows(ca_data$points, tx_data$points, va_data$points) %>%
  left_join(eji_needed, by = c("GEOID" = "GEOID_2020"))

# Replace -999/9 with NA and retrieve relevant columns
data_centers_cleaned <- data_centers_combined %>%
  mutate(across(where(is.atomic), ~ ifelse(.x %in% c("-999", -999, "9", 9), NA, .x))) %>%
  select(state_abb, county, operator, name, sqft, type, GEOID, RPL_SVM, RPL_EBM, RPL_CBM, geometry)

# Join EJI data back to the full shapefiles for for final data
CA_map_data <- ca_data$shape %>% left_join(eji_needed, by = c("GEOID" = "GEOID_2020"))
TX_map_data <- tx_data$shape %>% left_join(eji_needed, by = c("GEOID" = "GEOID_2020"))
VA_map_data <- va_data$shape %>% left_join(eji_needed, by = c("GEOID" = "GEOID_2020"))

# Visualization ----

# Generate heatmaps at state and county levels
generate_eji_map <- function(map_data, dc_data, state_code, mod_code, region_name = NULL) {
  
  mod_labels <- c("RPL_SVM" = "Social Vulnerability", "RPL_EBM" = "Environmental Burden", "RPL_CBM" = "Climate Vulnerability")
  
  # Determine focus area and filter points
  if (!is.null(region_name)) {
    focus_tracts <- map_data %>% filter(tolower(COUNTY) == tolower(region_name))
    bbox <- st_bbox(focus_tracts)
    points_to_plot <- dc_data %>% filter(state_abb == state_code) %>% st_crop(bbox)
    title_text <- paste(region_name, ":", mod_labels[mod_code])
  } else {
    bbox <- st_bbox(map_data)
    points_to_plot <- dc_data %>% filter(state_abb == state_code)
    title_text <- paste(state_code, "State-wide:", mod_labels[mod_code])
  }
  
  ggplot() +
    geom_sf(data = map_data, aes(fill = .data[[mod_code]]), color = "white", linewidth = 0.05) +
    geom_sf(data = points_to_plot, color = "black", fill = "cyan", shape = 21, size = 3, stroke = 1) +
    coord_sf(xlim = c(bbox["xmin"], bbox["xmax"]), ylim = c(bbox["ymin"], bbox["ymax"]), expand = TRUE) +
    scale_fill_viridis_c(option = "magma", name = "Percentile", limits = c(0, 1), na.value = "grey90") +
    labs(title = title_text, subtitle = "Data Center Locations Marked in Cyan", caption = "Source: CDC EJI & IM3 Atlas") +
    theme_void()
}

# Create heatmaps for counties with high volume of data center presence
focus_areas <- list(
  "VA" = c("Loudoun County", "Prince William County", "Fairfax County", "Henrico County"),
  "TX" = c("Bexar County", "Dallas County", "Travis County", "Ellis County", "Collin County"),
  "CA" = c("Santa Clara County", "Los Angeles County")
)

state_maps <- list("CA" = CA_map_data, "TX" = TX_map_data, "VA" = VA_map_data)

# Iterate through each focus area and create 3 heatmaps and save them in folder
for (st in names(focus_areas)) {
  for (co in focus_areas[[st]]) {
    for (mod in c("RPL_SVM", "RPL_EBM", "RPL_CBM")) {
      p <- generate_eji_map(state_maps[[st]], data_centers_cleaned, st, mod, co)

      file_path <- sprintf("Desktop/ENVST325/final_project/ENVST_325_final_project/viz/Map_%s_%s_%s.png", st, gsub(" ", "_", co), mod)
      ggsave(file_path, plot = p, width = 8, height = 6, bg = "white")
    }
  }
}