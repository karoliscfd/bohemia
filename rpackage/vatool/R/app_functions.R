library(shiny)
library(dplyr)

# load VA data (for now, this is fake)
load_va_data <- function(){
  out <-
    tibble(death_id = c('ABC-123-702', 'QRS-567-703', 'XYZ-987-701'),
           age_in_years = sample(1:100, 3),
           date_of_death = random_date(),
           date_of_birth = random_date(),
           date_of_interview = random_date(50),
           fever = sample(c('Yes', 'No'), size = 3, replace = TRUE),
           fever_days = sample(1:10, size = 3, replace = TRUE),
           HIV = sample(c('Yes', 'No'), size = 3, replace = TRUE),
           malaria_test = sample(c('Yes', 'No'), size = 3, replace = TRUE),
           malaria_positive = sample(c('Yes', 'No'), size = 3, replace = TRUE),
           TB = sample(c('Yes', 'No'), size = 3, replace = TRUE),
           phone_number = rep(12345, 3))
  return(out)
}


# Random date function
random_date <- function(n = 10000){
  sample(Sys.Date() - n: 
             Sys.Date(),
         1)
}

# Function for generating the about page
make_about <- function(){
  fluidPage(
    fluidRow(
      div(img(src='www/logo.png', align = "center"), style="text-align: center;"),
      h4('Built in partnership with ',
         a(href = 'http://databrew.cc',
           target='_blank', 'Databrew'),
         align = 'center'),
      p('Empowering research and analysis through collaborative data science.', align = 'center'),
      div(a(actionButton(inputId = "email", label = "info@databrew.cc", 
                         icon = icon("envelope", lib = "font-awesome")),
            href="mailto:info@databrew.cc",
            align = 'center')), 
      style = 'text-align:center;'
    )
  )
}

# Plot theme
theme_va <- ggplot2::theme_bw

# Get database connection
get_db_connection <- function(local = FALSE){
  creds <- yaml::yaml.load_file('credentials/credentials.yaml')
  users <- yaml::yaml.load_file('credentials/users.yaml')
  drv <- RPostgres::Postgres()
  
  if(local){
    con <- dbConnect(drv, dbname = 'va')
  } else {
    psql_end_point = creds$endpoint
    psql_user = creds$psql_master_username
    psql_pass = creds$psql_master_password
    con <- dbConnect(drv, dbname='va', host=psql_end_point, 
                     port=5432,
                     user=psql_user, password=psql_pass)
  }

  return(con)
}
