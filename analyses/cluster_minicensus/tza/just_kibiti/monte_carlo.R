read_sims <- TRUE
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
                          credentials_path = '../../../../credentials/credentials.yaml',
                          users_path = '../../../../credentials/users.yaml',
                          efficient = FALSE)
  pd_tza <- load_odk_data(the_country = 'Tanzania',
                          credentials_path = '../../../../credentials/credentials.yaml',
                          users_path = '../../../../credentials/users.yaml',
                          efficient = FALSE)
  is_local <- FALSE
  library(DBI)
  library(RPostgres)
  save(pd_moz,
       pd_tza,
       file = 'data.RData')
}

x <- pd_tza$minicensus_main %>%
  filter(hh_country == 'Tanzania',
         hh_district == 'Kibiti DC') %>%
  group_by(code = hh_hamlet_code) %>%
  summarise(n_households_minicensus = n())
left <- bohemia::locations %>%
  filter(District == 'Kibiti DC') %>%
  dplyr::select(District, Ward, Village, Hamlet, code) %>%
  left_join(bohemia::gps %>% dplyr::select(code,
                                           n_households_recon = n_households))
joined <- left_join(left, x) %>%
  mutate(n_households_minicensus = ifelse(is.na(n_households_minicensus), 0, n_households_minicensus)) %>%
  mutate(percentage_done = n_households_minicensus / n_households_recon * 100)
joined <- joined %>% arrange(desc(percentage_done))
write_csv(joined, '~/Desktop/percentage_done_kibiti.csv')

x = joined %>%
  group_by(Ward) %>%
  summarise(any_hh = sum(n_households_minicensus) > 0,
            hh = sum(n_households_minicensus))

if('pre_load.RData' %in% dir()){
  load('pre_load.RData')
} else {
  
  minicensus_main <- bind_rows(
    pd_moz$minicensus_main,
    pd_tza$minicensus_main
  )
  minicensus_people <- bind_rows(
    pd_moz$minicensus_people,
    pd_tza$minicensus_people
  )
  na_to_zero <- function(x){ifelse(is.na(x), 0, x)}
  gps <- bohemia::gps
  
  df_adjust <- function(df){
    df %>%
      mutate(n_households = ifelse(df$iso == 'TZA', n_households * 1,
                                   ifelse(df$iso == 'MOZ', n_households * 0.55, 
                                          NA)))
  }
  
  ##################################################################
  ### REMOVE RUFIJI, JUST KEEP KIBITI ##############################
  ##################################################################
  ##################################################################
  ##################################################################
  locs <- bohemia::locations
  keep_locs <- locs %>% filter(District == 'Kibiti DC')
  
  pd_tza$minicensus_people$code <- substr(pd_tza$minicensus_people$permid, 1, 3)
  pd_tza$minicensus_main$code <- pd_tza$minicensus_main$hh_hamlet_code
  
  pd_tza$minicensus_people <- pd_tza$minicensus_people %>%
    filter(code %in% keep_locs$code)
  pd_tza$minicensus_main <- pd_tza$minicensus_main %>%
    filter(code %in% keep_locs$code)
  
  
  
  # Get age and household details
  ages <- 
    bind_rows(
      pd_moz$minicensus_people %>% mutate(country = 'Mozambique'),
      pd_tza$minicensus_people %>% mutate(country = 'Tanzania')
    ) %>%
    mutate(days_old = Sys.Date() - dob) %>%
    mutate(years_old = days_old / 365.25) %>%
    mutate(is_child  = ifelse(country == 'Mozambique',
                              years_old >= 0 & years_old < 5,
                              years_old >= 5 & years_old < 15)) %>%
    group_by(country) %>%
    summarise(children = length(which(is_child)),
              people = n()) %>%
    ungroup %>%
    mutate(percent_children = round(children / people * 100, digits = 2))
  
  hh <- bind_rows(
    pd_moz$minicensus_main %>% mutate(country = 'Mozambique'),
    pd_tza$minicensus_main %>% mutate(country = 'Tanzania')
  ) %>%
    group_by(country) %>%
    summarise(avg_size = mean(hh_size))
  
  # Create a df based on minicensus
  left <- minicensus_people %>%
    left_join(minicensus_main %>% dplyr::select(instance_id,
                                                country = hh_country)) %>%
    mutate(years_old = (Sys.Date() - dob)/ 365.25) %>%
    mutate(under5 = years_old >= 0 & years_old <= 5) %>%
    mutate(over15 = years_old >= 15) %>%
    mutate(is_child  = ifelse(country == 'Mozambique',
                              years_old >= 0 & years_old < 5,
                              years_old >= 5 & years_old < 15)) %>%
    mutate(is_boy = is_child & gender == 'male') %>%
    mutate(is_girl = is_child & gender == 'female') %>%
    group_by(country, instance_id) %>%
    summarise(n_members = n(),
              under5s = length(which(under5)),
              over15 = length(which(over15)),
              reproductive = length(which(gender == 'female' & years_old >=13 & years_old <= 49)),
              n_females = length(which(gender == 'female')),
              n_males = length(which(gender == 'male')),
              n_boys = length(which(is_boy)),
              n_girls = length(which(is_girl)),
              n_children = length(which(is_child)))
  df_full <- df <-
    left_join(left,
              minicensus_main %>% dplyr::select(instance_id,
                                                cows_1_year_plus = hh_n_cows_greater_than_1_year,
                                                cows_babies = hh_n_cows_less_than_1_year,
                                                pigs_6_weeks_plus = hh_n_pigs_greater_than_6_weeks,
                                                pigs_babies = hh_n_pigs_less_than_6_weeks,
                                                # country = hh_country,
                                                code = hh_hamlet_code,
                                                n_people = hh_size,
                                                location = hh_geo_location)) 
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
  locs <- extract_ll(df$location)
  df$lng <- df$x <- locs$lng; df$lat <- df$y <- locs$lat
  # df$code <- df$hh_hamlet_code
  df <- left_join(df, bohemia::locations %>% 
                    dplyr::distinct(code, .keep_all = TRUE) %>%
                    dplyr::select(code, clinical_trial))
  
  df <- df %>% filter(lat < -3)
  df <- df %>%
    filter((lat < -16 & country == 'Mozambique') |
             (lat > -12 & country == 'Tanzania')
    )
  library(sp)
  
  
  # Aggregate df
  df_agg <- df %>%
    group_by(code) %>%
    summarise(n_humans = sum(n_members),
              n_females = sum(n_females),
              n_males = sum(n_males),
              n_boys = sum(n_boys),
              n_girls = sum(n_girls),
              n_households = n(),
              n_children = sum(n_children),
              n_over15s = sum(over15),
              clinical_trial = dplyr::first(clinical_trial),
              country = dplyr::first(country),
              lng = mean(lng),
              lat = mean(lat),
              cows_1_year_plus = sum(cows_1_year_plus, na.rm = TRUE),
              cows_babies = sum(cows_babies, na.rm = TRUE),
              pigs_6_weeks_plus = sum(pigs_6_weeks_plus, na.rm = TRUE),
              pigs_babies = sum(pigs_babies, na.rm = TRUE))
  df_agg <- df_agg %>% arrange(code)
  
  
  # Read in cluster difficulty access scores (sent from Eldo)
  difficulty <- read_csv('Mopeia.Hamlets_Accessibility_Scores.08.03.2021.csv')
  difficulty <- difficulty %>% dplyr::select(code, difficulty = Accessibility_Scores)
  difficulty$difficulty_value <- 
    ifelse(difficulty$difficulty == 'Easy', 1,
           ifelse(difficulty$difficulty == 'Normal', 2,
                  ifelse(difficulty$difficulty == 'Hard', 3,
                         ifelse(difficulty$difficulty == 'Very Hard', 4,
                                NA))))
  # Read in difficulty sent by Imani on March 22 2021
  difficulty_tza <- read_csv('Bohemia hamlets_Accessibility.csv') %>%
    dplyr::select(code = hamlet_code,
                  difficulty = Accessibility) %>%
    mutate(difficulty_value = 
             ifelse(difficulty == 'Easy', 1,
                    ifelse(difficulty == 'Normal', 2,
                           ifelse(difficulty == 'Hard', 3,
                                  ifelse(difficulty == 'Very Hard', 4,
                                         NA)))))
  difficulty_tza <- difficulty_tza %>% filter(!duplicated(code))
  difficulty <- bind_rows(difficulty, difficulty_tza)
  difficulty <- difficulty %>% filter(!is.na(difficulty_value))
  df_agg <- left_join(df_agg, difficulty)
  df_agg <- df_agg %>% filter(!duplicated(code))
  df_agg <- df_agg %>% filter(!is.na(difficulty_value))
  
  
  
  # Get the data grouped by codes
  codes <- sort(unique(df_agg$code))
  locations_list <- list()
  locations_list_ll <- list()
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
      message('Removing ', length(remove_these), ' of ', nrow(ss), ' due to weird distances.')
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
  coordinates(df_sp) <- ~lng+lat
  proj4string(df_sp) <- proj4string(bohemia::ruf2)
  df_proj <- spTransform(df_sp,   CRS("+proj=utm +zone=36 +south +ellps=WGS84 +datum=WGS84 +units=m +no_defs")
  )
  
  
  # Remake the aggregated dataframe, overwriting df
  df <- df %>%
    ungroup %>%
    group_by(code) %>%
    summarise(n_humans = sum(n_members),
              under5s = sum(under5s),
              over15s = sum(over15),
              n_reproductive = sum(reproductive),
              n_females = sum(n_females),
              n_males = sum(n_males),
              n_boys = sum(n_boys),
              n_girls = sum(n_girls),
              n_households = n(),
              n_children = sum(n_children),
              clinical_trial = dplyr::first(clinical_trial),
              country = dplyr::first(country),
              lng = mean(lng),
              lat = mean(lat),
              cows_1_year_plus = sum(cows_1_year_plus, na.rm = TRUE),
              cows_babies = sum(cows_babies, na.rm = TRUE),
              pigs_6_weeks_plus = sum(pigs_6_weeks_plus, na.rm = TRUE),
              pigs_babies = sum(pigs_babies, na.rm = TRUE))
  df <- df %>% arrange(code)
  
  
  # Combine with difficulty
  df <- left_join(df, difficulty)
  
  # Define the relationship between n children and n clusters
  library(readxl)
  sizes_df <- read_excel('20210413 Children numbers eligible enrolled followed final.xlsx', sheet = 2, skip = 0)
  sizes_df <- sizes_df[,c(1,6)]
  names(sizes_df) <- c('n_children', 'n_clusters')
  sizes_df <- sizes_df[1:31,]
  sizes_df$n_children <- as.numeric(sizes_df$n_children)
  sizes_df$n_clusters <- sizes_df$n_clusters
  save(df, df_sp, sizes_df, difficulty, df_full, file = 'pre_load.RData')
}



## Voronoi households first
if('vh.RData' %in% dir()){
  load('vh.RData')
} else {
  households <- df_sp[df_sp@data$code %in% df$code[df$country == 'Tanzania'],]# %>% filter(country == 'Mozambique')
  households <- spTransform(households, proj4string(bohemia::ruf2))
  coords <- coordinates(households)
  households@data$lng <- coords[,1]
  households@data$lat <- coords[,2]
  households@data$id <- 1:nrow(households)
  households@data$n_children <- ifelse(is.na(households@data$n_children), 
                                       0, households@data$n_children)
  co <- households$country[1]
  if(co == 'Mozambique'){
    households@data$n_adults <- households@data$n_people - households@data$n_children
  } else {
    households@data$n_adults <- households@data$over15
  }
  households_projected <- spTransform(households, CRS("+proj=utm +zone=36 +south +ellps=WGS84 +datum=WGS84 +units=m +no_defs"))
  
  v <- voronoi(shp = households, poly = bohemia::ruf2)
  proj4string(v) <- proj4string(bohemia::ruf2)
  v@data$id <- 1:nrow(v)#  as.numeric(as.character(v@data$id))
  vp <- spTransform(v, CRS("+proj=utm +zone=36 +south +ellps=WGS84 +datum=WGS84 +units=m +no_defs"))
  o <- over(households_projected, polygons(vp))
  households_projected@data$id <- vp@data$id[o] # Overwriting due to irregularities
  households_projected <- households_projected[!is.na(households_projected@data$id),]
  households_projected <- households_projected[!duplicated(households_projected@data$id),]
  
  # Get supp info
  vp@data <- v@data <- left_join(vp@data, households_projected@data)
  vp@data$n_children <- ifelse(is.na(vp@data$n_children), 
                               0, vp@data$n_children)
  save(vp, households_projected,
       o, v, households, coords,
       file = 'vh.RData')
}

# Get the common boundary data
if(!'gt.RData' %in% dir()){
  gt <- gTouches(spgeom1 = vp, byid = TRUE)
  coords <- coordinates(vp)
  coords_df <- tibble(x = coords[,1], y = coords[,2])
  coordinates(coords_df) <- ~x+y
  proj4string(coords_df) <- proj4string(vp)
  gd <- gDistance(spgeom1 = coords_df, byid = T)
  # Get distance between households
  gdh <- gDistance(spgeom1 = households_projected, byid = T)
  save(gt, gd, file = 'gt.RData')
} else {
  load('gt.RData')
}


# Define a function for creating a core
set.seed(seedy)
library(rangemap)
library(raster)
create_core <- function(this, eligibles, gt, gd, buffer_distance = 1000,
                        n_kids = 35){
  # this = vp[5,]
  # eligibles = vp
  no_more <- FALSE
  original <- this
  enough <- sum(this@data$n_children, na.rm = TRUE) >= n_kids
  counter <- 0
  while(!enough){
    counter <- counter + 1
    # message(counter)
    # Get the possible nearby ones
    sub_gt <- gt[this@data$id,
                 eligibles@data$id]
    if(is.matrix(sub_gt)){
      sub_gt <- apply(sub_gt, 2, any)
    }
    sub_eligibles <- eligibles[sub_gt,]
    # Sample one of them
    sample_vec <- sub_eligibles@data$id
    sample_vec <- sample_vec[!sample_vec %in% this@data$id]
    # Get the closest one to the core
    sub_gd <- gd[original@data$id, sample_vec]
    if(is.matrix(sub_gd)){
      sub_gd <- apply(sub_gd, 1, min)
    }
    keep <- sample_vec[which.min(sub_gd)]
    new_one <- sub_eligibles[sub_eligibles@data$id %in% keep,]
    if(nrow(new_one@data) == 0){
      enough <- TRUE
      no_more <- TRUE
    } else {
      this <- rbind(
        this,
        new_one
      )
      n_children <- sum(this@data$n_children, na.rm = TRUE)
      enough <- n_children >= n_kids
    }
  }
  if(no_more){
    out <- list(0)
    names(out) <- 'done'
  } else {
    # Get output object
    poly <- this
    pts <- households_projected[households_projected@data$id %in% poly@data$id,]
    if(nrow(pts) == 1){
      hull <- gBuffer(pts, width = 0.1)
    } else if(nrow(pts) == 2){
      ll <- spLines(pts); proj4string(ll) <- proj4string(pts)
      hull <- gBuffer(ll, width = 0.1)
    } else {
      suppressMessages({hull <- hull_polygon(pts, hull_type = 'concave')})
      hull <- gBuffer(hull, width = 0.1)
    }
    # Now overwrite the pts to make sure that we're getting the full ones (nothing overlaps and slips in)
    ox <- over(households_projected, polygons(hull))
    pts <- households_projected[!is.na(ox),]
    hull <- SpatialPolygonsDataFrame(Sr = hull,data = data.frame(x = 1), match.ID = F)
    buf <- gBuffer(hull, width = buffer_distance, quadsegs = 1000)
    buf <- SpatialPolygonsDataFrame(Sr = buf,data = data.frame(x = 1), match.ID = F)
    out <- list(poly, pts, hull, buf)
    names(out) <- c('poly', 'pts', 'hull', 'buf') 
  }
  return(out)
}

# Decide whether we are just using already created simulations, or running a simulation
if(read_sims){
  # Identify what the sims files are
  sim_files <- dir()
  sim_files <- sim_files[grepl('.RData', sim_files)]
  sim_numbers <- gsub('.RData', '', sim_files)
  keep <- !is.na(as.numeric(sim_numbers))
  sim_files <- sim_files[keep]
  master_poly_list <- master_pts_list <- master_hull_list <- master_buf_list <- list()
  for(i in 1:length(sim_files)){
    this_sim_file <- sim_files[i]
    load(this_sim_file)
    
    master_poly@data$sim <- i
    master_pts@data$sim <- i
    master_hull@data$sim <- i
    master_buf@data$sim <- i
    
    master_poly_list[[i]] <- master_poly
    master_pts_list[[i]]  <- master_pts
    master_hull_list[[i]] <- master_hull
    master_buf_list[[i]] <- master_buf
  }
  # # Combine all together
  # master_poly <- do.call('rbind', master_poly_list)
  # master_pts <- do.call('rbind', master_pts_list)
  # master_hull <- do.call('rbind', master_hull_list)
  # master_buf <- do.call('rbind', master_buf_list)
} else {
  
  # Going to carry out a simulation instead
  
  seed_file_name <- paste0(seedy, '.RData')
  if(seed_file_name %in% dir()){
    load(seed_file_name)
  } else {
    # Loop through some parameters
    buffer_distances <- buffer_distances <- c(400, 600)
    n_childrens <- c(20, 25)
    iterations <- length(buffer_distances) * length(n_childrens)
    master_counter <- 0
    master_poly_list <- master_pts_list <- master_hull_list <- master_buf_list <- list()
    for(buffer_distance in buffer_distances){
      for(n_children in n_childrens){
        start_time <- Sys.time()
        master_counter <- master_counter + 1
        
        # Loop through each polygon, joining only to adjacent polygons
        # buffer_distance <- 1000
        # n_children <- 35
        n_clusters <- sizes_df$n_clusters[sizes_df$n_children == n_children]
        done <- FALSE
        eligibles <- vp
        cluster_counter <- 0
        pts_list <- poly_list <- hull_list <- buf_list <- list()
        while(!done){
          set.seed(seedy)
          cluster_counter <- cluster_counter + 1
          message('Iteration ', master_counter, ' of ', iterations, ' | Distance: ', buffer_distance, '. Children per cluster: ', n_children, '. Cluster ', cluster_counter, '. Clusters needed: ', n_clusters)
          cant_find_starter <- TRUE
          failure_counter <- 0
          while(cant_find_starter){
            if(failure_counter > 0){
              message('---', failure_counter, ' failures...')
            }
            # Get a random starting point
            random_index <- sample(eligibles@data$id, 1)
            # Create a core
            starter <- eligibles[eligibles@data$id == random_index,]
            core <- create_core(this = starter,
                                eligibles = eligibles,
                                gt = gt,
                                gd = gd,
                                buffer_distance = buffer_distance,
                                n_kids = n_children)
            
            if(length(core) > 1){
              # Check if it overlaps with anything created yet
              any_overlap <- FALSE
              if(cluster_counter > 1){
                # # The below can result in ZONES overlapping, but no point will fall into more than one zone
                # any_overlap <- any(!is.na(over(combined_pts, polygons(gBuffer(core$buf, width = 1)))))
                # The below ensures no overlap between ZONES
                any_overlap <- any(!is.na(over(gBuffer(combined_buf, width = 1), polygons(gBuffer(core$buf, width = 1)))))
              }
              
              if(!any_overlap){
                # message('--- no overlaps, keep going')
                cant_find_starter <- FALSE
              } else {
                message('--- overlap detected, throwing out this core and trying again')
                failure_counter <- failure_counter + 1
                if(failure_counter > 100){
                  break
                }
              }
              
            } else {
              failure_counter <- failure_counter + 1
              if(failure_counter > 100){
                break
              }
            }
          }
          
          if(length(core) == 1){
            # try again with a different random index
            message('All done with ', cluster_counter, ' clusters.')
            done <- TRUE
          } else {
            # Identify anything that might fall into the buffer
            o <- over(households_projected, polygons(gBuffer(core$buf, width = 1)))
            buffer_indices <- which(!is.na(o))
            buffer_ids <- households_projected@data$id[buffer_indices]
            # don't count into buffer ids anything which is in the core
            core_ids <- core$pts@data$id
            buffer_ids <- buffer_ids[!buffer_ids %in% core_ids]
            # Keep both buffer and core points (these go to the output)
            buffer_pts <- households_projected[households_projected@data$id %in% buffer_ids,]
            core_pts <- households_projected[households_projected@data$id %in% core_ids,]# core$pts
            # Combine them
            core_pts@data$status <- 'core'
            if(nrow(buffer_pts@data) > 0){
              buffer_pts@data$status <- 'buffer'
              pts <- rbind(buffer_pts, core_pts)
            } else {
              pts <- core_pts
            }
            # Do the same as above, but for polys
            buffer_polys <- vp[vp@data$id %in% buffer_ids,]
            core_polys <- core$poly
            core_polys@data$status <- 'core'
            if(nrow(buffer_polys@data) > 0){
              buffer_polys@data$status <- 'buffer'; 
              poly <- rbind(buffer_polys, core_polys)
            } else {
              poly <- core_polys
            }
            
            # Now we want to remove from eligibles the following:
            # 1. core points
            # 2. buffer points
            # 3. anything within a km of buffer points (since this would be too close for building a new core)
            eligible_pts <- households_projected[households_projected@data$id %in% eligibles@data$id,]
            eligible_pts <- eligible_pts[!eligible_pts@data$id %in% pts@data$id,] # first removed core+ buffer
            eligibles <- eligibles[!eligibles@data$id %in% pts@data$id,]
            # also need to go a further kilometer out in order to ensure that buffers don't overlap
            outer_buf <- gBuffer(polygons(core$buf), width = buffer_distance+1)
            o2 <- over(households_projected, outer_buf)
            remove_inidices <- which(!is.na(o2))
            remove_these <- households_projected@data$id[remove_inidices]
            eligibles <- eligibles[!eligibles@data$id %in% remove_these,]
            eligible_pts <- eligible_pts[!eligible_pts@data$id %in% remove_these,]
            
            # Save the results in lists
            pts@data$cluster <- cluster_counter
            poly <- core$poly
            poly@data$cluster <- cluster_counter
            hull <- core$hull 
            hull@data$cluster <- cluster_counter
            buf <- core$buf
            buf@data$cluster <- cluster_counter
            poly@data$cluster <- cluster_counter
            poly_list[[cluster_counter]] <- poly
            hull_list[[cluster_counter]] <- hull
            pts_list[[cluster_counter]] <- pts
            buf_list[[cluster_counter]] <- buf
            
            # # Get some combined stuff and plot
            combined_poly <- do.call('rbind', poly_list)
            combined_pts <- do.call('rbind', pts_list)
            combined_hull <- do.call('rbind', hull_list)
            combined_buf <- do.call('rbind', buf_list)
            # plot(combined_buf)
            # plot(combined_hull, add = T)
            # points(combined_pts, col = ifelse(combined_pts@data$status == 'core', 'green', 'red'),
            #      pch = '.')
            # title(main = paste0('Done with cluster number ', cluster_counter, ' of ', n_clusters),
            #       sub = paste0('So far: ', sum(combined_pts@data$n_adults), ' adults and ',
            #                    nrow(combined_pts@data), ' households'))
            # # plot(combined_poly[combined_poly@data$status == 'core',], add = T, col = adjustcolor('red', alpha.f = 0.5))
            # # 
            done <- cluster_counter >= n_clusters
            # Sys.sleep(1)
          }
        }
        
        combined_poly <- do.call('rbind', poly_list)
        combined_pts <- do.call('rbind', pts_list)
        combined_hull <- do.call('rbind', hull_list)
        combined_buf <- do.call('rbind', buf_list)
        
        # Save to the final outcomes list
        combined_poly@data$iter_buffer_distance <- buffer_distance
        combined_pts@data$iter_buffer_distance <- buffer_distance
        combined_hull@data$iter_buffer_distance <- buffer_distance
        combined_buf@data$iter_buffer_distance <- buffer_distance
        combined_poly@data$iter_n_children <- n_children
        combined_pts@data$iter_n_children <- n_children
        combined_hull@data$iter_n_children <- n_children
        combined_buf@data$iter_n_children <- n_children
        
        master_poly_list[[master_counter]] <- combined_poly
        master_pts_list[[master_counter]] <- combined_pts
        master_hull_list[[master_counter]] <- combined_hull
        master_buf_list[[master_counter]] <- combined_buf
        stop_time <- Sys.time()
        took_time <- difftime(stop_time, start_time, units = 'mins')
        message('That took: ', round(took_time, digits = 1), ' minutes.')
      }
    }
    
    
    # Create combined "master
    master_poly <- do.call('rbind', master_poly_list)
    master_pts <- do.call('rbind', master_pts_list)
    master_hull <- do.call('rbind', master_hull_list)
    master_buf <- do.call('rbind', master_buf_list)
    save(master_poly, master_pts, master_hull, master_buf, file = seed_file_name)
  }
}

# Write a csv of outputs for Carlos
if(read_sims){
  data_list <- list()
  for(i in 1:length(master_pts_list)){
    data_list[[i]] <- master_pts_list[[i]]@data
  }
  x <- do.call('rbind', data_list)
  
  # Get numbers per different parameters
  pd <- x %>%
    ungroup %>%
    group_by(iter_buffer_distance,
             iter_n_children, sim) %>%
    summarise(n_real_clusters = length(unique(cluster)),
              n_children_core = sum(n_children[status == 'core']),
              treatable_adults = sum(n_adults),
              n_reproductive = sum(reproductive),
              n_cows_1_year_plus = sum(cows_1_year_plus, na.rm = TRUE),
              n_cows_babies = sum(cows_babies, na.rm = TRUE),
              n_pigs_6_weeks_plus = sum(pigs_6_weeks_plus, na.rm = TRUE),
              n_pigs_babies = sum(pigs_babies, na.rm = TRUE)) %>%
    ungroup %>%
    left_join(sizes_df,
              by = c('iter_n_children' = 'n_children')) %>%
    mutate(valid = n_real_clusters >= n_clusters) %>%
    filter(valid) %>%
    # get average per sim
    group_by(iter_buffer_distance,
             iter_n_children) %>%
    summarise(n_children_core = mean(n_children_core),
              n_real_clusters = mean(n_real_clusters),
              adults = mean(treatable_adults),
              n_reproductive = mean(n_reproductive),
              n_cows_1_year_plus = mean(n_cows_1_year_plus),
              n_cows_babies = mean(n_cows_babies),
              n_pigs_6_weeks_plus = mean(n_pigs_6_weeks_plus),
              n_pigs_babies = mean(n_pigs_babies))
  write_csv(pd, 'carlos.csv')
  # Get just for the 400 m 20 kids scenario
  out <- pd %>% filter(iter_buffer_distance == 400,
                       iter_n_children == 20)
  
  # Get numbers for different parameters BY ASSIGNMENT STATUS
  
  assignment_df <- tibble(
    cluster = sort(unique(x$cluster))
  )
  a <- rep(1:3, each = ceiling(nrow(assignment_df)/3))
  a <- sample(a, size = length(a), replace = F)
  assignment_df$assignment <- a[1:nrow(assignment_df)]
  x <- left_join(x, assignment_df)
 
  pd <- x %>%
    ungroup %>%
    group_by(iter_buffer_distance,
             iter_n_children, sim,
             assignment) %>%
    summarise(n_real_clusters = length(unique(cluster)),
              n_children_core = sum(n_children[status == 'core']),
              treatable_adults = sum(n_adults),
              n_reproductive = sum(reproductive),
              n_cows_1_year_plus = sum(cows_1_year_plus, na.rm = TRUE),
              n_cows_babies = sum(cows_babies, na.rm = TRUE),
              n_pigs_6_weeks_plus = sum(pigs_6_weeks_plus, na.rm = TRUE),
              n_pigs_babies = sum(pigs_babies, na.rm = TRUE)) %>%
    ungroup %>%
    left_join(sizes_df,
              by = c('iter_n_children' = 'n_children')) %>%
    # mutate(valid = n_real_clusters >= n_clusters) %>%
    # filter(valid) %>% # doesnt work because n_real is just 1/3 of actual
    # get average per sim
    group_by(iter_buffer_distance,
             iter_n_children, assignment) %>%
    summarise(n_children_core = mean(n_children_core),
              n_real_clusters = mean(n_real_clusters),
              adults = mean(treatable_adults),
              n_reproductive = mean(n_reproductive),
              n_cows_1_year_plus = mean(n_cows_1_year_plus),
              n_cows_babies = mean(n_cows_babies),
              n_pigs_6_weeks_plus = mean(n_pigs_6_weeks_plus),
              n_pigs_babies = mean(n_pigs_babies))
  carlos_table <- pd
  write_csv(pd, 'carlos3.csv')
  
  
  
}


# ######################## DELETE THE BELOW
xx <- households_projected
xx <- spTransform(xx, proj4string(bohemia::ruf2))

right <- master_pts[master_pts@data$iter_buffer_distance == 600 &
                      master_pts@data$iter_n_children == 25,]
table(duplicated(right@data$id))
dd <- right[right@data$id %in% right@data$id[duplicated(right@data$id)],]
# View(dd@data)
xpolys <- master_hull[master_hull@data$iter_buffer_distance == 600 &
                        master_hull@data$iter_n_children == 25,]
xpolys <- spTransform(xpolys, proj4string(bohemia::ruf2))
xbuf <- master_buf[master_buf@data$iter_buffer_distance == 600 &
                     master_buf@data$iter_n_children == 25,]
xbuf <- spTransform(xbuf, proj4string(bohemia::ruf2))
xx@data <- left_join(xx@data %>% ungroup, right@data %>% ungroup %>% dplyr::select(id, status, cluster))
xx@data$color <- ifelse(xx@data$status == 'core', 'red',
                        ifelse(xx@data$status == 'buffer', 'blue',
                               'black'))
l <- leaflet() %>% addTiles() %>%
  addCircleMarkers(data = xx,
                   color = xx@data$color,
                   popup = paste0('Status ', xx@data$status, ' Cluster number ', xx@data$cluster)) %>%
  addMeasure(primaryLengthUnit = 'meters') %>%
  addPolylines(data = xpolys, weight = 3, color = 'red') %>%
  addPolylines(data = xbuf, weight = 3, color = 'black')
# htmlwidgets::saveWidget(l, file = '~/Desktop/clusters_tza.html', selfcontained = FALSE)


# Request 13 april 2021
assignment_df <- tibble(
  cluster = sort(unique(xx@data$cluster))
)
a <- rep(1:3, each = ceiling(nrow(assignment_df)/3))
a <- sample(a, size = length(a), replace = F)
assignment_df$assignment <- a[1:nrow(assignment_df)]
xx@data <- left_join(xx@data,
                     assignment_df)

pd <- xx@data %>%
  group_by(assignment, cluster) %>%
  summarise(pigs_6_weeks_plus = sum(pigs_6_weeks_plus, na.rm = T),
            pigs_babies = sum(pigs_babies, na.rm = T),
            cows_1_year_plus = sum(cows_1_year_plus, na.rm = T),
            cows_babies = sum(cows_babies, na.rm = T))


# Carlos request, 2021-04-13

# 1. Histogram of animal numbers by cluster assignment group (to assess need for stratification)

pdx <- pd %>% tidyr::gather(key, value, pigs_6_weeks_plus:cows_babies) %>%
  filter(!is.na(assignment)) %>%
  mutate(assignment = paste0('Assignment group ', assignment))
ggplot(data = pdx,
       aes(x = value+0.001)) +
  geom_density(alpha = 0.6,
               fill = 'darkorange') +
  facet_grid(key~assignment) +
  scale_x_log10() +
  theme(strip.text = element_text(size = 6),
        plot.title = element_text(size = 12)) +
  labs(x = 'Value', y = 'Density',
       title = 'Distribution of animals per cluster, TZA')


# 2. The list of hamlets included in clusters so far (to prioritize FW assignment and hiring)
xx@data <- left_join(
  xx@data,
  households@data %>% dplyr::select(instance_id, code)
)
pd <- xx@data %>%
  filter(!is.na(status)) %>%
  group_by(code) %>%
  summarise(n_hh = n()) %>%
  ungroup %>%
  arrange(desc(n_hh))
pd <- left_join(pd,
                locations %>% dplyr::select(code,
                                            Village,
                                            Hamlet, Ward))
write_csv(pd,
          '~/Desktop/carlosapr13tza.csv')

pdw <- pd %>%
  group_by(Ward) %>%
  summarise(n_hh = sum(n_hh))

write_csv(pdw,
          '~/Desktop/carlosapr13wardstza.csv')
########################

if(read_sims){
  # Get some analysis for each scenario
  data_list <- list()
  for(i in 1:length(master_pts_list)){
    data_list[[i]] <- master_pts_list[[i]]@data
  }
  x <- do.call('rbind', data_list)
  pd <- x %>%
    ungroup %>%
    group_by(iter_buffer_distance,
             iter_n_children, sim) %>%
    summarise(n_real_clusters = length(unique(cluster)),
              n_children_core = sum(n_children[status == 'core']),
              treatable_adults = sum(n_adults)) %>%
    ungroup %>%
    left_join(sizes_df,
              by = c('iter_n_children' = 'n_children')) %>%
    mutate(valid = n_real_clusters >= n_clusters) %>%
    filter(valid) %>%
    # get average per sim
    group_by(iter_buffer_distance,
             iter_n_children) %>%
    summarise(n_children_core = mean(n_children_core),
              n_real_clusters = mean(n_real_clusters),
              treatable_adults = mean(treatable_adults))
    
  # mutate(valid = ifelse(valid, 'Sufficient number of clusters',
  #                       'Not enough clusters formed'))
  
  cols <- colorRampPalette(RColorBrewer::brewer.pal(n = 9, 'Spectral'))(length(unique(pd$iter_n_children)))
  # cols[3] <- 'darkgrey'
  # cols[3:4] <- c('black', 'grey')
  ggplot(data = pd,
         aes(x = iter_buffer_distance,
             y = treatable_adults)) +
    geom_point(aes(#pch = valid,
      color = factor(iter_n_children)),
      size = 4,
      alpha = 0.5) +
    theme(legend.position = 'bottom') +
    geom_line(aes(color = factor(iter_n_children),
                  group = factor(iter_n_children)),
              size = 1.5,
              alpha = 0.9) +
    scale_color_manual(name = 'Number of\nchildren in core',
                       values = cols) + #  rainbow(length(unique(pd$iter_n_children)))) +
    labs(x = 'Buffer distance (meters)',
         title = 'Cluster formation strategies comparison') +
    scale_y_continuous(name = 'Treatable adults (buffer + core)',
                       breaks = seq(10000, 70000, by = 10000)) +
    geom_hline(yintercept = seq(10000, 70000, by = 10000),
               lty = 2, alpha = 0.6)
  ggsave('~/Desktop/strategies.png', height = 12, width = 8)  
}


# Also get distance to edge of buffer, distance to nearest contaminant, etc
if(read_sims){
  # Identify what the sims files are
  sim_files <- dir()
  sim_files <- sim_files[grepl('.RData', sim_files)]
  sim_files <- sim_files[grepl('all_pts_', sim_files)]
  all_pts_list <- list()
  for(i in 1:length(sim_files)){
    this_sim_file <- sim_files[i]
    load(this_sim_file)
    all_pts@data$sim <- i
    all_pts_list[[i]] <- all_pts
  }

} else {
  seed_pts_name <- paste0('all_pts_', seedy, '.RData')
  if(seed_pts_name %in% dir()){
    load(seed_pts_name)
  } else {
    
    # Get a 1 km border around each household
    # radius_distances <- seq(500, 1000, 100)
    # full_list <- list()
    # for(i in 1:length(radius_distances)){
      # this_distance <- radius_distances[i]
    this_distance <- 1000
    radius <- gBuffer(households_projected, byid = T, width = this_distance)
    over_radius <- over(x = households_projected, y = polygons(radius), returnList = T)
    radius_list <- list()
    for(j in 1:length(over_radius)){
      out <- tibble(this_id = households_projected@data$id[j],
                    id = households_projected@data$id[unlist(over_radius[[j]])]) #%>%
      # mutate(radius_distance = this_distance)
      radius_list[[j]] <- out
    }
    radius_df <- bind_rows(radius_list)
    # full_list[[i]] <- radius_df
    # }

    iters_buffer_distance <- sort(unique(master_pts@data$iter_buffer_distance))
    iters_n_children <- sort(unique(master_pts@data$iter_n_children))
    contaminant_list <- list()
    counter <- 0
    iters <- length(iters_buffer_distance) * length(iters_n_children)
    for(buffer_distance in iters_buffer_distance){
      for(n_children in iters_n_children){
        counter <- counter + 1
        message(counter, ' of ', iters, '. Buffer: ', buffer_distance, '. Children: ', n_children)
        # Get the points
        these_buf <- master_buf[master_buf@data$iter_buffer_distance == buffer_distance & master_buf@data$iter_n_children == n_children,]
        these_pts <- master_pts[master_pts@data$iter_buffer_distance == buffer_distance & master_pts@data$iter_n_children == n_children,]

        # Keep only those in the core
        core <- these_pts[these_pts@data$status == 'core',]
        buff <- these_pts[!is.na(these_pts@data$status),]
        
        # Assign temporary assignations for the purpose of estimating
        # distances to contaminants
        assignment_df <- tibble(
          cluster = sort(unique(core@data$cluster))
        )
        a <- rep(1:3, each = ceiling(nrow(assignment_df)/3))
        a <- sample(a, size = length(a), replace = F)
        assignment_df$assignment <- a[1:nrow(assignment_df)]
        buff@data <- left_join(buff@data, assignment_df)
        # Bring the assignment into ALL points, since that is how contamination is determined
        all_pts <- households_projected
        all_pts@data <- left_join(all_pts@data, buff@data %>% ungroup %>% dplyr::select(assignment, id),
                                  by = 'id')
        
        # Assuming that non-cluster areas are group 1
        all_pts@data$assignment <- ifelse(is.na(all_pts@data$assignment), 1, all_pts@data$assignment)
        
        # Get the assignments into the radius data
        # (this will contain one row for each assignment in the 1 km area)
        sub_radius <- radius_df %>%
          left_join(all_pts@data %>% ungroup %>% dplyr::select(id, assignment)) %>%
          dplyr::select(-id) %>%
          dplyr::rename(id = this_id) %>%
          # now grouping by id to get each type
          group_by(id, assignment) %>%
          summarise(n_assig = n()) %>%
          ungroup %>% 
          # get the assignment for the person in question
          left_join(all_pts@data %>% ungroup %>% dplyr::select(id, self_assignment = assignment)) %>%
          mutate(is_same = assignment == self_assignment) %>%
          group_by(id) %>%
          summarise(n_same = sum(n_assig[is_same]),
                    n_diff = sum(n_assig[!is_same]),
                    n_1k = sum(n_assig)) %>%
          ungroup %>%
          mutate(p_same = n_same / n_1k * 100,
                 n_diff = n_diff / n_1k * 100)
        all_pts@data <- left_join(all_pts@data,
                                  sub_radius)
        
        
        # Get number of people within a radius of identical assignment status
        all_pts@data$nearest_contaminant <- NA
        
        # # Get distance to contaminant
        # for(i in 1:3){
        #   message('...group ', i, ' of 3')
        #   g1 <- sub_gd[which(all_pts@data$assignment == i),
        #                which(all_pts@data$assignment != i)]
        #   g2 <- apply(g1, 1, function(x){min(x, na.rm = TRUE)})
        #   all_pts@data$nearest_contaminant[all_pts@data$assignment == i] <- g2
        # }
        # Subset to only include those in the study core
        keep <- all_pts[all_pts@data$id %in% core@data$id,]
        keep@data$iter_n_children <- n_children
        keep@data$iter_buffer_distance <- buffer_distance
        # flag <- length(which(is.na(keep@data$nearest_contaminant)))
        # if(flag > 0){
        #   message('PROBLEM!!!')
        # }
        contaminant_list[[counter]] <- keep
      }
    }
    all_pts <- do.call('rbind', contaminant_list)
    save(all_pts, file = seed_pts_name)
  }
}

# Can we do it with just kibiti
charf <- master_pts@data %>%
  filter(iter_buffer_distance == 400,
         iter_n_children == 20)
table(charf$cluster)

# 
py <- master_pts[master_pts@data$iter_n_children == 20 &
                   master_pts@data$iter_buffer_distance == 400,]
py <- spTransform(py, proj4string(ruf2))

px <- master_hull[master_hull@data$iter_n_children == 20 &
                    master_hull@data$iter_buffer_distance == 400,]
px <- spTransform(px, proj4string(ruf2))

pz <- master_buf[master_buf@data$iter_n_children == 20 &
                   master_buf@data$iter_buffer_distance == 400,]
px <- spTransform(px, proj4string(ruf2))
pz <- spTransform(pz, proj4string(ruf2))
gx <- gps %>% filter(iso == 'TZA')
gx <- left_join(gx, locations)
gx <- gx %>% filter(District != 'Kibiti DC')
l <- leaflet() %>%
  addPolygons(data = px,
              popup = paste0('Cluster: ', px$cluster)) %>% 
  addPolylines(data = ruf2) %>% 
  addCircleMarkers(data = gx,
                   fillOpacity = 0.2,
                   fillColor = 'black',
                   radius = 1,
                   color = 'black',
                   popup = paste0(gx$hamlet, ' ', gx$code)) %>%
  addProviderTiles(providers$Esri.WorldImagery) %>%
  addPolylines(data = pz, color = 'red') %>%
  addMeasure(primaryLengthUnit = 'meters') %>%
  addCircleMarkers(data = py,
                   fillOpacity = 0.2,
                   fillColor = 'purple',
                   radius = 1,
                   color = 'purple',
                   popup = paste0('Status: ', py$status, '. ', py$n_children))
l
htmlwidgets::saveWidget(l, '~/Desktop/kibiti2.html', selfcontained = FALSE)

if(read_sims){
  # Plot of percent contamination
  cols <- c('black', 'red', 'darkorange')
  data_list <- list()
  for(i in 1:length(all_pts_list)){
    data_list[[i]] <- all_pts_list[[i]]@data
  }
  
  # Joe 2021-05-17
  # for(i in 1:length(master_pts_list)){
  #   master_pts_list[[i]] <- master_pts_list[[i]]@data
  # }
  
  x <- bind_rows(data_list)
  
  
  x <- x %>%
    mutate(iter_buffer_distance = paste0('Buffer: ', iter_buffer_distance)) %>%
    mutate(iter_n_children = paste0( bohemia::add_zero(iter_n_children, 2), ' kids')) %>%
    mutate(assignment = factor(assignment))
  agg <- x %>%
    group_by(iter_buffer_distance, iter_n_children, assignment) %>%
    summarise(hh = n(),
              avg_p_same = mean(p_same, na.rm = TRUE),
              med_p_same = median(p_same, na.rm = TRUE),
              n_children_core = sum(n_children)#,
              # COMMENTING OUT THE BELOW SINCE IT IS CORE ONLY
              # treatable_adults = sum(n_adults),
              # n_reproductive = sum(reproductive),
              # n_cows_1_year_plus = sum(cows_1_year_plus, na.rm = TRUE),
              # n_cows_babies = sum(cows_babies, na.rm = TRUE),
              # n_pigs_6_weeks_plus = sum(pigs_6_weeks_plus, na.rm = TRUE),
              # n_pigs_babies = sum(pigs_babies, na.rm = TRUE)
              ) %>%
    ungroup %>%
    # get average per sim
    group_by(iter_buffer_distance,
             iter_n_children,
             assignment) %>%
    summarise(hh = mean(hh),
              avg_p_same = mean(avg_p_same),
              med_p_same = mean(med_p_same),
              n_children_core = mean(n_children_core)#,
              # adults = mean(treatable_adults),
              # n_reproductive = mean(n_reproductive),
              # n_cows_1_year_plus = mean(n_cows_1_year_plus),
              # n_cows_babies = mean(n_cows_babies),
              # n_pigs_6_weeks_plus = mean(n_pigs_6_weeks_plus),
              # n_pigs_babies = mean(n_pigs_babies)
              )
  
  
  ggplot(data = x,
         aes(x = p_same,
             group = assignment)) +
    geom_density(aes(fill = assignment), alpha = 0.6, size = 0.3) +
    facet_grid(iter_n_children~iter_buffer_distance, scales = 'free_y') +
    labs(x = 'Percent of identical status within 1000 meter radius') +
    theme(legend.position = 'bottom') +
    scale_fill_manual(name = 'Assignment group',
                      values = cols) +
    theme(axis.text = element_text(size = 6),
          strip.text = element_text(size = 8)) +
    labs(y = 'Density') +
    geom_point(data = agg,
               aes(x = avg_p_same,
                   y = 0.04,
                   color = assignment),
               pch = 'I') +
    geom_text(data = agg,
              aes(x = avg_p_same,
                  y = 0.035,
                  color = assignment,
                  label = round(avg_p_same)),
              size = 3) +
    scale_color_manual(name = 'Assignment group',
                       values = cols)
  # ggsave('~/Desktop/radius_distributions.png', width= 9, height = 7)
  # Join the data here with some of the assignment-group level data from the previous section
  # Join some data here with previous section at assignment level
  right <- carlos_table
  right <- right %>%
    mutate(iter_buffer_distance = paste0('Buffer: ', iter_buffer_distance)) %>%
    mutate(iter_n_children = paste0( bohemia::add_zero(iter_n_children, 2), ' kids')) %>%
    mutate(assignment = factor(assignment)) %>%
    dplyr::select(-n_children_core)
  out <- left_join(agg, right)
  write_csv(out, 'carlos_combined.csv')
  
  
  write_csv(agg, 'carlos2.csv')
  
  ggplot(data = agg,
         aes(x = assignment,
             y = avg_p_same,
             fill = assignment)) +
    facet_grid(iter_n_children~iter_buffer_distance) +
    geom_bar(stat = 'identity') +
    labs(x = 'Percent of identical status within 1000 meter radius') +
    theme(axis.text = element_text(size = 6),
          strip.text = element_text(size = 8)) +
    labs(y = '%') +
    geom_text(data = agg,
              aes(x = assignment,
                  y = avg_p_same,
                  label = round(avg_p_same)),
              size = 3,
              nudge_y = -20,
              color = 'white') +
    scale_fill_manual(name = 'Assignment group',
                       values = cols) +
    theme(legend.position = 'none')

  ggsave('~/Desktop/radius_distributions2.png', width= 9, height = 12)


  # Plot of percent contamination
  pd <- x %>%
    group_by(assignment,
             iter_n_children,
             iter_buffer_distance) %>%
    summarise(hh = n(),
              med_p_same = median(p_same, na.rm = TRUE),
              avg_p_same = mean(p_same, na.rm = TRUE))
  # cols <- RColorBrewer::brewer.pal(n = length(unique(pd$iter_n_children)), 'Spectral')
  cols <- colorRampPalette(RColorBrewer::brewer.pal(n = 9, 'Spectral'))(length(unique(pd$iter_n_children)))

  # cols[3:4] <- c('black', 'grey')
  ggplot(data = pd,
         aes(x = iter_buffer_distance,
             y = med_p_same)) +
    geom_point(aes(#pch = valid,
      color = factor(iter_n_children)),
      size = 2,
      alpha = 0.5) +
    facet_wrap(~paste0('Assignment\ngroup ', assignment)) +
    theme(legend.position = 'bottom') +
    geom_line(aes(color = factor(iter_n_children),
                  group = factor(iter_n_children)),
              size = 1.4,
              alpha = 0.9) +
    scale_color_manual(name = 'Number of\nchildren in core',
                       values = cols) + #  rainbow(length(unique(pd$iter_n_children)))) +
    labs(x = 'Minimum buffer distance (meters)',
         y = 'MEDIAN % with identical assignment\nstatus within 1 km radius',
         title = 'Cluster formation strategies comparison')
  ggsave('~/Desktop/radius_median.png', height = 8, width = 12)
  
  # cols[3:4] <- c('black', 'grey')
  ggplot(data = pd,
         aes(x = iter_buffer_distance,
             y = avg_p_same)) +
    geom_point(aes(#pch = valid,
      color = factor(iter_n_children)),
      size = 2,
      alpha = 0.5) +
    facet_wrap(~paste0('Assignment\ngroup ', assignment)) +
    theme(legend.position = 'bottom') +
    geom_line(aes(color = factor(iter_n_children),
                  group = factor(iter_n_children)),
              size = 1.4,
              alpha = 0.9) +
    scale_color_manual(name = 'Number of\nchildren in core',
                       values = cols) + #  rainbow(length(unique(pd$iter_n_children)))) +
    labs(x = 'Minimum buffer distance (meters)',
         y = 'MEAN % with identical assignment\nstatus within 1 km radius',
         title = 'Cluster formation strategies comparison')
  ggsave('~/Desktop/radius_mean.png', height = 8, width = 12)

  # Plot of nearest contaminant
  pd <- all_pts@data %>%
    group_by(assignment,
             iter_n_children,
             iter_buffer_distance) %>%
    summarise(hh = n(),
              avg_distance_to_nearest_contaminant = mean(nearest_contaminant, na.rm = TRUE),
              p25 = quantile(nearest_contaminant, 0.25, na.rm = TRUE),
              p75 = quantile(nearest_contaminant, 0.75, na.rm = TRUE),
              mn = median(nearest_contaminant, na.rm = TRUE),
              p95 = quantile(nearest_contaminant, 0.95, na.rm = TRUE),
              p05 = quantile(nearest_contaminant, 0.05, na.rm = TRUE))

  cols <- RColorBrewer::brewer.pal(n = length(unique(pd$iter_n_children)), 'Spectral')
  cols[3:4] <- c('black', 'grey')
  ggplot(data = pd,
         aes(x = iter_buffer_distance,
             y = avg_distance_to_nearest_contaminant)) +
    geom_point(aes(#pch = valid,
      color = factor(iter_n_children)),
      size = 2,
      alpha = 0.5) +
    facet_wrap(~paste0('Assignment\ngroup ', assignment)) +
    theme(legend.position = 'bottom') +
    geom_line(aes(color = factor(iter_n_children),
                  group = factor(iter_n_children)),
              size = 1.4,
              alpha = 0.9) +
    scale_color_manual(name = 'Number of\nchildren in core',
                       values = cols) + #  rainbow(length(unique(pd$iter_n_children)))) +
    labs(x = 'Minimum buffer distance (meters)',
         title = 'Cluster formation strategies comparison') +
    geom_hline(yintercept = seq(0, 2500, 250), lty = 2, alpha = 0.6) +
    scale_y_continuous(name = 'Average meters to nearest contaminant\namong "core" households',
                       breaks = seq(0, 2500, 250))
  ggsave('~/Desktop/distance.png', height = 8, width = 12)
  
} 

extra <- read_sims
# Calculate radius differences at the sweet spot
if(extra){
  # Get a 1 km border around each household
  radius_distances <- seq(200, 1000, by = 200)
  full_list <- list()
  for(i in 1:length(radius_distances)){
    this_distance <- radius_distances[i]
    message(this_distance)
    radius <- gBuffer(households_projected, byid = T, width = this_distance)
    over_radius <- over(x = households_projected, y = polygons(radius), returnList = T)
    radius_list <- list()
    for(j in 1:length(over_radius)){
      out <- tibble(this_id = households_projected@data$id[j],
                    id = households_projected@data$id[unlist(over_radius[[j]])]) %>%
        mutate(radius_distance = this_distance)
      radius_list[[j]] <- out
    }
    radius_df <- bind_rows(radius_list)
    full_list[[i]] <- radius_df
  }
  radius_df <- bind_rows(full_list)
  
  # Not doing everything here
  iters_buffer_distance <- 600# sort(unique(master_pts@data$iter_buffer_distance))
  iters_n_children <- 15#sort(unique(master_pts@data$iter_n_children))
  contaminant_list <- list()
  counter <- 0
  iters <- length(iters_buffer_distance) * length(iters_n_children)
  for(radius_distance in radius_distances){
    for(buffer_distance in iters_buffer_distance){
      for(n_children in iters_n_children){
        counter <- counter + 1
        message(counter, ' of ', iters, '. Buffer: ', buffer_distance, '. Children: ', n_children)
        # Get the points
        these_buf <- master_buf[master_buf@data$iter_buffer_distance == buffer_distance & master_buf@data$iter_n_children == n_children,]
        these_pts <- master_pts[master_pts@data$iter_buffer_distance == buffer_distance & master_pts@data$iter_n_children == n_children,]
        
        # Keep only those in the core
        core <- these_pts[these_pts@data$status == 'core',]
        buff <- these_pts[!is.na(these_pts@data$status),]
        
        # Assign temporary assignations for the purpose of estimating
        # distances to contaminants
        assignment_df <- tibble(
          cluster = sort(unique(core@data$cluster))
        )
        a <- rep(1:3, each = ceiling(nrow(assignment_df)/3))
        a <- sample(a, size = length(a), replace = F)
        assignment_df$assignment <- a[1:nrow(assignment_df)]
        buff@data <- left_join(buff@data, assignment_df)
        # Bring the assignment into ALL points, since that is how contamination is determined
        all_pts <- households_projected
        all_pts@data <- left_join(all_pts@data, buff@data %>% ungroup %>% dplyr::select(assignment, id),
                                  by = 'id')
        
        # Assuming that non-cluster areas are group 1
        all_pts@data$assignment <- ifelse(is.na(all_pts@data$assignment), 1, all_pts@data$assignment)
        
        # Get the assignments into the radius data
        # (this will contain one row for each assignment in the 1 km area)
        rd <- radius_distance
        sub_radius <- radius_df %>%
          filter(radius_distance == rd) %>%
          left_join(all_pts@data %>% ungroup %>% dplyr::select(id, assignment)) %>%
          dplyr::select(-id) %>%
          dplyr::rename(id = this_id) %>%
          # now grouping by id to get each type
          group_by(id, assignment) %>%
          summarise(n_assig = n()) %>%
          ungroup %>% 
          # get the assignment for the person in question
          left_join(all_pts@data %>% ungroup %>% dplyr::select(id, self_assignment = assignment)) %>%
          mutate(is_same = assignment == self_assignment) %>%
          group_by(id) %>%
          summarise(n_same = sum(n_assig[is_same]),
                    n_diff = sum(n_assig[!is_same]),
                    n_1k = sum(n_assig)) %>%
          ungroup %>%
          mutate(p_same = n_same / n_1k * 100,
                 n_diff = n_diff / n_1k * 100)
        all_pts@data <- left_join(all_pts@data,
                                  sub_radius)
        
        
        # Get number of people within a radius of identical assignment status
        all_pts@data$nearest_contaminant <- NA
        
        # # Get distance to contaminant
        # for(i in 1:3){
        #   message('...group ', i, ' of 3')
        #   g1 <- sub_gd[which(all_pts@data$assignment == i),
        #                which(all_pts@data$assignment != i)]
        #   g2 <- apply(g1, 1, function(x){min(x, na.rm = TRUE)})
        #   all_pts@data$nearest_contaminant[all_pts@data$assignment == i] <- g2
        # }
        # Subset to only include those in the study core
        keep <- all_pts[all_pts@data$id %in% core@data$id,]
        keep@data$iter_n_children <- n_children
        keep@data$iter_buffer_distance <- buffer_distance
        keep@data$radius_distance <- radius_distance
        # flag <- length(which(is.na(keep@data$nearest_contaminant)))
        # if(flag > 0){
        #   message('PROBLEM!!!')
        # }
        contaminant_list[[counter]] <- keep
      }
    }
  }

  radius_pts <- do.call('rbind', contaminant_list)
  
  pd <- radius_pts@data
  
  x <- pd %>%
    mutate(iter_buffer_distance = paste0('Buffer: ', iter_buffer_distance)) %>%
    mutate(iter_n_children = paste0( bohemia::add_zero(iter_n_children, 2), ' kids')) %>%
    mutate(assignment = factor(assignment))
  agg <- x %>%
    group_by(iter_buffer_distance, iter_n_children, assignment, radius_distance) %>%
    summarise(hh = n(),
              avg_p_same = mean(p_same, na.rm = TRUE),
              med_p_same = median(p_same, na.rm = TRUE),
              n_children_core = sum(n_children)
    ) %>%
    ungroup 
  
  ggplot(data = agg,
         aes(x = radius_distance,
             y = avg_p_same,
             color = assignment,
             group = assignment)) +
    facet_grid(iter_n_children~iter_buffer_distance) +
    geom_line(size = 3, alpha = 0.8) +
    labs(x = 'Size of radius for measuring percent contamination',
         y = 'Percent of adults in radius with identical assignment status',
         title = 'Different measurements of contamination at "sweet spot"') +
    theme(axis.text = element_text(size = 6),
          strip.text = element_text(size = 8)) +
    theme(legend.position = 'bottom')
  
  ggsave('~/Desktop/sweet_spot_radii.png', width= 10, height = 9)
  
}
