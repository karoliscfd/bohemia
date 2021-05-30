#' Visit control sheet list generation
#' 
#' Render a visit control sheet
#' @param census_data A dataframe in the format of the minicensus (household level)
#' @param census_people A dataframe in the format of the minicensus people table
#' @param census_subs A dataframe in the format of the
#' @param keyfile The path to the private key
#' @param keyfile_public The path to the public key
#' @param location A three letter location code (or character vector of multiple codes). If NULL, all locations to be used
#' @param output_file The name of the spreadsheet to be written (csv file); if null, will return the table in memory
#' @param fake_data Whether to use fake data or not
#' @param html Whether to return a print-ready html table (intead of the default csv)
#' @import dplyr
#' @import PKI
#' @import readr
#' @import rmarkdown
#' @return A table will be created
#' @export

list_generation_visit_control <- function(census_data,
                                          census_people,
                                          census_subs,
                                          keyfile = NULL,
                                          keyfile_public = NULL,
                                          location = NULL,
                                          output_file = NULL,
                                          fake_data = FALSE,
                                          html = FALSE){
  
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
  if(!is.null(location)){
    locs <- locs %>% filter(code %in% location)
  }
  if(nrow(locs) < 1){
    stop('No data found for the specified locations.')
  }
  
  if(fake_data){
    ################################# Create dummy data #########################################
    # Encrypt the names
    the_names <- c('John Doe', 'Jane Doe', 'Tarzan Jungle', 'Bob Smith', 'Alice Wonderland')
    the_names_encrypted <- encrypt_private_data(data = the_names, keyfile = keyfile_public)
    # Decrypt the names
    the_names <- decrypt_private_data(data = the_names_encrypted, keyfile = keyfile)
    
    # Create some household IDs for the geographies in question
    indices <- sample(1:nrow(locs), length(the_names), replace = TRUE)
    codes <- locs$code[indices]
    hhids <- paste0(codes, '-', sample(c('123','234', '345', '456'), length(the_names), replace = TRUE))  
    df <- locs[indices,] %>% dplyr::select(District, Ward, Village, Hamlet)
    df$hhid <- hhids
    df$hh_head_name <- sample(the_names, nrow(df), replace = TRUE)
    df$hh_sub_name <- sample(the_names, nrow(df), replace = TRUE)  
    get_contact <- function(){ paste0(sample(0:9, 8, replace = T), collapse = '')}
    make_contact <- function(n){out <- c(); for(i in 1:n){out[i] <- get_contact()};return(out)}
    df$contact_information <- make_contact(n = nrow(df))
    df$previous_attempts <- 0
    df <- df %>% arrange(hhid) %>%
      dplyr::select(hhid, hh_head_name, hh_sub_name,
                    District, Ward, Village, Hamlet, contact_information, previous_attempts)
    
  } else {
    
    df <- census_data %>%
      dplyr::rename(hhid = hh_id) %>%
      arrange(hhid) %>%
      mutate(previous_attempts = 0) %>% # placeholder
      dplyr::select(hhid,
                    District = hh_district, 
                    Ward = hh_ward, 
                    Village = hh_village, 
                    Hamlet = hh_hamlet, 
                    contact_information = hh_contact_info_number,
                    previous_attempts,
                    instance_id)
    
    # Retrieve the household head and sub names
    hhh <- census_data %>%
      mutate(hh_head_id = as.numeric(as.character(hh_head_id))) %>%
      dplyr::select(hh_head_id,
                    instance_id) %>%
      left_join(census_people %>%
                  mutate(num = as.numeric(as.character(num))) %>%
                  dplyr::select(instance_id, hh_head_id = num,
                                first_name,
                                last_name,
                                pid)) %>%
      mutate(hh_head_name = paste0(first_name, ' ', last_name, ' ', pid)) %>%
      dplyr::select(instance_id, hh_head_name)
    
    hhs <- census_subs %>%
      mutate(hh_sub_id = as.numeric(as.character(hh_sub_id))) %>%
      filter(!is.na(hh_sub_id)) %>%
      dplyr::select(hh_sub_id,
                    instance_id) %>%
      left_join(census_people %>%
                  mutate(num = as.numeric(as.character(num))) %>%
                  dplyr::select(instance_id, hh_sub_id = num,
                                first_name,
                                last_name,
                                pid)) %>%
      mutate(hh_sub_name = paste0(first_name, ' ', last_name, ' ', pid)) %>%
      dplyr::select(instance_id, hh_sub_name) %>%
      group_by(instance_id) %>%
      summarise(hh_sub_name = paste0(hh_sub_name, collapse = '; '))
    
    # Join hh head and subs to main table
    df <- left_join(df, hhh) %>%
      left_join(hhs) %>%
      arrange(hhid) %>%
      dplyr::select(hhid, hh_head_name, hh_sub_name,
                    District, Ward, Village, Hamlet, contact_information, previous_attempts)
  }
  
  if(html){
    names(df) <- toupper(names(df))
    bohemia::prettify(df, nrows = nrow(df), download_options = TRUE)
  } else if(!is.null(output_file)){
    message('Writing a csv to ', output_file)
    write_csv(df, output_file)
  } else {
    return(df)
  }
}
