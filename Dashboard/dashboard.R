library(shiny)
library(tidyverse)
library(sf)
library(leaflet)
library(viridis)
library(htmltools)
library(scales)

# Create data needed for the dashboard ----
# This ensures CA_map_data, TX_map_data, VA_map_data, and data_centers_cleaned are loaded
source("~/Desktop/ENVST325/final_project/ENVST_325_final_project/analysis.R") 

# Gather variables for dashboard ----
# Grouped by category for a cleaner dropdown menu in the UI
granular_vars <- list(
  "Overall Modules" = c(
    "Social Vulnerability Index" = "RPL_SVM",
    "Environmental Burden Index" = "RPL_EBM",
    "Climate Burden Index" = "RPL_CBM"
  ),
  "Social Indicators" = c(
    "Poverty (Below 200%)" = "EPL_POV200",
    "No High School Diploma" = "EPL_NOHSDP",
    "Unemployment" = "EPL_UNEMP",
    "Renter-Occupied Housing" = "EPL_RENTER",
    "Housing Cost Burden" = "EPL_HOUBDN",
    "Uninsured Rate" = "EPL_UNINSUR",
    "No Internet Access" = "EPL_NOINT",
    "Age 65 or Older" = "EPL_AGE65",
    "Age 17 or Younger" = "EPL_AGE17",
    "Disability Status" = "EPL_DISABL",
    "Limited English Proficiency" = "EPL_LIMENG"
  ),
  "Environmental Indicators" = c(
    "Ozone Concentration" = "EPL_OZONE",
    "PM2.5 Concentration" = "EPL_PM",
    "Diesel Particulate Matter" = "EPL_DSLPM",
    "Air Toxics Cancer Risk" = "EPL_TOTCR",
    "Hazardous Waste (NPL) Proximity" = "EPL_NPL",
    "Toxic Release (TRI) Proximity" = "EPL_TRI",
    "TSD Facility Proximity" = "EPL_TSD",
    "RMP Facility Proximity" = "EPL_RMP",
    "Lead Mine Proximity" = "EPL_LEAD",
    "Lack of Park Access" = "EPL_PARK",
    "Pre-1980 Housing" = "EPL_HOUAGE",
    "Impaired Water Bodies" = "EPL_IMPWTR"
  ),
  "Climate & Health" = c(
    "Coastal Flooding Risk" = "EPL_CFLD",
    "Drought Risk" = "EPL_DRGT",
    "Hurricane Risk" = "EPL_HRCN",
    "Riverine Flooding Risk" = "EPL_RFLD",
    "High Wind Risk" = "EPL_SWND",
    "Tornado Risk" = "EPL_TRND",
    "Asthma Prevalence" = "EPL_ASTHMA",
    "Cancer Prevalence" = "EPL_CANCER",
    "Heart Disease Prevalence" = "EPL_CHD",
    "Mental Health Prevalence" = "EPL_MHLTH",
    "Diabetes Prevalence" = "EPL_DIABETES"
  )
)

# Data preparation for dashboard ----

# Standardize map polygons to WGS84 (EPSG 4326)
all_states_map <- bind_rows(
  CA_map_data %>% mutate(STATE_ABB = "CA"),
  TX_map_data %>% mutate(STATE_ABB = "TX"),
  VA_map_data %>% mutate(STATE_ABB = "VA")
) %>% st_transform(4326) 

# Standardize data center points to the same CRS (4326)
dcs_for_filter <- data_centers_cleaned %>% st_transform(4326)

# Aggregate by state and counties
counties_with_dcs <- all_states_map %>%
  st_filter(dcs_for_filter, .predicate = st_intersects) %>%
  st_drop_geometry() %>%
  select(STATE_ABB, COUNTY) %>%
  distinct()

# Prepare interactive tooltips
data_centers_interact <- dcs_for_filter %>%
  mutate(
    lng = st_coordinates(.)[,1],
    lat = st_coordinates(.)[,2],
    tooltip = paste0(
      "<div style='font-family: Arial; font-size: 12px;'>",
      "<b>Operator:</b> ", operator, "<br>",
      "<b>Name:</b> ", ifelse(is.na(name), "N/A", name), "<br>",
      "<b>SqFt:</b> ", ifelse(is.na(sqft), "N/A", scales::comma(sqft)), "<br>",
      "<b>Type:</b> ", type,
      "</div>"
    ) %>% lapply(htmltools::HTML)
  )

# Shiny UI ----
ui <- fluidPage(
  theme = bslib::bs_theme(bootswatch = "flatly"),
  titlePanel("Data Center Environmental Justice Index Explorer"),
  
  sidebarLayout(
    sidebarPanel(
      selectInput("state", "1. Select State:", choices = c("CA", "TX", "VA")),
      uiOutput("county_ui"),
      selectInput("variable", "3. Select EJI Variable:", choices = granular_vars),
      hr(),
      helpText("Background colors show EJI Percentile (0 to 1)."),
      helpText("Cyan points indicate data center locations. Hover/Click for details.")
    ),
    
    mainPanel(
      leafletOutput("leafmap", height = "850px")
    )
  )
)

# Shiny server ----
server <- function(input, output, session) {
  
  # Dynamic UI: Only show counties with data centers for the selected state
  output$county_ui <- renderUI({
    req(input$state)
    available_counties <- counties_with_dcs %>%
      filter(STATE_ABB == input$state) %>%
      pull(COUNTY) %>% sort()
    
    selectInput("county", "2. Select Impacted County:", 
                choices = c("All Impacted Counties", available_counties))
  })
  
  output$leafmap <- renderLeaflet({
    req(input$state, input$variable, input$county)
    
    # 1. Filter initial state data
    plot_map <- all_states_map %>% filter(STATE_ABB == input$state)
    plot_dcs <- data_centers_interact %>% filter(state_abb == input$state)
    
    # 2. Apply County Filter if a specific county is selected
    if (input$county != "All Impacted Counties") {
      plot_map <- plot_map %>% filter(COUNTY == input$county)
      # Use st_filter for robust point-in-county filtering
      plot_dcs <- plot_dcs %>% st_filter(plot_map)
    }
    
    # 3. Calculate bounding box for the view
    bounds <- st_bbox(plot_map)
    
    # 4. Define palette (Scale fixed 0 to 1)
    pal <- colorNumeric(palette = "magma", domain = c(0, 1), na.color = "#D3D3D3")
    
    # 5. Build the Leaflet Map
    leaflet() %>%
      addProviderTiles(providers$CartoDB.Positron) %>%
      fitBounds(
        lng1 = as.numeric(bounds$xmin), lat1 = as.numeric(bounds$ymin),
        lng2 = as.numeric(bounds$xmax), lat2 = as.numeric(bounds$ymax)
      ) %>%
      addPolygons(
        data = plot_map,
        fillColor = ~pal(plot_map[[input$variable]]),
        fillOpacity = 0.7,
        color = "white",
        weight = 0.5,
        highlightOptions = highlightOptions(weight = 2, color = "#666", fillOpacity = 0.9),
        label = ~paste0("County: ", COUNTY, " | Tract: ", GEOID)
      ) %>%
      addCircleMarkers(
        data = plot_dcs,
        lng = ~lng, lat = ~lat,
        color = "black", 
        fillColor = "cyan", 
        fillOpacity = 1, 
        weight = 1, 
        radius = 7,
        label = ~tooltip
      ) %>%
      addLegend(
        # Make the legend have 0 at the bottom and 1 at the top for readability
        pal = colorNumeric(palette = "magma", domain = c(0, 1), reverse = TRUE), 
        values = c(0, 1), 
        position = "bottomright", 
        title = "Percentile",
        labFormat = labelFormat(transform = function(x) sort(x, decreasing = TRUE))
      )
  })
}

shinyApp(ui, server)