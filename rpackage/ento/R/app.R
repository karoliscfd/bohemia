#' The application User-Interface
#' 
#' @param request Internal parameter for `{shiny}`. 
#'     DO NOT REMOVE.
#' @import shiny
#' @import shinydashboard
#' @import ggplot2
#' @import DT
#' @import dplyr
#' @import readr
#' @import RPostgres
#' @import DBI
#' @import shinyjs
#' @noRd


temp_dir <- tempdir()# getwd()
if(!dir.exists(temp_dir)){
  dir.create(temp_dir)
}

app_ui <- function(request) {
  tagList(
    # Leave this function for adding external resources
    golem_add_external_resources(),
    # Your application UI logic 
    fluidPage(
      h1("ento")
    )
  )
}

#' Add external Resources to the Application
#' 
#' This function is internally used to add external 
#' resources inside the Shiny application. 
#' 
#' @import shiny
#' @importFrom golem add_resource_path activate_js favicon bundle_resources
#' @noRd
golem_add_external_resources <- function(){
  
  add_resource_path(
    'www', app_sys('app/www')
  )
  
  tags$head(
    favicon(),
    bundle_resources(
      path = app_sys('app/www'),
      app_title = 'ento'
    )
    # Add here other external resources
    # for example, you can add shinyalert::useShinyalert() 
  )
}



##################################################
# SERVER
##################################################
#' @import shiny
#' @import leaflet
app_server <- function(input, output, session) {

  message('Server code running')
  
}

app <- function(){
  # Detect the system. If on AWS, don't launch browswer
  is_aws <- grepl('aws', tolower(Sys.info()['release']))
  shinyApp(ui = app_ui,
           server = app_server,
           options = list('launch.browswer' = !is_aws))
}
