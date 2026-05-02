library(tidyverse)
library(terra)
library(sf)
# Data import ----
# Download datasets
data_centers <- read.csv("Desktop/ENVST325/final_project/ENVST_325_final_project/data_repo/im3_open_source_data_center_atlas_v2026.02.09/im3_open_source_data_center_atlas_v2026.02.09.csv")
eji <- read.csv("Desktop/ENVST325/final_project/ENVST_325_final_project/data_repo/EJI_2024_United_States_CSV/EJI_2024_United_States.csv")
nih <- read.csv("Desktop/ENVST325/final_project/ENVST_325_final_project/data_repo/NIH/HDPulse_data_export.csv")

# Skinny down data to only include TX, CA, and VA
data_centers_needed_states <- data_centers %>%
  filter(state_abb %in% c("CA", "TX", "VA"))

eji_needed_states <- eji %>%
  filter(STATEABBR %in% c("CA", "TX", "VA"))

Loudon_VA <- data_centers %>% filter(county=="Loudoun County")
plot(VA$lon, VA$lat, xlab="Longitude", ylab="Latitude", main="Data Centers in Loudoun County, VA")


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





