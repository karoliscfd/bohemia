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
    navbarPage('Bohemia entomology data management tool',
               tabPanel('A4',
                        fluidPage(
                          column(6,
                                 DT::dataTableOutput('main_table')),
                          column(6,
                                 textOutput('selected_text'))
                        )))
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
  message('Working directory is: ', getwd())
  
  message('Defining function for fake data')
  make_fake <- function(n = 10){
    out <- tibble(qr = 1:n,
                  date = Sys.Date(),
                  species = 'culex erraticus')
    return(out)
  }
  
  # Load in the data from s3
  retrieve_ento_data(s3creds_path = 'credentials/bohemiacensuss3credentials.csv',
                     country = 'Mozambique')
  # There is now an object in memory named "entoa3"
  # There is now an object in memory named "entoa4" (if some data has already been saved there)
  if(exists('entoa3')){
    message('---the entoa3 object has ', nrow(entoa3), ' rows')
  } else {
    message('---there is no object named entoa3!')
  }
  if(exists('entoa4')){
    message('---the entoa4 object has ', nrow(entoa4), ' rows')
  }  else {
    message('---there is no object named entoa4!')
  }
  # Define a function for whittling down the data from entoa3 to only that which matters
  trim_down_a3 <- function(entoa3){
    out <- entoa3[,c('', names(entoa3)[grepl('dissect', names(entoa3))])]
  }
  
  data_list <- reactiveValues(main = make_fake(),
                              sub = data.frame())

  output$main_table <- DT::renderDataTable({
    pd <- data_list$main
    DT::datatable(pd,
                  selection = list(mode = 'single', selected = c(1)))
  })  
  
  observeEvent(input$main_table_rows_selected, {
    # capture the selected row
    rs <- input$main_table_rows_selected
    message('---The selected row is: ', rs)
    # Subset the data
    ok <- FALSE
    if(!is.null(rs)){
      if(length(rs) == 1){
        ok <- TRUE
      }
    }
    if(ok){
      pd <- data_list$main
      sub_data <- pd[rs,]
      data_list$sub <- sub_data
    } else {
      data_list$sub <- data.frame()
    }
  })

  output$selected_text <- renderText({
    # Get the selected row
    dls <- data_list$sub
    if(nrow(dls) == 1){
      out <- paste0(dls$qr, ' ', dls$species)
    } else {
      out <- 'Select an entry by clicking on the table.'
    }
  })
}

app <- function(){
  # Detect the system. If on AWS, don't launch browswer
  is_aws <- grepl('aws', tolower(Sys.info()['release']))
  shinyApp(ui = app_ui,
           server = app_server,
           options = list('launch.browswer' = !is_aws))
}
