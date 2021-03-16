
##################################################
# UI
##################################################
#' @import shiny
#' @import shinydashboard
#' @import leaflet
#' @import shiny
#' @import ggplot2
#' @import gsheet
#' @import DT
#' @import shinyMobile
#' @import DBI
#' @import RPostgres
app_ui <- function(request) {
  options(scipen = '999')

  tagList(
    mobile_golem_add_external_resources(),

    dashboardPage(
      dashboardHeader (title = "Bohemia VA tool"),
      dashboardSidebar(
        sidebarMenu(
          menuItem(
            text="Main",
            tabName="main"),
          menuItem(
            text = 'About',
            tabName = 'about')
        )),
      dashboardBody(
        tags$head(
          tags$link(rel = "stylesheet", type = "text/css", href = "custom.css")
        ),
        tabItems(
          tabItem(
            tabName="main",
            fluidPage(
              uiOutput('top_button'),
              uiOutput('ui_main'),
              fluidRow(
                column(8,
                       uiOutput('ui_select_va')),
                column(4,
                       uiOutput('ui_assign_cod'))
              ),
              fluidRow(
                column(12,
                       DT::dataTableOutput('va_table'))
              )
            )
          ),
          tabItem(
            tabName = 'about',
            make_about()
          )
        )
      )
    )
  )
}



##################################################
# SERVER
##################################################
#' @import shiny
#' @import leaflet
app_server <- function(input, output, session) {
  is_local <- TRUE
  logged_in <- reactiveVal(value = FALSE)
  log_in_fail <- reactiveVal(value=FALSE)
  # Connect to database
  message('Connecting to database : ', ifelse(is_local, ' local', 'remote'))
  con <- get_db_connection(local = is_local)
  # Get list of authorized users
  users <- dbReadTable(conn = con, 'users')
  
  data <- reactiveValues(va = data.frame())
  
  # Upon log in, read in data
  observeEvent(input$log_in,{
    liu <- input$log_in_user
    lip <- input$log_in_password
    # See if the user exists and the password is correct
    # save(users, liu, lip, file = 'temp_data.RData')
    ok <- FALSE
    if(tolower(liu) %in% users$username & tolower(lip) %in% users$password){
      ok <-TRUE
    }
    if(ok){
      logged_in(TRUE)
      removeModal()
      data$va <- load_va_data()
    } else {
      logged_in(FALSE)
      log_in_fail(TRUE)
      removeModal()
    }
    
  })

  # Define the button
  output$top_button <- renderUI({
    li <- logged_in()
    if(li){
      actionButton("log_out", "Log out")
    } else {
      actionButton("show", "Log in")
    }
  })
  
  # Define the placeholder main ui
  output$ui_main <- renderUI({
    li <- logged_in()
    lif <- log_in_fail()
    if(li){
      fluidPage(h1('Logged in'))
    } else if (lif){
      fluidPage(h1('Username or password incorrect'))
    } else {
      fluidPage(h1('Not logged in'))
      
    }
  })
  
  # Selection input for VA ID
  output$ui_select_va <- renderUI({
    li <- logged_in()
    if(li){
      pd <- data$va
      choices <- pd$death_id
      selectInput('death_id', 'VA ID', choices = choices, selected = choices[1])
    } else {
      NULL
    }
  })
  
  output$ui_assign_cod <- renderUI({
    li <- logged_in()
    if(li){
      choices <- cod_choices()
      fluidPage(
        fluidRow(
          selectInput('cod', 'Cause of death', choices = choices, selected = choices[1])
        ),
        fluidRow(
          actionButton('submit_cod', 'Submit')
        )
      )
    } else {
      NULL
    }
  })
  
  output$va_table <- DT::renderDataTable({
    li <- logged_in()
    out <- NULL
    if(li){
      idi <- input$death_id
      if(!is.null(idi)){
        pd <- data$va
        person <- pd %>% filter(death_id == idi)
        person <- get_va_names(person)
        out <- 
          tibble(Variable = names(person),
                 Response = as.character(person[1,]))
      }
    } 
    out
  })

  observeEvent(input$show, {
    # logged_in(TRUE)
    showModal(modalDialog(
      title = "Log in",
      fluidPage(
        fluidRow(
          column(6,
                 textInput('log_in_user', 'User')),
          column(6,
                 passwordInput('log_in_password', 'Password'))
        ),
        fluidRow(
          actionButton('log_in', 'Log in')
        )
      )
    ))
  })
  observeEvent(input$log_out, {
    logged_in(FALSE)
  })
  
  # Observe submission of cause of death and save
  observeEvent(input$submit_cod, {
    message('COD submitted, need to do some stuff here...')
  })

  session$onSessionEnded(function(){
    cat(paste0('Session ended.'))
    if(exists('con')){
      dbDisconnect(con)
      cat(paste0('Disconnected from database.'))
    }
  })


}

#' Add external Resources to the Application
#'
#' This function is internally used to add external
#' resources inside the Shiny application.
#'
#' @import shiny
#' @importFrom golem add_resource_path activate_js favicon bundle_resources
#' @noRd
mobile_golem_add_external_resources <- function(){
  addResourcePath(
    'www', system.file('app/www', package = 'vatool')
  )


  share <- list(
    title = "Bohemia VA Tool",
    url = "https://bohemia.team/va/",
    image = "https://www.databrew.cc/images/logo_clear.png",
    description = "Bohemia app",
    twitter_user = "data_brew"
  )

  tags$head(
    tags$link(rel="stylesheet", type="text/css", href="www/custom.css")
  )
}

app <- function(){
  # Detect the system. If on AWS, don't launch browswer
  is_aws <- grepl('aws', tolower(Sys.info()['release']))
  shinyApp(ui = app_ui,
           server = app_server,
           options = list('launch.browswer' = !is_aws))
}
