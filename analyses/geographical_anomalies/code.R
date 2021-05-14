seedy <- as.numeric(Sys.time())
# Basic knitr options
library(knitr)
opts_chunk$set(comment = NA, 
               # echo = FALSE, 
               warning = FALSE, 
               message = FALSE, 
               error = TRUE, 
               cache = FALSE,
               fig.width = 9.64,
               fig.height = 5.9,
               fig.path = 'figures/')
options(scipen=999)

## Load libraries
library(bohemia)
library(ggplot2)
library(lubridate)
library(dplyr)
library(ggplot2)
library(sp)
library(raster)
library(ggthemes)
library(sf)
library(RColorBrewer)
library(readr)
library(tidyr)
library(leaflet)
library(rgeos)
# options(scipen = '999')
theme_set(databrew::theme_simple())

extract_ll <- function(x){
  lngs <- lats <- c()
  for(i in 1:length(x)){
    y <- x[i]
    lat <- unlist(lapply(strsplit(y[1], ' '), function(z){z[1]}))
    lng <- unlist(lapply(strsplit(y[1], ' '), function(z){z[2]}))
    lngs[i] <- lng; lats[i] <- lat
  }
  
  lng <- as.numeric(lngs); lat <- as.numeric(lats)
  return(tibble(lng = lng, lat = lat))
}

if('data.RData' %in% dir()){
  load('data.RData')
} else {
  pd_moz <- load_odk_data(the_country = 'Mozambique',
                          credentials_path = '../../../credentials/credentials.yaml',
                          users_path = '../../../credentials/users.yaml',
                          efficient = FALSE)
  pd_tza <- load_odk_data(the_country = 'Tanzania',
                          credentials_path = '../../../credentials/credentials.yaml',
                          users_path = '../../../credentials/users.yaml',
                          efficient = FALSE)
  is_local <- FALSE
  library(DBI)
  library(RPostgres)
  save(pd_moz,
       pd_tza,
       file = 'data.RData')
}

if('pre_load.RData' %in% dir()){
  load('pre_load.RData')
} else {
  
  minicensus_main <- bind_rows(
    pd_moz$minicensus_main,
    pd_tza$minicensus_main
  )
  
  df <- minicensus_main
  
  na_to_zero <- function(x){ifelse(is.na(x), 0, x)}
  gps <- bohemia::gps
  
  # Function for extracting lng and lat from a odk geocode object
  extract_ll <- function(x){
    lngs <- lats <- c()
    for(i in 1:length(x)){
      y <- x[i]
      lat <- unlist(lapply(strsplit(y[1], ' '), function(z){z[1]}))
      lng <- unlist(lapply(strsplit(y[1], ' '), function(z){z[2]}))
      lngs[i] <- lng; lats[i] <- lat
    }
    
    lng <- as.numeric(lngs); lat <- as.numeric(lats)
    return(tibble(lng = lng, lat = lat))
  }
  df$location <- df$hh_geo_location
  locs <- extract_ll(df$location)
  df$lng <- df$x <- locs$lng; df$lat <- df$y <- locs$lat
  df$code <- df$hh_hamlet_code
  df$country <- df$hh_country
  df <- df %>% filter(lat < -3)
  df <- df %>%
    filter((lat < -16 & country == 'Mozambique') |
             (lat > -12 & country == 'Tanzania')
    )
  library(sp)

  # Get the data grouped by codes
  codes <- sort(unique(df$code))
  locations_list <- list()
  locations_list_ll <- list()
  problem_list <- list()
  counter <- 0
  for(i in 1:length(codes)){
    # message('INDEX ', i)
    this_code <- codes[i]
    this_data <- df %>% filter(code == this_code) %>% mutate(x = lng, y = lat)
    coordinates(this_data) <- ~x+y
    proj4string(this_data) <- proj4string(bohemia::ruf2)
    # CRS("+proj=utm +zone=36 +south +ellps=WGS84 +datum=WGS84 +units=m +no_defs")
    ss <- spTransform(this_data, CRS("+proj=utm +zone=36 +south +ellps=WGS84 +datum=WGS84 +units=m +no_defs"))
    # Get distances
    # dd <- rgeos::gDistance(ss, byid = TRUE)
    # Throw out anything more than 3k from centroid?
    centroid <- apply(coordinates(ss), 2, median)
    centroid <- data.frame(t(as.data.frame(centroid)))
    coordinates(centroid) <- ~x+y
    proj4string(centroid) <- proj4string(ss)
    distance_from_centroid <- rgeos::gDistance(ss, centroid, byid = TRUE)
    remove_these <- which(distance_from_centroid > 3000)
    if(length(remove_these) > 0){
      counter <- counter + 1
      message('Removing ', length(remove_these), ' of ', nrow(ss), ' due to weird distances.')
      removals <- this_data[remove_these,]
      problem_list[[counter]] <- removals
      
      this_data <- this_data[!(1:nrow(this_data)) %in% remove_these,]
      ss <- ss[!(1:nrow(ss)) %in% remove_these,]
    } else {
      message('No removals for hamlet of ', nrow(ss))
    }
    locations_list_ll[[i]] <- this_data
    locations_list[[i]] <- ss
  }
  names(locations_list) <- names(locations_list_ll) <- codes
  locations_df <- do.call('rbind', locations_list)
  df <- locations_df@data
  df_sp <- df
  df_sp$x <- df_sp$lng
  df_sp$y <- df_sp$lat
  coordinates(df_sp) <- ~x+y
  proj4string(df_sp) <- proj4string(bohemia::ruf2)
  df_proj <- spTransform(df_sp,   CRS("+proj=utm +zone=36 +south +ellps=WGS84 +datum=WGS84 +units=m +no_defs")
  )
  
  # Get the problematic ones
  problems <- do.call('rbind', problem_list)
  
  # Combine problems and non problems
  df_sp@data$problematic <- FALSE
  problems@data$problematic <- TRUE
  combined <- rbind(
    df_sp,
    problems
  )
  
  
  save(df, codes, df_sp, problems, combined, file = 'pre_load.RData')
}

x <- combined@data %>% filter(country == 'Mozambique') %>% dplyr::select(hh_id, problematic) %>% mutate(action = ' ')
write_csv(x,
          '~/Desktop/hh_moz.csv')

x <- combined@data %>% filter(country == 'Tanzania') %>% dplyr::select(hh_id, problematic) %>% mutate(action = ' ')
write_csv(x,
          '~/Desktop/hh_tza.csv')



# M

# Make hulls
hull_list <- list()
for(i in 1:length(codes)){
  this_code <- codes[i]
  this_data <- combined[combined@data$code == this_code,]
  hull <- gConvexHull(spgeom = this_data, byid = FALSE)
  hull_list[[i]] <- hull
}

# Make leaflet
# cols <- ifelse(combined@data$problematic,
#                'red', 'blue')
colors <- rainbow(length(unique(codes)))
colors <- sample(colors, size = length(colors))
cols <- colors[as.numeric(factor(combined$code))]
l <- leaflet() %>%
  addProviderTiles(providers$Esri.WorldImagery) %>%
  addMarkers(data = problems,
             popup = paste0(problems@data$hh_id, '. ',
                            problems@data$hh_hamlet)) %>%
  addCircleMarkers(data = combined,
                   color = cols,
                   popup = paste0(combined@data$hh_id, '. ',
                                  combined@data$hh_hamlet),
                   radius = ifelse(combined@data$problematic, 4, 1),
                   fillOpacity = ifelse(combined@data$problematic, 0.9, 0.2),
                   fillColor = cols)
for(i in 1:length(hull_list)){
  this_hull <- hull_list[[i]]
  l <- l %>%
    addPolylines(data = this_hull,
                 color = colors[i],
                 fillColor = colors[i],
                 fillOpacity = 0.1)
}
l
htmlwidgets::saveWidget(l, '~/Desktop/hamlets.html', selfcontained = FALSE)
