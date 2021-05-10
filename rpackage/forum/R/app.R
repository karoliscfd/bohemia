
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
#' @import dplyr
app_ui <- function(request) {
  options(scipen = '999')
  
  tagList(
    mobile_golem_add_external_resources(),
    
    dashboardPage(
      dashboardHeader (title = "Bohemia forum directory"),
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
        # tags$head(
        #   tags$link(rel = "stylesheet", type = "text/css", href = "custom.css")
        # ),
        tabItems(
          tabItem(
            tabName="main",
            fluidPage(
              fluidRow(
                column(3,
                       uiOutput('top_button'),
                       uiOutput('top_button_save'),
                       uiOutput('ui_selected_row'),
                       uiOutput('ui_add_row')),
                column(9, 
                       DT::dataTableOutput('contact_table'))
              )
            )
          ),
          tabItem(
            tabName = 'about',
            fluidPage(
              fluidRow(
                div(img(src='https://www.databrew.cc/images/logosmall.png', align = "center"), style="text-align: center;"),
                h4('Built in partnership with ',
                   a(href = 'https://databrew.cc',
                     target='_blank', 'Databrew'),
                   align = 'center'),
                p('Empowering research and analysis through collaborative data science.', align = 'center'),
                div(a(actionButton(inputId = "email_us", label = "info@databrew.cc",
                                   icon = icon("envelope", lib = "font-awesome")),
                      href="mailto:info@databrew.cc",
                      align = 'center')),
                style = 'text-align:center;'
              )
            )
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
  
  logged_in <- reactiveVal(value = FALSE)
  observeEvent(input$log_in,{
    
    email <- input$email
    password <- input$password
    message('email is: ', email)
    message('password is: ', password)
    if(email == 'admin' & password == 'admin'){
      logged_in(TRUE)
      removeModal()
    }
  })
  
  observeEvent(logged_in(), {
    li <- logged_in()
    if(li){
      message('LOGGED IN')
    } else {
      message('LOGGED OUT')
    }
  })
  
  output$top_button <- renderUI({
    li <- logged_in()
    if(li){
      actionButton("log_out", "Log out")
    } else {
      actionButton("show", "Log in")
    }
  })
  
  output$top_button_save <- renderUI({
    li <- logged_in()
    if(li){
      actionButton("save", "SAVE")
    } else {
      NULL
    }
  })
  
  output$ui_add_row <- renderUI({
    li <- logged_in()
    rs <- input$contact_table_rows_selected
    ok <- FALSE
    if(li){
      if(length(rs) == 0){
        ok <- TRUE
      }
    }
    if(ok){
      h2(actionButton("add_row", "Add entry"))
    } else {
      NULL
    }
  })
  
  output$ui_selected_row <- renderUI({
    rs <- input$contact_table_rows_selected
    message('SELECTED ROWS ARE: ')
    print(rs)
    ok <- FALSE
    li <- logged_in()
    if(li){
      if(!is.null(rs)){
        if(length(rs) > 0){
          ok <- TRUE
        }
      }
    }
    if(ok){
      pd <- x$df
      print('PD is ')
      print(pd)
      pd <- pd[rs,]
      save(pd, file = '/tmp/pd.RData')
      show_this <- paste0(pd$first_name, ' ',
             pd$last_name)
      show_this <- paste0(show_this, collapse = ', ')
      fluidPage(
        fluidRow(
          h3(ifelse(nrow(pd) == 1,
                    'Selected entry: ',
                    'Selected entries: ')),
          p(show_this),
          h2(actionButton("delete_row", "Delete entry"))
        )
      )
    } else {
      NULL
    }
  })
  
  observeEvent(input$delete_row,{
    rs <- input$contact_table_rows_selected
    message('Going to delete the following rows: ')
    print(rs)
    old_df <- x$df
    new_df <- old_df[!(1:nrow(old_df)) %in% rs,]
    x$df <- new_df
  })
  
  observeEvent(input$show, {
    # logged_in(TRUE)
    showModal(modalDialog(
      title = "Log in",
      fluidPage(
        fluidRow(
          column(6,
                 textInput('email', 'Email')),
          column(6,
                 passwordInput('password', 'Password'))
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
  
  # create a reactive dataframe to store data
  x = reactiveValues(df=NULL)
  observeEvent(logged_in(), {
    li <- logged_in()
    if(li){
      # User is logged in, get data
      if(!'df_forum.RData' %in% dir()){
        message('Getting data from google docs')
        df <- gsheet::gsheet2tbl('https://docs.google.com/spreadsheets/d/1qDxynnod4YZYzGP1G9562auOXzAq1nVn89EjeJYgL8k/edit#gid=0') 
        # removing details for now
        df$details <- NULL
        df <- df[, c("country", "first_name", "last_name", "institution", "position", "email", "phone")]
        save(df, file = 'df_forum.RData')
      } else {
        message('Loading up previously saved data')
        load('df_forum.RData')
      }
      x$df <- df
    }
  })
  
  
  # put data in table with options for saving a csv 
  output$contact_table <- DT::renderDataTable({
    li <- logged_in()
    if(li){
      DT::datatable(x$df, editable = 'cell',
                    extensions = 'Buttons', 
                    filter = 'top', 
                    options = list(pageLength = nrow(x$df), info = FALSE, dom='Bfrtip', buttons = list('csv')))
    }
  })
  
  # edit table
  observeEvent(input[["contact_table_cell_edit"]], {
    cellinfo <- input[["contact_table_cell_edit"]]
    x$df <- editData(x$df, input[["contact_table_cell_edit"]], "contact_table")
  })
  
  # Add a row
  observeEvent(input$add_row, {
    showModal(modalDialog(
      title = "Add entry",
      fluidPage(
        fluidRow(
          textInput('add_country', 'Country'),
          textInput('add_first_name', 'First name'),
          textInput('add_last_name', 'Last name'),
          textInput('add_institution', 'Institution'),
          textInput('add_position', 'Position'),
          textInput('add_email', 'Email'),
          textInput('add_phone', 'Phone')
        ),
        fluidRow(actionButton('confirm_add', 'Add entry!'))
      )
    ))
  })
  observeEvent(input$confirm_add, {
    pd <- tibble(country = input$add_country,
                 first_name = input$add_first_name,
                 last_name = input$add_last_name,
                 institution = input$add_institution,
                 position = input$add_position,
                 email = input$add_email,
                 phone = input$add_phone)
    old_df <- x$df
    new_df <- bind_rows(pd, old_df)
    x$df <- new_df
    removeModal()
  })
  
  # Save changes
  observeEvent(input$save, {
    message('Going to save data')
    df <- x$df
    save(df, file = 'df_forum.RData')
    # Save the history too
    st <- Sys.time()
    st <- as.numeric(st)
    save(df, file = paste0('df_forum_',
                           st, 
                           '.RData'))
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
    'www', system.file('app/www', package = 'forum')
  )
  
  
  share <- list(
    title = "Bohemia forum app",
    url = "https://bohemia.team/forum/",
    image = "https://www.databrew.cc/images/logo_clear.png",
    description = "Bohemia app",
    twitter_user = "data_brew"
  )
  
  tags$head(
    
    tags$link(rel="stylesheet", type="text/css", href="www/custom.css")
    # tags$link(rel="stylesheet", type="text/css", href="www/custom.css")
  )
}

app <- function(){
  # Detect the system. If on AWS, don't launch browswer
  is_aws <- grepl('aws', tolower(Sys.info()['release']))
  shinyApp(ui = app_ui,
           server = app_server,
           options = list('launch.browswer' = !is_aws))
}