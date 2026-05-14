# Data Center Environmental Justice Dashboard

## Overview

This is an interactive Shiny web application that allows users to explore the spatial relationship between data centers and environmental justice indicators (EJI) across California, Texas, and Virginia. The dashboard enables granular analysis of 37 different EJI variables at the Census tract level with dynamic filtering by state and county.

## Purpose

The dashboard serves as an interactive tool to:

- Visualize data center locations and environmental justice metrics simultaneously
- Examine over 37 granular EJI grouped by category
- Filter analysis by state and county to focus on specific regions
- Hover over Census tracts and data center points for detailed information
- Identify patterns of environmental and social vulnerability near data centers

## Getting Started

### Prerequisites

You must first run the `analysis.R` script to generate the required processed datasets.

### Installation

1. Install required R packages (if not already installed):

```r
install.packages(c("shiny", "tidyverse", "sf", "leaflet", "viridis", "htmltools", "scales", "bslib"))
```

2. Ensure you have access to the data files referenced in `analysis.R`:
   - IM3 Data Center Atlas CSV
   - CDC EJI 2024 United States CSV
   - 2020 Census Tract Shapefiles (CA, TX, VA)

### Running the App

1. Update the file path on line 11 to match your local directory structure:

```r
source("~/Desktop/ENVST325/final_project/ENVST_325_final_project/analysis.R")
```

2. Run the script in RStudio or R console:

```r
source("dashboard.R")
```

3. The Shiny app will open in your default browser (usually http://localhost:3838)

Alternatively, if this is saved in a Shiny app directory structure, run:

```r
shiny::runApp()
```

## Dependencies

```r
library(shiny)        # Web application framework
library(tidyverse)    # Data manipulation and visualization
library(sf)           # Spatial data handling
library(leaflet)      # Interactive mapping
library(viridis)      # Color palettes
library(htmltools)    # HTML utilities for tooltips
library(scales)       # Formatting utilities (number formatting)
library(bslib)        # Bootstrap styling themes
```

**R Version:** 4.0+ (required for newer sf and bslib features)

## Features

### Interactive Map

- **Choropleth Visualization:** Census tracts colored by EJI percentile rank (0–1 scale)
- **Dynamic Color Scale:** Uses Viridis "magma" palette for consistent visualization
- **Data Center Markers:** Cyan circle markers with black outlines highlighting facility locations
- **Base Map:** CartoDB Positron provides clean context without excessive detail
- **Hover Interactions:** Lightweight labels appear on hover for tracts and data centers

### Variable Selection

The dashboard provides access to 37 EJI-related variables grouped into four categories:

**Overall Modules (3 variables)**

- Social Vulnerability Index (RPL_SVM)
- Environmental Burden Index (RPL_EBM)
- Climate Burden Index (RPL_CBM)

**Social Indicators (11 variables)**

- Poverty (Below 200%)
- No High School Diploma
- Unemployment
- Renter-Occupied Housing
- Housing Cost Burden
- Uninsured Rate
- No Internet Access
- Age 65 or Older
- Age 17 or Younger
- Disability Status
- Limited English Proficiency

**Environmental Indicators (12 variables)**

- Ozone Concentration
- PM2.5 Concentration
- Diesel Particulate Matter
- Air Toxics Cancer Risk
- Hazardous Waste (NPL) Proximity
- Toxic Release (TRI) Proximity
- TSD Facility Proximity
- RMP Facility Proximity
- Lead Mine Proximity
- Lack of Park Access
- Pre-1980 Housing
- Impaired Water Bodies

**Climate & Health (11 variables)**

- Coastal Flooding Risk
- Drought Risk
- Hurricane Risk
- Riverine Flooding Risk
- High Wind Risk
- Tornado Risk
- Asthma Prevalence
- Cancer Prevalence
- Heart Disease Prevalence
- Mental Health Prevalence
- Diabetes Prevalence

### Dynamic Filtering

**State Selection**

- Choose between California (CA), Texas (TX), or Virginia (VA)
- Map automatically resets to state boundaries

**County Selection**

- Dropdown dynamically populates with only counties containing data centers in the selected state
- "All Impacted Counties" option shows state-wide view
- Selecting a specific county zooms and filters both map polygons and data center markers

**Variable Selection**

- Choose from 37 EJI variables organized by category
- Map updates in real-time to display the selected metric

## Application Structure

### Data Preparation (Lines 9–81)

1. **Data Loading:** Sources `analysis.R` to load processed spatial datasets
2. **Coordinate Reference System Standardization:** Converts all data to WGS84 (EPSG 4326) for Leaflet compatibility
3. **County-Data Center Index:** Identifies which counties contain data centers to enable smart filtering
4. **Interactive Tooltip Generation:** Creates HTML-formatted popups with formatted numbers for data center markers

### User Interface (Lines 97–116)

- **Theme:** Bootstrap "flatly" theme for clean, modern aesthetics
- **Layout:** Sidebar for controls, main panel for interactive map
- **Controls:**
  - State selection (dropdown)
  - County selection (dynamic dropdown)
  - EJI variable selection (grouped dropdown with 37 options)
  - Help text with usage instructions

### Server Logic (Lines 118–187)

1. **Dynamic County UI:** Renders county dropdown based on selected state
2. **Map Rendering:** 
   - Filters spatial data by state and county selections
   - Applies color palette based on selected EJI variable
   - Draws Census tract polygons with interactive highlighting
   - Overlays data center locations as interactive markers
3. **Bounds Calculation:** Automatically fits map view to filtered data extent
4. **Legend:** Shows percentile scale (0 to 1) with reversed magma palette for readability

## Data Notes

- **Percentile Ranks:** All EJI variables are expressed as percentile ranks (0 = least burdened, 1 = most burdened)
- **Color Interpretation:** 
  - **Dark/Black areas:** High EJI percentile (greater vulnerability)
  - **Light/Yellow areas:** Low EJI percentile (less vulnerability)
  - **Grey areas:** Missing data (NA values)
- **Spatial Reference:** All data in WGS84 (EPSG 4326) for Leaflet compatibility
- **Data Centers:** Only data centers falling within focus state boundaries are shown

## User Guide

### Step 1: Select a State

Click the "Select State" dropdown and choose CA, TX, or VA.

### Step 2: Choose a County (Optional)

By default, all data center-impacted counties for your selected state display. To focus on a specific county, select it from the "Select Impacted County" dropdown. The map will zoom to that county automatically.

### Step 3: Choose an EJI Variable

Select from 37 variables organized by category:

- Start with "Overall Modules" for broad vulnerability patterns
- Drill down into specific categories (Social, Environmental, Climate & Health) for detailed analysis

### Step 4: Explore the Map

- **Hover over Census tracts:** See county and tract GEOID
- **Click/hover on cyan points:** View data center details (operator, name, square footage, type)
- **Use map controls:** Zoom, pan, and reset view as needed

## Interpretation

Maps reveal how data center placement aligns with environmental and social vulnerability:

- **High percentile + nearby data centers:** Suggests potential environmental justice concern
- **Low percentile + data centers:** Data centers sited in less vulnerable areas
- **Visible patterns:** May indicate clustering of facilities in certain vulnerability profiles
- **Cross-variable analysis:** Compare social and environmental metrics to understand multidimensional vulnerability