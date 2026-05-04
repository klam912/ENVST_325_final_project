library(tidyverse)
library(terra)
library(sf)
library(ggplot2)
library(sf)
library(viridis)
# Data import ----
# Download datasets
data_centers <- read.csv("Desktop/ENVST325/final_project/ENVST_325_final_project/data_repo/im3_open_source_data_center_atlas_v2026.02.09/im3_open_source_data_center_atlas_v2026.02.09.csv")
eji <- read.csv("Desktop/ENVST325/final_project/ENVST_325_final_project/data_repo/EJI_2024_United_States_CSV/EJI_2024_United_States.csv")

# Skinny down data to only include TX, CA, and VA
data_centers_needed_states <- data_centers %>%
  filter(state_abb %in% c("CA", "TX", "VA"))

eji_needed_states <- eji %>%
  filter(STATEABBR %in% c("CA", "TX", "VA"))

# PROBLEM: EJI is at a Census tract level (multiple per county) while data_centers
# is in county level
# SOLUTION: keep it at a Census tract level and go to Census to get the 
# spatial information about each Census tract

# Download the 3 states Shapefiles and use sf for spatial join
# California
# Read in Shapefile
CA_data_centers <- subset(data_centers_needed_states, state_abb == "CA")
CA_shapefile <- st_read("Desktop/ENVST325/final_project/ENVST_325_final_project/data_repo/tl_2020_06_tract/tl_2020_06_tract.shp")
# Convert data_Centers into shp
data_centers_CA_shp <- st_as_sf(CA_data_centers, coords = c("lon", "lat"), crs=4326)
data_centers_CA_shp1 <- st_transform(data_centers_CA_shp, crs=4269)


data_centers_CA_final <- st_join(data_centers_CA_shp1, CA_shapefile)

# Texas
# Read in Shapefile
TX_data_centers <- subset(data_centers_needed_states, state_abb == "TX")
TX_shapefile <- st_read("Desktop/ENVST325/final_project/ENVST_325_final_project/data_repo/tl_2020_48_tract/tl_2020_48_tract.shp")
# Convert data_Centers into shp
data_centers_TX_shp <- st_as_sf(TX_data_centers, coords = c("lon", "lat"), crs=4326)
data_centers_TX_shp1 <- st_transform(data_centers_TX_shp, crs=4269)


data_centers_TX_final <- st_join(data_centers_TX_shp1, TX_shapefile)
# Virginia
VA_data_centers <- subset(data_centers_needed_states, state_abb == "VA")
VA_shapefile <- st_read("Desktop/ENVST325/final_project/ENVST_325_final_project/data_repo/tl_2020_51_tract/tl_2020_51_tract.shp")
# Convert data_Centers into shp
data_centers_VA_shp <- st_as_sf(VA_data_centers, coords = c("lon", "lat"), crs=4326)
data_centers_VA_shp1 <- st_transform(data_centers_VA_shp, crs=4269)


data_centers_VA_final <- st_join(data_centers_VA_shp1, VA_shapefile)

# Once you have data_centers_shp_CA, data_centers_shp_TX, data_centers_shp_VA,
# stack them up and join with EJI on GEOID
data_centers_CA_TX_VA <- rbind(data_centers_CA_final,data_centers_TX_final,data_centers_VA_final)

# Trim whitespace before joining
data_centers_CA_TX_VA <- data_centers_CA_TX_VA %>% mutate(GEOID = trimws(GEOID))
eji_needed_states <- eji_needed_states %>% mutate(GEOID_2020 = trimws(GEOID_2020))
data_centers_CA_TX_VA$GEOID <- as.character(data_centers_CA_TX_VA$GEOID)
eji_needed_states$GEOID_2020 <- as.character(eji_needed_states$GEOID_2020)

# Left join with EJI on GEOID
data_centers_eji_final <- data_centers_CA_TX_VA %>%
  left_join(eji_needed_states, by = c("GEOID" = "GEOID_2020"))

data_centers_eji_final_no_na <- na.omit(data_centers_eji_final)

# Validate ----
# Sum up any rows whose county names do not match since left_join already matches GEOID with GEOID_2020
sum(data_centers_eji_final_no_na$county != data_centers_eji_final_no_na$COUNTY)
sum(data_centers_eji_final_no_na$GEOID != data_centers_eji_final_no_na$GEOID.y)

# Data cleaning ----
# Select relevant columns (use percentile rank for normalized comparisons)
# Include the domain percentile ranking (broad category) (RPL) and its individual variables that
# is comprised in the domain
# Each domain is under a module (e.g. SVM)
data_centers_final <- data_centers_eji_final_no_na %>%
  select(
    state,
    state_abb,
    county,
    operator,
    name,
    sqft,
    type,
    GEOID,
    INTPTLAT,
    INTPTLON,
    geometry,
    E_TOTPOP,
    EPL_POV200,
    EPL_NOHSDP,
    EPL_UNEMP,
    EPL_RENTER,
    EPL_HOUBDN,
    EPL_UNINSUR,
    EPL_NOINT,
    RPL_SVM_DOM2,
    EPL_AGE65,
    EPL_AGE17,
    EPL_DISABL,
    EPL_LIMENG,
    RPL_SVM_DOM3,
    RPL_SVM, # Social Vulnerability Module
    EPL_OZONE,
    EPL_PM,
    EPL_DSLPM,
    EPL_TOTCR,
    RPL_EBM_DOM1,
    EPL_NPL, # EPA NAtional Priority List site (most serious uncontrolled or abandoned hazardous waste sites)
    EPL_TRI, # community's proximity to facilities that handle specific toxic chemicals that may pose a threat to human health
    EPL_TSD,
    EPL_RMP,
    EPL_LEAD,
    RPL_EBM_DOM2,
    EPL_PARK,
    EPL_HOUAGE,
    RPL_EBM_DOM3,
    EPL_IMPWTR,
    F_IMPWTR, # flag to indicate which has no data vs. true 0
    RPL_EBM_DOM5,
    RPL_EBM, # Environmental Burden Module
    EPL_ASTHMA,
    EPL_CANCER,
    EPL_CHD,
    EPL_MHLTH,
    EPL_DIABETES,
    EPL_NEHD,
    RPL_CBM_DOM1,
    EPL_CFLD,
    F_CFLD, # flag to indicate which has no data vs. true 0
    EPL_DRGT,
    F_DRGT, # flag to indicate which has no data vs. true 0
    EPL_HRCN,
    F_HRCN, # flag
    EPL_RFLD,
    F_RFLD, # flag
    EPL_SWND, 
    F_SWND, #flag
    EPL_TRND,
    F_TRND, #flag
    RPL_CBM_DOM3,
    RPL_CBM, # Climate Burden Module
    E_AFAM,
    E_AIAN,
    E_ASIAN,
    E_HISP,
    E_NHPI,
    E_OTHERRACE,
    E_TWOMORE
  )
# Make sure to clean up values -999 
total_rows_null_values <- data_centers_final %>%
  filter(if_any(where(is.atomic), ~ .x %in% c("-999", -999)))
# Instead of excluding, just replace them as NA to signify poor quality
data_centers_cleaned <- data_centers_final %>%
  # Replace -999 and 9 with NA across all atomic (string/numeric) columns
  mutate(across(where(is.atomic), ~ ifelse(.x %in% c("-999", -999, "9", 9), NA, .x)))

# Analysis ----
# NOTE: INTPTLAT and INTPTLON are the center coordinates of the Census tracts while
# geometry stores the coordinates of the individual data centers.

# Calculate total number of data centers per county in VA and TX
total_data_centers_per_county <- data_centers_cleaned %>%
  group_by(state_abb, county, operator) %>%
  summarise(
    total = n()
  )

# Summary of main EJI modules by state
state_summary <- data_centers_cleaned %>%
  group_by(state_abb) %>%
  summarise(
    avg_social_vulnerability = mean(RPL_SVM, na.rm = TRUE),
    avg_env_burden = mean(RPL_EBM, na.rm = TRUE),
    avg_climate_burden = mean(RPL_CBM, na.rm = TRUE),
    total_data_centers = n(),
    avg_sqft = mean(sqft, na.rm = TRUE)
  )


# 1. Reshape and rename the modules for clarity
plot_data <- data_centers_cleaned %>%
  select(state_abb, RPL_SVM, RPL_EBM, RPL_CBM) %>%
  pivot_longer(
    cols = starts_with("RPL"), 
    names_to = "Module", 
    values_to = "Percentile"
  ) %>%
  mutate(Module = case_when(
    Module == "RPL_SVM" ~ "Social Vulnerability",
    Module == "RPL_EBM" ~ "Environmental Burden",
    Module == "RPL_CBM" ~ "Climate Vulnerability",
    TRUE ~ Module
  ))

# 2. Create the boxplot with the new names
ggplot(plot_data, aes(x = Module, y = Percentile, fill = state_abb)) +
  geom_boxplot(outlier.shape = 1, alpha = 0.7) +
  labs(
    title = "EJI Module Distributions in Data Center Census Tracts",
    subtitle = "Comparing Texas and Virginia",
    y = "Percentile Rank (0.0 to 1.0)",
    x = "EJI Module Category",
    fill = "State"
  ) +
  theme_minimal() +
  theme(
    legend.position = "bottom",
    plot.title = element_text(face = "bold")
  )


# Plot map ----
# 1. Prepare Boundaries safely
# We wrap st_union in st_as_sf to ensure it remains a valid spatial object
tx_outline <- if(exists("TX_shapefile")) st_as_sf(st_union(TX_shapefile)) else NULL
va_outline <- if(exists("VA_shapefile")) st_as_sf(st_union(VA_shapefile)) else NULL

# 2. Texas Map
if (!is.null(tx_outline)) {
  tx_map <- ggplot() +
    # Draw census tracts
    geom_sf(data = TX_shapefile, 
            fill = "gray98", 
            color = "gray80", 
            linewidth = 0.1) + # Use 'linewidth' instead of 'size'
    # Draw state border
    geom_sf(data = tx_outline, 
            fill = NA, 
            color = "black", 
            linewidth = 0.5) +
    # Draw data centers
    geom_sf(data = data_centers_cleaned %>% filter(state_abb == "TX"), 
            color = "firebrick", 
            size = 2, 
            alpha = 0.7) +
    labs(title = "Data Centers within Texas Census Tracts",
         caption = "Data: Census Bureau & IM3 Atlas") +
    theme_void()
  
  # Assign to object and then print (helps avoid the 'depth' error in some R sessions)
  print(tx_map)
}

# 3. Virginia Map
if (!is.null(va_outline)) {
  va_map <- ggplot() +
    geom_sf(data = VA_shapefile, 
            fill = "gray98", 
            color = "gray80", 
            linewidth = 0.1) +
    geom_sf(data = va_outline, 
            fill = NA, 
            color = "black", 
            linewidth = 0.5) +
    geom_sf(data = data_centers_cleaned %>% filter(state_abb == "VA"), 
            color = "steelblue", 
            size = 2, 
            alpha = 0.7) +
    labs(title = "Data Centers within Virginia Census Tracts",
         caption = "Data: Census Bureau & IM3 Atlas") +
    theme_void()
  
  print(va_map)
}


# Heatmap ----
# 1. Prepare the Data
# We join the EJI data to the shapefiles using the GEOID column
# Ensure your Shapefile GEOID and EJI GEOTRACT are the same type (character)
TX_map_data <- TX_shapefile %>%
  left_join(eji_needed_states %>% filter(STATEABBR == "TX"), by = c("GEOID" = "GEOID_2020"))

VA_map_data <- VA_shapefile %>%
  left_join(eji_needed_states %>% filter(STATEABBR == "VA"), by = c("GEOID" = "GEOID_2020"))

# 2. Define the modules we want to map
modules <- c("RPL_SVM" = "Social Vulnerability", 
             "RPL_EBM" = "Environmental Burden", 
             "RPL_CBM" = "Climate Vulnerability")

states <- list("TX" = TX_map_data, "VA" = VA_map_data)

# 3. Create the 6 Maps
for (state_code in names(states)) {
  for (mod_code in names(modules)) {
    
    # Get the human-readable title
    mod_title <- modules[[mod_code]]
    state_df <- states[[state_code]]
    
    # Filter data centers for this state
    centers_sub <- data_centers_cleaned %>% filter(state_abb == state_code)
    
    p <- ggplot() +
      # The Heatmap Layer: Census tracts colored by EJI score
      geom_sf(data = state_df, aes_string(fill = mod_code), color = NA) +
      
      # The Context Layer: State Border
      geom_sf(data = st_union(state_df), fill = NA, color = "black", linewidth = 0.5) +
      
      # The Data Center Layer: Points
      geom_sf(data = centers_sub, color = "white", fill = "red", shape = 21, size = 1.5, stroke = 0.5) +
      
      # Styling
      scale_fill_viridis_c(option = "magma", name = "Percentile", na.value = "grey90", limits = c(0, 1)) +
      labs(
        title = paste(mod_title, "Heatmap:", state_code),
        subtitle = "Points represent Data Center locations",
        caption = "Data: CDC EJI 2024 & IM3 Atlas"
      ) +
      theme_void() +
      theme(legend.position = "right")
    
    # Print each map (In RStudio, check your 'Plots' pane or save them)
    print(p)
    
    # Optional: Save each map automatically
    ggsave(filename = paste0("Desktop/ENVST325/final_project/ENVST_325_final_project/heatmap_", state_code, "_", mod_code, ".png"), plot = p, bg = "white")
  }
}

# Plot map but zoom more on the census tract with the data centers ----
# 1. Prepare Data (Join EJI to Shapefiles)
# Ensure GEOID columns match (pad with 0 if necessary)
TX_map_data <- TX_shapefile %>%
  left_join(eji_needed_states %>% filter(STATEABBR == "TX"), by = c("GEOID" = "GEOID_2020"))

VA_map_data <- VA_shapefile %>%
  left_join(eji_needed_states %>% filter(STATEABBR == "VA"), by = c("GEOID" = "GEOID_2020"))

# 2. Configuration
modules <- c("RPL_SVM" = "Social Vulnerability", 
             "RPL_EBM" = "Environmental Burden", 
             "RPL_CBM" = "Climate Vulnerability")

states_list <- list("TX" = TX_map_data, "VA" = VA_map_data)

# 3. Generate Zoomed Maps
for (state_code in names(states_list)) {
  
  # Filter data centers for this state
  centers_sub <- data_centers_cleaned %>% filter(state_abb == state_code)
  
  # SKIP if no centers found for that state
  if (nrow(centers_sub) == 0) next
  
  # CALCULATE ZOOM AREA (Bounding Box of data centers)
  bbox <- st_bbox(centers_sub)
  
  # Add "Padding" (approx 10-20% of the range) so points aren't right on the edge
  x_range <- as.numeric(bbox["xmax"] - bbox["xmin"])
  y_range <- as.numeric(bbox["ymax"] - bbox["ymin"])
  
  # If there's only one data center (range=0), set a default zoom of ~0.5 degrees
  pad_x <- if(x_range == 0) 0.25 else x_range * 0.15
  pad_y <- if(y_range == 0) 0.25 else y_range * 0.15
  
  xlims <- c(bbox["xmin"] - pad_x, bbox["xmax"] + pad_x)
  ylims <- c(bbox["ymin"] - pad_y, bbox["ymax"] + pad_y)
  
  for (mod_code in names(modules)) {
    mod_title <- modules[[mod_code]]
    state_df <- states_list[[state_code]]
    
    p <- ggplot() +
      # Background: All census tracts
      geom_sf(data = state_df, aes(fill = .data[[mod_code]]), color = "white", linewidth = 0.05) +
      
      # Data Centers: High-contrast points
      geom_sf(data = centers_sub, color = "black", fill = "cyan", shape = 21, size = 3, stroke = 1) +
      
      # THE ZOOM: Use coord_sf to crop the view to the bounding box
      coord_sf(xlim = xlims, ylim = ylims, expand = FALSE) +
      
      # Styling
      scale_fill_viridis_c(option = "magma", name = "Percentile", na.value = "grey90", limits = c(0, 1)) +
      labs(
        title = paste("Zoomed:", mod_title),
        subtitle = paste("State:", state_code, "| Focused on Data Center Clusters"),
        caption = "Data: CDC EJI 2024 & IM3 Atlas"
      ) +
      theme_minimal() +
      theme(
        panel.grid = element_blank(),
        axis.text = element_blank(),
        legend.position = "right"
      )
    
    print(p)
    
    # Optional: Save each map automatically
    ggsave(filename = paste0("Desktop/ENVST325/final_project/ENVST_325_final_project/heatmap_focused_", state_code, "_", mod_code, ".png"), plot = p, bg = "white")
  }
}

# Create a function that returns a heatmap with the desired variable
#' @param state_abbr String, e.g., "TX" or "VA"
#' @param eji_var String, the column name from EJI (e.g., "RPL_EBM", "RPL_SVM")
#' @param map_data The state shapefile joined with EJI data
#' @param dc_data The cleaned data centers sf object
#' @param var_label String, a readable title for the legend/map
create_zoomed_map <- function(state_abbr, eji_var, map_data, dc_data, var_label) {
  
  # 1. Filter data centers for the chosen state
  centers_sub <- dc_data %>% filter(state_abb == state_abbr)
  
  if (nrow(centers_sub) == 0) {
    stop(paste("No data centers found for state:", state_abbr))
  }
  
  # 2. Calculate the "Zoom" (Bounding Box)
  bbox <- st_bbox(centers_sub)
  
  # Add padding (15%)
  x_range <- as.numeric(bbox["xmax"] - bbox["xmin"])
  y_range <- as.numeric(bbox["ymax"] - bbox["ymin"])
  pad_x <- if(x_range == 0) 0.25 else x_range * 0.15
  pad_y <- if(y_range == 0) 0.25 else y_range * 0.15
  
  # 3. Build the Plot
  p <- ggplot() +
    # Fill tracts based on the user-provided variable
    geom_sf(data = map_data, aes(fill = .data[[eji_var]]), color = "white", linewidth = 0.05) +
    
    # Overlay state boundary for context
    geom_sf(data = st_union(map_data), fill = NA, color = "black", linewidth = 0.6) +
    
    # Overlay data centers (cyan with black border for high visibility)
    geom_sf(data = centers_sub, color = "black", fill = "cyan", shape = 21, size = 3, stroke = 1) +
    
    # Zoom in using the calculated box
    coord_sf(
      xlim = c(bbox["xmin"] - pad_x, bbox["xmax"] + pad_x),
      ylim = c(bbox["ymin"] - pad_y, bbox["ymax"] + pad_y),
      expand = FALSE
    ) +
    
    # Styling
    scale_fill_viridis_c(option = "magma", name = "Percentile", limits = c(0, 1), na.value = "grey90") +
    labs(
      title = paste(state_abbr, "Zoomed Map:", var_label),
      subtitle = paste("Variable:", eji_var),
      caption = "Data: CDC EJI & IM3 Data Center Atlas"
    ) +
    theme_minimal() +
    theme(
      panel.grid = element_blank(),
      axis.title = element_blank(),
      axis.text = element_blank()
    )
  
  return(p)
}

# Example 1: Texas - Unemployment Percentile
tx_unemp_map <- create_zoomed_map("TX", "EPL_UNEMP", TX_map_data, data_centers_cleaned, "Unemployment Percentile Ranking")
print(tx_unemp_map)
