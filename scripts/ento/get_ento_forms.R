# devtools::install_github("validmeasures/odkr")
library(odkr)
library(readr)
library(aws.s3)
library(dplyr)

# Define the country
country <- 'Mozambique'
iso <- tolower(substr(country, 1, 3))

# Configure AWS bucket info
# Read in credentials for S3 bucket
s3creds <- read_csv('../../credentials/bohemiacensuss3credentials.csv')

# Set environment variables for AWS s3
Sys.setenv(
  "AWS_ACCESS_KEY_ID" = s3creds$`Access key ID`,
  "AWS_SECRET_ACCESS_KEY" = s3creds$`Secret access key`,
  "AWS_DEFAULT_REGION" = "eu-west-3"
)

# Read in credentials for ODK Aggregate server
odk_collect_creds <- yaml::yaml.load_file('../../credentials/credentials.yaml')

# Define locations
briefcase_dir <- '/home/joebrew/Documents/briefcase'
jar_file_briefcase <- 'ODK-Briefcase-v1.18.0'

# Check the directory
this_dir <- getwd()
split_dir <- unlist(strsplit(this_dir, split = '/'))
check <- split_dir[length(split_dir)] == 'ento' & split_dir[length(split_dir) - 1] == 'scripts' & split_dir[length(split_dir) - 2] == 'bohemia' 
if(!check){
  message('YOU ARE IN THE WRONG DIRECTORY. MAKE SURE YOU ARE IN bohemia/scripts/ento')
}

# Make a temporary directory
temp_dir <- tempdir()

# Retrieve the data
pull_remote(target = paste0(briefcase_dir),
            briefcase = jar_file_briefcase,
            id = "entoa3",
            to = temp_dir,
            from = odk_collect_creds$databrew_odk_server,
            username = odk_collect_creds$databrew_odk_user,
            password = odk_collect_creds$databrew_odk_pass)

# Export the data as csv
export_data(target = briefcase_dir,
            briefcase = jar_file_briefcase,
            id = "entoa3",
            from = temp_dir,
            to = temp_dir,
            filename = "entoa3done.csv")

# Capture the names of all the entoa3 files
entoa3_files <- dir(temp_dir)
entoa3_files <- entoa3_files[grepl('entoa3', entoa3_files)]
entoa3_list <- list()
for(i in 1:length(entoa3_files)){
  entoa3_list[[i]] <- read_csv(file.path(temp_dir, entoa3_files[i]))
}
names(entoa3_list) <- gsub('.csv', '', entoa3_files, fixed = TRUE)
entoa3 <- entoa3_list

# # Read in the csv
# entoa3 <- read_csv(file.path(temp_dir, 'entoa3done.csv'))


# Put the objects into S3

file_name <- paste0('entoa3_', country, '_',
                    as.character(as.character(Sys.time())),
                    '.RData')
full_path <- file.path(temp_dir, file_name)
save(entoa3, file = full_path)
put_object(
  file = full_path,
  object = file_name,
  bucket = "bohemiaento"
)

############################################################
# To read most recent forms
read_recent <- FALSE
if(read_recent){
  buck <- get_bucket(bucket = 'bohemiaento')
  
  # Retrieve objects from s3
  buck_names <- buck_times <-  c()
  for(i in 1:length(buck)){
    buck_names[i] <- buck[i]$Contents$Key
    buck_times[i] <- buck[i]$Contents$LastModified
  }
  buck_df <- tibble(file = buck_names,
                    date_time = buck_times) %>%
    # keep only entoa3
    filter(grepl('entoa3', file))
  buck_df_keep <- buck_df %>%
    arrange(desc(date_time)) %>%
    filter(grepl(country, file)) %>%
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