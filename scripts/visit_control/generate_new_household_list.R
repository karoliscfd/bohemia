library(bohemia)
library(tidyverse)
library(gsheet)

# Define the country
country <- 'Mozambique'

# Define the locations
location_codes <- NULL # alternatively, supply a vector of locations, as below
# location_codes <- c('AMB', 'ZZE')

# Define the number of "extras" per hamlet
extra_n <- 50

# Define an output file
output_file <- '~/Desktop/new_household_list.csv'

message('Loading minicensus data')

# Read in minicensus data
file_name <- paste0(country, '_minicensus_data.RData')
if(file_name %in% dir()){
  load(file_name)
} else {
  minicensus_data <- load_odk_data(the_country = country,
                                   credentials_path = '../../credentials/credentials.yaml', # request from Databrew
                                   users_path = '../../credentials/users.yaml', # request from Databrew
                                   efficient = FALSE)
  save(minicensus_data,
       file = file_name)
}
codes <- sort(unique(minicensus_data$minicensus_main$hh_id))


# Get the "extra" margin
codes_df <- tibble(code = codes) %>%
  mutate(hamlet_code = substr(code, 1, 3)) %>%
  mutate(number = substr(code, 5,7)) %>%
  mutate(number = as.numeric(number)) %>%
  group_by(hamlet_code) %>%
  summarise(max_number = max(number, na.rm = TRUE))

hamlet_codes <- sort(unique(substr(codes, 1, 3)))
out_list <- list()
for(i in 1:nrow(codes_df)){
  this_code <- codes_df$hamlet_code[i]
  max_number <- codes_df$max_number[i]
  new_numbers <- (max_number + 1):(max_number + extra_n)
  new_numbers <- add_zero(new_numbers, 3)
  new_codes <- paste0(this_code, '-', new_numbers)
  out_df <- tibble(code = new_codes)
  out_list[[i]] <- out_df
}
new_codes_df <- bind_rows(out_list) %>%
  mutate(hamlet_code = substr(code, 1, 3))
if(!is.null(location_codes)){
  new_codes_df <- new_codes_df %>%
    filter(hamlet_code %in% location_codes)
}
new_codes_df$number <- 1:nrow(new_codes_df)
new_codes_df <- left_join(new_codes_df,
                          bohemia::locations %>%
                            dplyr::select(District, Ward, Village, Hamlet,
                                          hamlet_code = code))

new_codes_df <- new_codes_df %>%
  dplyr::select(number, District, Ward, Village, Hamlet,
                hamlet_code, code)
# Write to the output file
write_csv(new_codes_df,
          output_file)

# Also show table
bohemia::prettify(new_codes_df,
                  nrows = nrow(new_codes_df))
