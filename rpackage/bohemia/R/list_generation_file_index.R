#' Visit control sheet file index list
#' 
#' Render a file index list
#' @param location A three letter location code (or character vector of multiple codes). If NULL, all locations to be used
#' @param output_file The name of the spreadsheet to be written (csv file); if null, will return the table in memory
#' @import dplyr
#' @import readr
#' @return A table will be created
#' @export

list_generation_file_index <- function(location = NULL,
                                          output_file = NULL){
  
  # # REMOVE THE BELOW
  # keyfile <- '../../../credentials/bohemia_priv.pem'
  # keyfile_public <- '../../../credentials/bohemia_pub.pem'
  # library(dplyr)
  # library(PKI)
  # library(bohemia)

  # Deal with location
  locs <- bohemia::locations
  if(!is.null(location)){
    locs <- locs %>% filter(code %in% location)
  }
  if(nrow(locs) < 1){
    stop('No data found for the specified locations.')
  }
  
  ################################# Create dummy data #########################################
 
  # Create some household IDs for the geographies in question
  the_names <- rep(NA, 50)
  indices <- sample(1:nrow(locs), length(the_names), replace = TRUE)
  codes <- locs$code[indices]
  hhids <- paste0(codes, '-', sample(c('123','234', '345', '456'), length(the_names), replace = TRUE))  
  df <- locs[indices,] %>% dplyr::select(District, Ward, Village, Hamlet)
  df$hhid <- hhids
  df <- df %>% arrange(hhid) 
  df$SN <- sample(1:10000000, length(the_names))
  df <- df %>% dplyr::select(SN,
                             hhid,
                             District, Ward, Village, Hamlet)
  
  if(!is.null(output_file)){
    message('Writing a csv to ', output_file)
    write_csv(df, output_file)
  } else {
    return(df)
  }
}