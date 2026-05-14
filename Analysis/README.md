# Data Center Environmental Justice Analysis

## Overview

This R script analyzes the spatial relationship between data centers and environmental justice indicators (EJI) across three U.S. states: California, Texas, and Virginia. It processes data center locations and overlays them with Census tract-level environmental justice metrics to visualize potential environmental and social vulnerabilities associated with data center placement.

## Purpose

The analysis serves as a tool for environmental justice research by:

- Identifying data centers located in tracts with high social vulnerability, environmental burden, or climate vulnerability
- Visualizing the geographic overlap of data center infrastructure with disadvantaged communities
- Creating county-level heatmaps of EJI indices in highly clustered data-center areas

## Data Sources

### Required Datasets

1. **IM3 Open Source Data Center Atlas** (`im3_open_source_data_center_atlas_v2026.02.09.csv`)
   - Comprehensive inventory of U.S. data centers
   - Fields: state abbreviation, county, operator, facility name, square footage, type, coordinates (lon/lat)

2. **CDC Environmental Justice Index (EJI)** (`EJI_2024_United_States.csv`)
   - 2024 EJI dataset with Census 2020 tract identifiers
   - Key variables: `GEOID_2020`, `RPL_SVM`, `RPL_EBM`, `RPL_CBM`

3. **Census Tract Shapefiles** (2020)
   - State-level shapefiles for CA (FIPS 06), TX (FIPS 48), VA (FIPS 51)
   - Files: `tl_2020_XX_tract.shp` format

## Dependencies

```r
library(tidyverse)  # Data manipulation and visualization
library(sf)         # Spatial data handling
library(viridis)    # Color palettes for maps
```

**R Version:** 3.6+ (ggplot2 and dplyr features)

## Script Structure

### 1. Data Processing

**Load and Filter Data**

- Loads data center and EJI data
- Filters EJI data to CA, TX, and VA
- Standardizes GEOID formats (handles leading zeros in California tract IDs)

**State-Level Processing**

- `process_state_data()` function:
  - Reads state-level Census tract shapefiles
  - Converts data center coordinates to spatial points
  - Performs spatial join to assign Census tracts to each data center
  - Returns shapefile polygons and data center points

**Data Integration**

- Combines processed data across all three states
- Joins data center locations with EJI metrics using Census tract GEOID
- Cleans missing values (replaces -999/9 with NA)
- Get relevant columns: state, county, operator, facility name, size, type, and EJ indices

### 2. Visualization

**Heatmap Generation**

- `generate_eji_map()` function creates publication-ready maps showing:
  - Census tracts colored by EJ index percentile (0–1 scale)
  - Data center locations marked as cyan points with black outlines
  - State-wide and county-level zoom capabilities

**EJ Metrics Visualized**

- **RPL_SVM:** Social Vulnerability Module - measures socioeconomic disadvantage
- **RPL_EBM:** Environmental Burden Module - captures pollution and hazard exposure
- **RPL_CBM:** Climate Vulnerability Module - reflects climate change impacts

**Output Generation**

- Generates 3 heatmaps per county (one for each EJ metric)
- Creates 12 county-level maps across 4 Virginia, 5 Texas, and 2 California focus counties
- Total output: 36 PNG visualizations saved to the viz directory

## Key Functions

### `process_state_data(state_abb, shp_path)`

Processes spatial data for a single state.

**Arguments:**

- `state_abb` (character): Two-letter state abbreviation (e.g., "CA", "TX", "VA")
- `shp_path` (character): Path to the census tract shapefile

**Returns:**

- Named list with elements:
  - `shape`: sf object of census tract polygons with EJI data
  - `points`: sf object of data center locations with assigned tract GEOIDs

**Details:**

- Handles state-specific GEOID formatting (CA leading zero correction)
- Reprojects data centers to match shapefile coordinate reference system
- Performs spatial join to link data centers to census tracts

### `generate_eji_map(map_data, dc_data, state_code, mod_code, region_name = NULL)`

Creates heatmap visualizations of EJI metrics with data center overlays.

**Arguments:**

- `map_data` (sf): Census tract polygons with EJI variables
- `dc_data` (sf): Data center point locations
- `state_code` (character): Two-letter state abbreviation
- `mod_code` (character): EJI module variable name ("RPL_SVM", "RPL_EBM", or "RPL_CBM")
- `region_name` (character, optional): County name for focused view; if NULL, shows state-wide map

**Returns:**

- ggplot2 map object

**Details:**

- Color scale: Viridis "magma" palette (low-to-high percentile rank in dark-to-yellow)
- Missing values displayed in light grey
- Data centers highlighted to show spatial proximity to vulnerable tracts

## Focus Areas

The script generates maps for the following high-data-center counties:

**Virginia (Northern Virginia / Data Center Alley)**

- Loudoun County
- Prince William County
- Fairfax County
- Henrico County

**Texas**

- Bexar County
- Dallas County
- Travis County
- Ellis County
- Collin County

**California**

- Santa Clara County
- Los Angeles County

## Output

**Format:** PNG images (8×6 inches, 300 dpi equivalent)

**Naming Convention:** `Map_[STATE]_[COUNTY]_[MODULE].png`

Example: `Map_VA_Loudoun_County_RPL_SVM.png`

**Location:** `Desktop/ENVST325/final_project/ENVST_325_final_project/viz/`

## Usage

1. **Update file paths** in lines 8-9 and 39-41 to match your local directory structure
2. **Install dependencies** if not already installed:
   ```r
   install.packages(c("tidyverse", "sf", "viridis"))
   ```
3. **Run the script:**
   ```r
   source("analysis.R")
   ```
4. **Check the viz directory** for generated heatmaps

## Data Notes

- **GEOID Handling:** California tract GEOIDs include leading zeros in shapefiles but not in EJI data; the script corrects this mismatch
- **Missing Values:** Replaced placeholder values (-999/9) with NA to avoid misinterpretation and removed from analysis
- **Spatial Reference:** All data converted to match source shapefile CRS
- **Percentile Ranks:** EJI modules are expressed as percentile ranks (0–1); higher values indicate greater disadvantage/vulnerability

## Interpretation

Maps reveal the spatial concentration of data centers in relation to environmental and social vulnerability:

- Darker (higher percentile) areas indicate tracts experiencing greater EJ burden
- Cyan data center markers highlight data center location
- Patterns may indicate disproportionate environmental impacts on certain communities

## Limitations

- Analysis limited to three states since patterns in other states may differ
- County-level focus reflects major data center clusters; other significant sites may be excluded
- Temporal dynamics (facility closures, expansions) not captured in static analysis


## References

- CDC Environmental Justice Index (EJI): https://www.atsdr.cdc.gov/place-health/php/eji/index.html
- IM3 Data Center Atlas: https://data.msdlive.org/records/p147s-4h760
- U.S. Census Bureau: TIGER/Line Shapefiles (2020): https://www.census.gov/geographies/mapping-files/time-series/geo/tiger-line-file.2020.html#list-tab-790442341
