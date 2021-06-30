#' VA list generation
#' 
#' Render a VA list
#' @param death_data A dataframe in the format of the death data from the censu
#' @param keyfile The path to the private key
#' @param keyfile_public The path to the public key
#' @param location_code A three letter location code (or character vector of multiple codes). If NULL, all locations to be used
#' @param output_file The name of the spreadsheet to be written (csv file); if null, will return the table in memory
#' @param fake Whether or not to use fake data
#' @param data_list List of ODK-X data
#' @param agg_list List of ODK aggregate data
#' @import dplyr
#' @import PKI
#' @import readr
#' @return A table will be created
#' @export

list_generation_va <- function(death_data,
                               data_list,
                               agg_list,
                               keyfile = NULL,
                               keyfile_public = NULL,
                               location_code = NULL,
                               output_file = NULL,
                               fake = FALSE){
  
  # # REMOVE THE BELOW
  # keyfile <- '../../../credentials/bohemia_priv.pem'
  # keyfile_public <- '../../../credentials/bohemia_pub.pem'
  # library(dplyr)
  # library(PKI)
  # library(bohemia)
  
  # Deal with keyfile
  if(is.null(keyfile)){
    stop('You must specify the path to a private key (pem file) for decrypting names.')
  }
  if(is.null(keyfile_public)){
    stop('You must specify the path to a public key (pem file) for encrypting names.')
  }
  
  # Deal with location
  locs <- bohemia::locations
  if(!is.null(location_code)){
    locs <- locs %>% filter(code %in% location_code)
  }
  if(nrow(locs) < 1){
    stop('No data found for the specified locations.')
  }
  
  if(fake){
    # Encrypt the names
    the_names <- c('John Doe', 'Jane Doe', 'Tarzan Jungle', 'Bob Smith', 'Alice Wonderland')
    # the_names_encrypted <- encrypt_private_data(data = the_names, keyfile = keyfile_public)
    # # Decrypt the names
    # the_names <- decrypt_private_data(data = the_names_encrypted, keyfile = keyfile)
    # 
    # Create some household IDs for the geographies in question
    indices <- sample(1:nrow(locs), length(the_names), replace = TRUE)
    codes <- locs$code[indices]
    hhids <- paste0(codes, '-', sample(c('123','234', '345', '456'), length(the_names), replace = TRUE))  
    df <- locs[indices,] %>% dplyr::select(District, Ward, Village, Hamlet)
    df$hhid <- hhids
    df$hh_head_name <- sample(the_names, nrow(df), replace = TRUE)
    df$hh_sub_name <- sample(the_names, nrow(df), replace = TRUE) 
    df$fwid <- sample(1:600, nrow(df))
    df$deceased_id <- paste0(hhids, '-', 701)
    df$deceased_name <- sample(the_names, nrow(df), replace = TRUE)
    df$deceased_gender <- sample(c('M', 'F'), nrow(df), replace = TRUE)
    df$age_at_time_of_death <- rnorm(50, sd = 10, n = nrow(df))
    df$observations <- '      '
    get_contact <- function(){ paste0(sample(0:9, 8, replace = T), collapse = '')}
    make_contact <- function(n){out <- c(); for(i in 1:n){out[i] <- get_contact()};return(out)}
    df$contact_information <- make_contact(n = nrow(df))
    df$previous_attempts <- 0
    df <- df %>% arrange(hhid) 
  } else {
    # Using real data
    deaths <- death_data
    already_vas <- agg_list$va153census
    already_death_ids <- sort(unique(already_vas$`group_intro-death_id`))
    census <- data_list$census
      out <- 
        deaths %>%
          mutate(deceased_name = paste0(hh_death_name, ' ', hh_death_surname)) %>%
          dplyr::select(deceased_id = hh_death_id,
                        deceased_name,
                        deceased_gender = hh_death_gender,
                        age_at_time_of_death = hh_death_age) %>%
          mutate(code = substr(deceased_id, 1, 3)) %>%
          left_join(bohemia::locations %>% dplyr::select(District, Ward, Village, Hamlet, code)) %>%
          filter(!deceased_id %in% already_death_ids)
      df <- out
  }
  
  
  if(!is.null(output_file)){
    message('Writing a csv to ', output_file)
    write_csv(df, output_file)
  } else {
    return(df)
  }
}