#' helpers 
#'
#' @description A fct function
#'
#' @return The return value, if any, from executing the function.
#'
#' @noRd


#' Retrieve ento data
#' 
#' Retrieve entomology data from AWS s3
#' @param s3creds_path The path to a csv file with s3 credentials
#' @param country Mozambique or Tanzania
#' @return An object loaded into memory
#' @import aws.s3
#' @import dplyr
#' @export

retrieve_ento_data <- function(s3creds_path = '../../credentials/bohemiacensuss3credentials.csv',
                               country = 'Mozambique'){
  
  # Configure AWS bucket info
  # Read in credentials for S3 bucket
  s3creds <- read_csv(s3creds_path)
  
  # Set environment variables for AWS s3
  Sys.setenv(
    "AWS_ACCESS_KEY_ID" = s3creds$`Access key ID`,
    "AWS_SECRET_ACCESS_KEY" = s3creds$`Secret access key`,
    "AWS_DEFAULT_REGION" = "eu-west-3"
  )
  
  
  buck <- get_bucket(bucket = 'bohemiaento')
  
  # Retrieve objects from s3
  buck_names <- buck_times <-  c()
  for(i in 1:length(buck)){
    buck_names[i] <- buck[i]$Contents$Key
    buck_times[i] <- buck[i]$Contents$LastModified
  }
  buck_df <- tibble(file = buck_names,
                    date_time = buck_times) %>%
    # get a "type" column
    mutate(type = unlist(lapply(strsplit(file, '_'), function(x){x[1]})))
  buck_df_keep <- buck_df %>%
    arrange(desc(date_time)) %>%
    filter(grepl(country, file)) %>%
    group_by(type) %>%
    filter(date_time == dplyr::first(date_time))
  
  # Retrieve and save locally
  if(nrow(buck_df_keep) > 0){
    for(i in 1:nrow(buck_df_keep)){
      this_file <- buck_df_keep$file[i]
      this_object_name <- unlist(strsplit(this_file, '_'))[1]
      local_file <- paste0(this_object_name, '.RData')
      save_object(
        object = this_file,
        bucket = 'bohemiaento',
        file = local_file)
      load(local_file, envir = .GlobalEnv) # load to main namespace
      file.remove(local_file)
    }
  }
}
