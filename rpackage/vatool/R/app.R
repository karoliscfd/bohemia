
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
#' @import dplyr
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
            text="History",
            tabName="history"),
          menuItem(
            text="Adjudicate",
            tabName="adjudicate"),
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
              fluidRow(
                column(4, 
                       uiOutput('top_button'),
                       br(),
                       uiOutput('ui_main', inline = TRUE))
              ),
              br(),
              fluidRow(
                column(8,
                       DT::dataTableOutput('va_table')),
                column(4,
                       uiOutput('ui_select_va'),
                       uiOutput('ui_assign_cod'),
                       uiOutput('ui_submission'))
              )
            )
          ),
          tabItem(
            tabName = 'history',
            fluidRow(
              column(12,
                     h2('User info'),
                     DT::dataTableOutput('user_table'),
                     br(),
                     h2('Submission history'),
                     DT::dataTableOutput('history_table'))
            )
          ),
          tabItem(
            tabName = 'adjudicate',
            fluidRow(
              uiOutput('ui_adjudicate')
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
#' @import dplyr
app_server <- function(input, output, session) {
  is_local <- FALSE
  logged_in <- reactiveVal(value = FALSE)
  submission_success <- reactiveVal(value = NULL)
  adj_submission_success <- reactiveVal(value = NULL)
  
  log_in_fail <- reactiveVal(value=FALSE)
  # Connect to database
  message('Connecting to database : ', ifelse(is_local, ' local', 'remote'))
  con <- get_db_connection(local = is_local)
  # Get list of authorized users, session, and cod tables
  users <- dbReadTable(conn = con, 'vatool_users')
  cods <- dbReadTable(conn=con, 'vatool_cods')
  data <- reactiveValues(va = data.frame(), session = data.frame(), cod = data.frame())
  # save(users, cods, file = 'va_data.rda')
  print(users)
  
  # Upon log in, read in data
  observeEvent(input$log_in,{
    message('in observeEvent(input$log_in')
    liu <- input$log_in_user
    lip <- input$log_in_password
    # See if the user exists and the password is correct
    ok <- FALSE
    if(!is.null(users)){
      message('at point 6')
      if(tolower(liu) %in% users$username & tolower(lip) %in% users$password){
        ok <-TRUE
      }
    }
    
    if(ok){
      logged_in(TRUE)
      removeModal()
      # load data
      # data$va <- load_va_data(is_local = is_local)
      data$va <- readRDS('~/Desktop/va_data.rda')
      # print(head(data$va))
      # create table with same columns as session table in database (to append upon logout)
      print(users)
      message('at point 2')
      save(users, file = '/tmp/users.RData')
      user_id <- users %>% dplyr::filter(username == tolower(liu)) %>% .$user_id
      start_time <- Sys.time()
      end_time <- NA
      data$session <- dplyr::tibble(user_id = user_id, start_time=start_time, end_time=end_time)
      
      # create cod table
      data$cod <- dplyr::tibble(user_id = user_id, death_id = NA, cod_code_1 = NA,cod_1 =NA,cod_code_2 = NA,cod_2 =NA,cod_code_3 = NA,cod_3 =NA, time_stamp = NA)
      
    } else {
      logged_in(FALSE)
      log_in_fail(TRUE)
      removeModal()
    }
    
  })

  # Selection input for VA ID
  output$ui_adjudicate <- renderUI({
    li <- logged_in()
    uu <- !is.null(users)
    li <- li & uu
    if(li){
      liu <- input$log_in_user
      message('at point 3')
      user_role <- users %>% dplyr::filter(username == tolower(liu)) %>% .$role
      cod <- cods %>% group_by(death_id, cod_3) %>% summarise(counts = n())
      if(user_role == 'Adjudicator'){
        # get ids that have more than one diagnosis
        death_id_choices <- unique(cod$death_id[duplicated(cod$death_id)])
        cods_choices <- cod_choices()
        fluidPage(
          fluidRow(
            column(8,
                   h2('Previous diagnoses'),
                   DT::dataTableOutput('adj_table_2'),
                   h2('Patient info'),
                   DT::dataTableOutput('adj_table_1')),
            column(4,
                   br(),
                   selectInput('adj_death_id', 'Select the VA ID', choices = death_id_choices),
                   selectInput('adj_cods', 'Select underlying cause of death',  choices = c('', names(cods_choices))),
                   br(),
                   actionButton('adj_submit_cod', 'Submit cause of death'),
                   uiOutput('ui_submission_adj'))
          )
        )
      } else {
        fluidPage(
          fluidRow(
            h2('You must be an Adjudicator to view this page')
          ) 
        )
      }
    } else {
      NULL
    }
  })
  
  # table showing 
  output$adj_table_1 <- DT::renderDataTable({
    li <- logged_in()
    out <- NULL
    if(li){
      idi <- input$adj_death_id
      if(!is.null(idi)){
        pd <- data$va
        person <- pd %>% filter(death_id == idi)
        person <- get_va_names(person)
        # remove columns with NA
        person <- person[ , apply(person, 2, function(x) !any(is.na(x)))]
        # remove other columns 
        # remove other columns 
        remove_these <- "write your 3 digit|Id10007|server|first or given|the surname|name of VA|1	Manually write your 3 digit worker ID here|tz001|this_usernameTake a picture of the painted Household ID|isadult1|isadult2|isneonatal|isneonatal2|ischild1|ischild2|instancename|instance_id|device_id|end_time|start_time|todays_date|wid|Do you have a QR code with your worker ID?|wid|ageindays|ageindaysneonate|ageinmonths|ageinmonthsbyyear|ageinmonthsremain|ageinyears2|ageinyearsremain|The GPS coordinates represents|Collect the GPS coordinates of this location|Does the house you're at have a painted ID number on it?|hh_id|Write the 6 digit household ID here"
        person <- person[, !grepl(remove_these, names(person))]
        person <- person[,apply(person, 2, function(x) x != 'no')]
        
        out <- as.data.frame(t(person))
        out$Question <- rownames(out)
        names(out) <- c('Answer', 'Question')
        rownames(out) <- NULL
        out <- out[, c('Question', 'Answer')]
        # out <- out[which(nchar(as.character(out$Answer)) < 700),]
        # out <- 
        #   tibble(Variable = names(person),
        #          Response = person[1,])
      }
    } 
    out
  })
  
  # table showing 
  output$adj_table_2 <- DT::renderDataTable({
    li <- logged_in()
    out <- NULL
    if(li){
      idi <- input$adj_death_id
      if(!is.null(idi)){
        out <- cods %>% filter(death_id == idi)
      }
    } 
    
    names(out) <- c('User ID', 'Death ID', 'Immediate COD code', 'Immediate COD', 'Intermediary COD code', 'Intermediary COD', 'Underlying COD code', 'Underlying COD', 'Time stamp')
    out
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
      liu <- input$log_in_user
      li_text <- paste0('Welcome ', liu)
      p(li_text)
    } else if (lif){
      p('Username or password incorrect')
    } else {
      p('Not logged in')
    }
  })
  
  # Selection input for VA ID
  output$ui_select_va <- renderUI({
    li <- logged_in()
    if(li){
      pd <- data$va
      choices <- pd$death_id
      selectInput('death_id', 'Select the VA ID', choices = choices, selected = choices[1])
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
          selectInput('cod_1', 'Select immediate cause of death', choices =c('', names(choices)) , selected = ''),
          selectInput('cod_2', 'Select intermediary cause of death', choices =c('', names(choices)), selected = ''),
          selectInput('cod_3', 'Select underlying cause of death', choices =c('', names(choices)), selected = '')
        ),
        fluidRow(
          actionButton('submit_cod', 'Submit cause of death')
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
        # remove columns with NA
        person <- person[ , apply(person, 2, function(x) !any(is.na(x)))]
      
        # remove other columns 
        remove_these <- "write your 3 digit|Id10007|server|first or given|the surname|name of VA|1	Manually write your 3 digit worker ID here|tz001|this_usernameTake a picture of the painted Household ID|isadult1|isadult2|isneonatal|isneonatal2|ischild1|ischild2|instancename|instance_id|device_id|end_time|start_time|todays_date|wid|Do you have a QR code with your worker ID?|wid|ageindays|ageindaysneonate|ageinmonths|ageinmonthsbyyear|ageinmonthsremain|ageinyears2|ageinyearsremain|The GPS coordinates represents|Collect the GPS coordinates of this location|Does the house you're at have a painted ID number on it?|hh_id|Write the 6 digit household ID here"
        
        person <- person[, !grepl(remove_these, names(person))]
        person <- person[,apply(person, 2, function(x) x != 'no')]
        out <- as.data.frame(t(person))
        out$Question <- rownames(out)
        names(out) <- c('Answer', 'Question')
        rownames(out) <- NULL
        out <- out[, c('Question', 'Answer')]
        # out <- out[which(nchar(as.character(out$Answer)) < 700),]
        # out <- 
        #   tibble(Variable = names(person),
        #          Response = person[1,])
      }
    } 
    if(!is.null(out)){
      if(is.data.frame(out)){
        
        databrew::prettify(out, nrows = nrow(out))
      }
    }
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
    session_data <- data$session
    session_data$end_time <- Sys.time()
    dbAppendTable(conn = con, name = 'vatool_sessions', value = session_data)
  })
  
  # Observe submission of cause of death and save
  observeEvent(input$submit_cod, {
    cod_names <- cod_data()
    cod_data <- data$cod
    cod_1 = input$cod_1
    cod_2 = input$cod_2
    cod_3 = input$cod_3
    # condition if underlying cause of death is not fiilled out, wont submit
    if(cod_1==''){
      submission_success(FALSE)
    } else {
      death_id = input$death_id
      cod_data$cod_1 = cod_1
      cod_data$cod_2 = cod_2
      cod_data$cod_3 = cod_3
      cod_data$death_id = death_id
      cod_data$time_stamp <- Sys.time()
      # save(cod_data,cod_1, cod_2, cod_3, cod_names,file='temp.rda')
      
      # ISSUE HERE IS THAT SOME (LIKE DIARRHOEA) ARE ASSOCIATED WITH TWO CODES AND VICE VERSA
      cod_data$cod_1 <- cod_names$cod_code[cod_names$cod_names==cod_data$cod_1][1]
      cod_data$cod_2 <- cod_names$cod_code[cod_names$cod_names==cod_data$cod_2][1]
      cod_data$cod_3 <- cod_names$cod_code[cod_names$cod_names==cod_data$cod_3][1]
      dbAppendTable(conn = con, name = 'vatool_cods', value = cod_data)
      submission_success(TRUE)
    }
   
  })
  
  # Observe changes in inputs
  observeEvent(c(input$cod,input$death_id), {
    submission_success(NULL)
  })

  output$ui_submission <- renderUI({
    ss <- submission_success()
    if(is.null(ss)){
      NULL
    } else if(ss){
      h3('Submission successful')
    } else {
      h3('Submission unsuccessful')
    }
  })
  
  # history table 
  output$user_table <- DT::renderDataTable({
    li <- logged_in()
    out <- NULL
    if(li){
      if(!is.null(users)){
        message('at point 4')
        liu <- input$log_in_user
        out <- users %>% dplyr::filter(username == tolower(liu))
        names(out) <- c('User ID', 'Username', 'Password', 'First name', 'Last name', 'Country', 'Role')
        out
      }
    } 
    out
  })
  
  # history table 
  output$history_table <- DT::renderDataTable({
    li <- logged_in()
    out <- NULL
    if(li){
      if(!is.null(users)){
        message('at point 5')
        liu <- input$log_in_user
        user <- users %>% dplyr::filter(username == tolower(liu))
        userid <- user %>% dplyr::filter(username == tolower(liu)) %>% .$user_id
        out <- cods %>% dplyr::filter(user_id == userid)
        names(out) <-  c('User ID', 'Death ID', 'Immediate COD code', 'Immediate COD', 'Intermediary COD code', 'Intermediary COD', 'Underlying COD code', 'Underlying COD', 'Time stamp')
      }
    } 
    out
  })

  # Adjudicator submissions
  # Observe submission of cause of death and save
  observeEvent(input$adj_submit_cod, {
    cod_names <- cod_data()
    cod_data <- data$cod
    cod_1 = input$adj_cods
    # condition if underlying cause of death is not fiilled out, wont submit
    if(cod_1==''){
      adj_submission_success(FALSE)
    } else {
      death_id = input$adj_death_id
      cod_data$cod_1 = input$adj_cods
      cod_data$death_id = death_id
      cod_data$time_stamp <- Sys.time()

      # ISSUE HERE IS THAT SOME (LIKE DIARRHOEA) ARE ASSOCIATED WITH TWO CODES AND VICE VERSA
      cod_data$cod_1 <- cod_names$cod_code[cod_names$cod_names==cod_data$cod_1][1]
      dbAppendTable(conn = con, name = 'vatool_cods', value = cod_data)
      adj_submission_success(TRUE)
    }
    
  })
  
  # Observe changes in inputs
  observeEvent(c(input$adj_cod,input$adj_death_id), {
    adj_submission_success(NULL)
  })
  
  output$ui_submission_adj <- renderUI({
    ss <- adj_submission_success()
    if(is.null(ss)){
      NULL
    } else if(ss){
      h3('Submission successful')
    } else {
      h3('Submission unsuccessful')
    }
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
