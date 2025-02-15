#' Load ODK data
#' 
#' Load odk data
#' @param the_country The country to be loaded
#' @param credentials_path The path to the credentials.yaml file 
#' @param users_path The path to the users.yaml file
#' @param local Whether to use the local database
#' @param efficient Whether to only load select columns
#' @param use_cached Whether to use a cached file
#' @param con A connection object
#' @import yaml
#' @import dplyr
#' @import DBI
#' @import RPostgres
#' @import lubridate
#' @export

load_odk_data <- function(the_country = 'Mozambique',
                          credentials_path = 'credentials/credentials.yaml',
                          users_path = 'credentials/users.yaml',
                          local = FALSE, 
                          efficient=TRUE,
                          use_cached = FALSE,
                          con = NULL){
  no_con <- is.null(con)
  message('Starting the load_odk_data function...')
  start_time <- Sys.time()
  
  cached_file_name <- paste0('/tmp/',
                             the_country, '_',
                             ifelse(efficient, 'efficient', 'inefficient'),
                             '_',
                             ifelse(local, 'local', 'remote'),
                             '.RData')
  
  # Decide whether to use cached or not
  get_new_data <- TRUE
  if(use_cached){
    cached_file_exists <- file.exists(cached_file_name)
    if(cached_file_exists){
      # See how old it is 
      file_info <- file.info(cached_file_name)
      creation_time <- file_info$ctime
      is_old <- (Sys.time() - lubridate::hours(12)) > creation_time
      if(!is_old){
        get_new_data <- FALSE
      }
    }
  } 
  
  # No file, need to ping database
  if(get_new_data){
    message('...Retrieving data from the database')
    if(no_con){
      creds <- yaml::yaml.load_file(credentials_path)
      users <- yaml::yaml.load_file(users_path)
      psql_end_point = creds$endpoint
      psql_user = creds$psql_master_username
      psql_pass = creds$psql_master_password
      drv <- RPostgres::Postgres()
      if(local){
        con <- dbConnect(drv, dbname='bohemia')
      } else {
        con <- dbConnect(drv, dbname='bohemia', host=psql_end_point, 
                         port=5432,
                         user=psql_user, password=psql_pass)
      } 
    }

    
    # Define server
    if(the_country == 'Mozambique'){
      server_url <- 'https://sap.manhica.net:4442/ODKAggregate'
    } else {
      server_url <- 'https://bohemia.ihi.or.tz'
    }
    
    # Read in data
    data <- list()
    if(!is.null(the_country)){
      # load smaller dataset
      if(efficient){
        main <- dbGetQuery(con, paste0("SELECT instance_id,wid, device_id, start_time,end_time,hh_head_id,hh_hamlet_code, hh_hamlet,hh_id, hh_size, hh_n_cows_less_than_1_year, hh_n_cows_greater_than_1_year, hh_n_pigs_less_than_6_weeks, hh_n_pigs_greater_than_6_weeks, n_nets_in_hh, hh_animals_distance_cattle_rainy_season_geo, hh_animals_distance_cattle_dry_season_geo, hh_animals_rainy_season_geo_pigs, hh_animals_dry_season_geo_pigs, todays_date, hh_country, hh_geo_location, hh_ward, hh_village, hh_district FROM clean_minicensus_main where server='", server_url, "'"))
      } else {
        main <- dbGetQuery(con, paste0("SELECT * FROM clean_minicensus_main where server='", server_url, "'"))
      }
      
    } else {
      if(efficient){
        # load smaller dataset
        main <- dbGetQuery(con, paste0("SELECT instance_id,wid, device_id, start_time,end_time,hh_head_id,hh_hamlet_code, hh_hamlet,hh_id, hh_size, hh_n_cows_less_than_1_year, hh_n_cows_greater_than_1_year, hh_n_pigs_less_than_6_weeks, hh_n_pigs_greater_than_6_weeks, n_nets_in_hh, hh_animals_distance_cattle_rainy_season_geo, hh_animals_distance_cattle_dry_season_geo, hh_animals_rainy_season_geo_pigs, hh_animals_dry_season_geo_pigs, todays_date, hh_country, hh_geo_location, hh_ward, hh_village, hh_district FROM clean_minicensus_main"))
      } else {
        main <- dbGetQuery(con, paste0("SELECT * FROM clean_minicensus_main"))
        
      }
    }
    data$minicensus_main <- main
    ok_ids <- main$instance_id
    ok <- TRUE
    if(length(ok_ids) == 0){
      ok_ids <- '86ff878c-1f45-11eb-adc1-0242ac120002' # fake
    }
    ok_uuids <- paste0("(",paste0("'",ok_ids,"'", collapse=","),")")
    
    repeat_names <- c("minicensus_people", 
                      "minicensus_repeat_death_info",
                      "minicensus_repeat_hh_sub", 
                      "minicensus_repeat_mosquito_net", 
                      "minicensus_repeat_water")
    
    if(efficient){
      for(i in 1:length(repeat_names)){
        this_name <- repeat_names[i]
        if(this_name =='minicensus_people'){
          
          this_data <- dbGetQuery(con, paste0("SELECT instance_id, dob, pid,initials, num,permid, first_name, last_name FROM clean_", this_name, " WHERE instance_id IN ", ok_uuids))
          
        } else  if(this_name == 'minicensus_repeat_death_info'){
          
          # Doing full data for deaths due to request from hansel and paul
          # this_data <- dbGetQuery(con, paste0("SELECT instance_id, death_id, death_dod, death_number, death_initials FROM clean_", this_name, " WHERE instance_id IN ", ok_uuids))
          this_data <- dbGetQuery(con, paste0("SELECT * FROM clean_", this_name, " WHERE instance_id IN ", ok_uuids))
          
        } else if(this_name =='minicensus_repeat_hh_sub'){
          this_data <- dbGetQuery(con, paste0("SELECT instance_id, hh_sub_id FROM clean_", this_name, " WHERE instance_id IN ", ok_uuids))
        } else if(this_name =='minicensus_repeat_mosquito_net'){
          this_data <- dbGetQuery(con, paste0("SELECT * FROM clean_", this_name, " WHERE instance_id IN ", ok_uuids))
        } else if(this_name == 'minicensus_repeat_water'){
          this_data <- dbGetQuery(con, paste0("SELECT * FROM clean_", this_name, " WHERE instance_id IN ", ok_uuids))
        }
        data[[this_name]] <- this_data
      }
    } else {
      for(i in 1:length(repeat_names)){
        this_name <- repeat_names[i]
        this_data <- dbGetQuery(con, paste0("SELECT * FROM clean_", this_name, " WHERE instance_id IN ", ok_uuids))
        data[[this_name]] <- this_data
      }
    }
    
    # Read in enumerations, va, and refusals data
    if(efficient){
      if(!is.null(the_country)){
        enumerations <- dbGetQuery(con, paste0("SELECT instance_id, agregado, village, ward, hamlet, hamlet_code,country, todays_date, chefe_name,localizacao_agregado, wid, start_time, end_time, location_gps FROM clean_enumerations where server='", server_url, "'"))
        #HERE do the same for va and refusals, and then anaomalies in the app. no need for corrections and fixes.
        va_refusals <- dbGetQuery(con, paste0("SELECT * FROM clean_va_refusals where server='", server_url, "'"))
        va <- dbGetQuery(con, paste0("SELECT instance_id, start_time, end_time, the_country,wid, todays_date, death_id, hh_id, gps_location, server FROM clean_va where server='", server_url, "'"))
        
        refusals <- dbGetQuery(con, paste0("SELECT instance_id, hh_geo_location,country,reason_no_participate, hamlet,district,region, hamlet_code, hh_id, hh_region, village, ward, todays_date, wid FROM clean_refusals where server='", server_url, "'"))
      } else {
        enumerations <- dbGetQuery(con, "SELECT instance_id, agregado, village, ward, hamlet, hamlet_code,country, todays_date, chefe_name,localizacao_agregado, wid, start_time, end_time, location_gps FROM clean_enumerations")
        va_refusals <- dbGetQuery(con, paste0("SELECT * FROM clean_va_refusals"))
        va <- dbGetQuery(con, "SELECT instance_id, start_time, end_time, the_country,wid, todays_date, death_id, hh_id,gps_location FROM clean_va")
        refusals <- dbGetQuery(con, "SELECT instance_id, hh_geo_location,country, reason_no_participate,hamlet,district,region, hamlet_code, hh_id, hh_region, village, ward, todays_date, wid FROM clean_refusals")
      }
    } else {
      if(!is.null(the_country)){
        enumerations <- dbGetQuery(con, paste0("SELECT * FROM clean_enumerations where server='", server_url, "'"))
        va <- dbGetQuery(con, paste0("SELECT * FROM clean_va where server='", server_url, "'"))
        va_refusals <- dbGetQuery(con, paste0("SELECT * FROM clean_va_refusals where server='", server_url, "'"))
        refusals <- dbGetQuery(con, paste0("SELECT * FROM clean_refusals where server='", server_url, "'"))
      } else {
        enumerations <- dbGetQuery(con, "SELECT * FROM clean_enumerations")
        va <- dbGetQuery(con, "SELECT * FROM clean_va")
        va_refusals <- dbGetQuery(con, "SELECT * FROM clean_va_refusals")
        refusals <- dbGetQuery(con, "SELECT * FROM clean_refusals")
      }
    }
    
    data$enumerations <- enumerations
    data$va <- va
    data$refusals <- refusals
    
    # Read in corrections data
    corrections <- dbGetQuery(con, "SELECT * FROM corrections")
    fixes <- dbGetQuery(con, "SELECT * FROM fixes")
    fixes_ad_hoc <- dbGetQuery(con, "SELECT * FROM fixes_ad_hoc")
    
    data$fixes <- fixes
    data$fixes_ad_hoc <- fixes_ad_hoc
    data$corrections <- corrections
    
    # Only disconnect if the connection was established in function
    if(no_con){
      dbDisconnect(con)
    }
    
    
    if(use_cached){
      # At this point there is something named data
      save(data, file = cached_file_name)
    }
    
  } else {
    message('...Loading a stored file')
    load(cached_file_name)
  }
  end_time <- Sys.time()
  message('..That took ', round(lubridate::time_length(end_time - start_time, unit = 'second'), 2), ' seconds.')
  return(data)
}