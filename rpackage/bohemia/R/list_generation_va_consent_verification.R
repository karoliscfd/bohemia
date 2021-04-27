#' VA Consent Verification list generation
#' 
#' Render a VA consent verification list
#' @param keyfile The path to the private key
#' @param keyfile_public The path to the public key
#' @param location A three letter location code (or character vector of multiple codes). If NULL, all locations to be used
#' @param output_file The name of the spreadsheet to be written (csv file); if null, will return the table in memory
#' @import dplyr
#' @import PKI
#' @import readr
#' @return A table will be created
#' @export

list_generation_va_consent_verification <- function(keyfile = NULL,
                                          keyfile_public = NULL,
                                          location = NULL,
                                          output_file = NULL){
  
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
  df$deceased_name <- sample(the_names, nrow(df), replace = TRUE)  
  df$verify_consent_existence <- df$verify_consent_filled <- df$note_errors <- df$verify_consent_corrected <- df$archivist_signature_and_date <- df$fwid_and_name <-  '        '
  
  
  if(!is.null(output_file)){
    message('Writing a csv to ', output_file)
    write_csv(df, output_file)
  } else {
    return(df)
  }
}