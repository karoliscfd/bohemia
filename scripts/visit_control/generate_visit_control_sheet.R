# NOTE: this script is a temporary solution. The "permanent" visit control sheet generation
# method cannot be finalized until its dependencies (the census form) are finalized/locked.

# Define some parameters
suitcase_dir <- '/home/joebrew/Documents/suitcase'
jar_file <- 'ODK-X_Suitcase_v2.1.7.jar'
odkx_path <- '/home/joebrew/Documents/bohemia/odkx/app/config' # must be full path!
kf <- '../../credentials/bohemia_priv.pem' #path to private key for name decryption
creds <- yaml::yaml.load_file('../../credentials/credentials.yaml')
use_real_names <- TRUE # whether to decrypt names (TRUE) or use fakes ones (false)
is_linux <- Sys.info()['sysname'] == 'Linux'
keyfile = '../../../credentials/bohemia_priv.pem'
keyfile_public = '../../../credentials/bohemia_pub.pem'
output_file = '/home/joebrew/Desktop/visit_control_sheet.csv'
download_dir <- getwd()

# Check the directory
this_dir <- getwd()
split_dir <- unlist(strsplit(this_dir, split = '/'))
check <- split_dir[length(split_dir)] == 'visit_control' & split_dir[length(split_dir) - 1] == 'scripts' & split_dir[length(split_dir) - 2] == 'bohemia'
if(!check){
  message('YOU ARE IN THE WRONG DIRECTORY. MAKE SURE YOU ARE IN bohemia/scripts/visit_control')
}


library(dplyr)
library(tidyr)
library(stringr)
library(sp)
library(babynames)
library(bohemia)


# Define function for making fake names
fake_names <- function(n = 1, words = 2){
  vec <- babynames::babynames$name
  first_name <- sample(vec, size = n, replace = T)
  if(words == 1){
    out <- first_name
  } else {
    last_name <- sample(vec, size = n, replace = T)
    out <- paste0(first_name, ' ', last_name)
  }
  return(out)
}

## THE BELOW IS COMMENTED OUT INTENTIONALLY. EVENTUALLY, WE WILL MIGRATE TO THIS 
## METHOD (RETRIEVING DATA FROM ODK-X SERVER RATHER THAN MINICENSUS DATABASE)
## BUT NOT UNTIL SIZE / SYNC ISSUES ARE RESOLVED
## https://trello.com/c/vLynMQqa/149-change-visit-control-list-generation-to-use-odk-x-dataset-instead-of-minicensus-dataset
# # Retrieve data for the CENSUS main table(ODK-X method)
# odkx_retrieve_data(suitcase_dir = suitcase_dir,
#                    jar_file = jar_file,
#                    server_url = creds$odkx_server,
#                    table_id = 'census',
#                    user = creds$odkx_user,
#                    pass = creds$odkx_pass,
#                    is_linux = is_linux,
#                    download_dir = download_dir,
#                    attachments = FALSE)
# # Retrieve data for the household members table (ODK-X method)
# odkx_retrieve_data(suitcase_dir = suitcase_dir,
#                    jar_file = jar_file,
#                    server_url = creds$odkx_server,
#                    table_id = 'hh_member',
#                    user = creds$odkx_user,
#                    pass = creds$odkx_pass,
#                    is_linux = is_linux,
#                    download_dir = download_dir,
#                    attachments = FALSE)



message('Loading minicensus data')
# Define the country
country <- 'Mozambique'

# Read in minicensus data
if('minicensus_data.RData' %in% dir()){
  load('minicensus_data.RData')
} else {
  minicensus_data <- load_odk_data(the_country = country,
                          credentials_path = '../../credentials/credentials.yaml', # request from Databrew
                          users_path = '../../credentials/users.yaml', # request from Databrew
                          efficient = FALSE)
  save(minicensus_data,
       file = 'minicensus_data.RData')
}
out_list <- minicensus_data





# Decrypt names
if(use_real_names){
  out_list$enumerations$sub_name <- decrypt_private_data(out_list$enumerations$sub_name, keyfile = kf)
  out_list$enumerations$chefe_name <- decrypt_private_data(out_list$enumerations$chefe_name, keyfile = kf)
  out_list$minicensus_repeat_death_info$death_name <- decrypt_private_data(out_list$minicensus_repeat_death_info$death_name, keyfile = kf)
  out_list$minicensus_repeat_death_info$death_surname <- decrypt_private_data(out_list$minicensus_repeat_death_info$death_surname, keyfile = kf)
  out_list$minicensus_people$first_name <- decrypt_private_data(out_list$minicensus_people$first_name, keyfile = kf)
  out_list$minicensus_people$last_name <- decrypt_private_data(out_list$minicensus_people$last_name, keyfile = kf)
  out_list$va$id10007 <- decrypt_private_data(out_list$va$id10007, keyfile = kf)
  out_list$va$id10017 <- decrypt_private_data(out_list$va$id10017, keyfile = kf)
  out_list$va$id10018 <- decrypt_private_data(out_list$va$id10018, keyfile = kf)
  out_list$va$id10061 <- decrypt_private_data(out_list$va$id10061, keyfile = kf)
  out_list$va$id10062 <- decrypt_private_data(out_list$va$id10062, keyfile = kf)
} else {
  out_list$enumerations$sub_name <- fake_names(length(out_list$enumerations$sub_name))
  out_list$enumerations$chefe_name <- fake_names(length(out_list$enumerations$chefe_name))
  out_list$minicensus_repeat_death_info$death_name <- fake_names(length(out_list$minicensus_repeat_death_info$death_name), words = 1)
  out_list$minicensus_repeat_death_info$death_surname <- fake_names(length(out_list$minicensus_repeat_death_info$death_surname), words = 1)
  out_list$minicensus_people$first_name <- fake_names(length(out_list$minicensus_people$first_name), words = 1)
  out_list$minicensus_people$last_name <- fake_names(length(out_list$minicensus_people$last_name), words = 1)
  out_list$va$id10007 <- fake_names(length(out_list$va$id10007))
  out_list$va$id10017 <- fake_names(length(out_list$va$id10017))
  out_list$va$id10018 <- fake_names(length(out_list$va$id10018))
  out_list$va$id10061 <- fake_names(length(out_list$va$id10061))
  out_list$va$id10062 <- fake_names(length(out_list$va$id10062))
}


# Update names
for(i in 1:length(names(out_list))){
  this_name <- names(out_list)[i]
  if(grepl('minicensus_', this_name)){
    new_name <- gsub('minicensus_', 'clean_minicensus_', this_name)
    names(out_list)[i] <- new_name
  }
}

# Create objects required for visit control sheet
census_data <- out_list$clean_minicensus_main
census_people <- out_list$clean_minicensus_people
census_subs <- out_list$clean_minicensus_repeat_hh_sub


# Generate the visit control sheet
df <- list_generation_visit_control(census_data = census_data,
                              census_people = census_people,
                              census_subs = census_subs,
                              keyfile = keyfile,
                              keyfile_public = keyfile_public,
                              location = c('NOR', 'CHM', 'BBB'), # set to null in order to do all locations
                              output_file = output_file, # set to null in order to return a dataframe in memory
                              fake_data = FALSE,
                              html = FALSE) # set to TRUE if you want an html table ready for printing
