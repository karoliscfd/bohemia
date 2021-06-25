# devtools::install_github("validmeasures/odkr")
library(odkr)
library(readr)

# Define the country
country <- 'Mozambique'
iso <- tolower(substr(country, 1, 3))

# Read in credentials for ODK Aggregate server
odk_collect_creds <- yaml::yaml.load_file('../../credentials/credentials.yaml')

# Define locations
briefcase_dir <- '/home/joebrew/Documents/briefcase'
jar_file_briefcase <- 'ODK-Briefcase-v1.18.0'

# Retrieve the data
pull_remote(target = paste0(briefcase_dir),
            briefcase = jar_file_briefcase,
            id = "entoa3",
            to = "~/Desktop",
            from = odk_collect_creds$databrew_odk_server,
            username = odk_collect_creds$databrew_odk_user,
            password = odk_collect_creds$databrew_odk_pass)

# Export the data as csv
export_data(target = briefcase_dir,
            briefcase = jar_file_briefcase,
            id = "entoa3",
            from = "~/Desktop",
            to = "~/Desktop",
            filename = "test.csv")

# Read in the csv
entoa3 <- read_csv('~/Desktop/test.csv')
