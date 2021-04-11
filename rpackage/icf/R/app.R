
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
#' @import shinyjs

suppressPackageStartupMessages(
  library(shinyjs)
)

library(dplyr)
if('ifc.RData' %in% dir('/tmp')){
  load('ifc.RData')
} else {
  # Get fieldworker data
  # Define a default fieldworkers data
  if(!'fids.csv' %in% dir('/tmp')){
    fids_url <- 'https://docs.google.com/spreadsheets/d/1o1DGtCUrlBZcu-iLW-reWuB3PC8poEFGYxHfIZXNk1Q/edit#gid=0'
    fids1 <- gsheet::gsheet2tbl(fids_url) %>% dplyr::select(bohemia_id, first_name, last_name, supervisor, Role = details) %>% dplyr::mutate(country = 'Tanzania')
    fids_url <- 'https://docs.google.com/spreadsheets/d/1o1DGtCUrlBZcu-iLW-reWuB3PC8poEFGYxHfIZXNk1Q/edit#gid=409816186'
    fids2 <- gsheet::gsheet2tbl(fids_url) %>% dplyr::select(bohemia_id, first_name, last_name, supervisor, Role = details) %>% dplyr::mutate(country = 'Mozambique')
    fids_url <- 'https://docs.google.com/spreadsheets/d/1o1DGtCUrlBZcu-iLW-reWuB3PC8poEFGYxHfIZXNk1Q/edit#gid=179257508'
    fids3 <- gsheet::gsheet2tbl(fids_url) %>% dplyr::select(bohemia_id, first_name, last_name, supervisor, Role = details) %>% dplyr::mutate(country = 'Catalonia')
    fids <- bind_rows(fids1, fids2, fids3)
    readr::write_csv(fids, '/tmp/fids.csv')
  } else {
    fids <- readr::read_csv('/tmp/fids.csv')
  }
  
  # Read in locations
  locations <- bohemia::locations
  
  
  
  # Prepare some dummy data
  date_choices <- as.Date((Sys.Date()-30):Sys.Date(), origin = '1970-01-01')
  dates <- sample(date_choices, 1500, replace = TRUE)
  hh_ids <- paste0(sample(locations$code, 1500, replace = T), '-',
                   seq(100, 599, by = 1))
  hh <- 
    dplyr::tibble(date = dates,
                  hh_id = hh_ids)
  out_list <- list()
  for(i in 1:nrow(hh)){
    this_hh <- hh$hh_id[i]
    nn <- sample(1:15, 1)
    nums <- bohemia::add_zero(1:nn, 3)
    ids <- paste0(this_hh, '-', nums)
    out <- dplyr::tibble(hh_id = this_hh,
                         date = hh$date[i],
                         id = ids)
    out_list[[i]] <- out
  }
  df <- bind_rows(out_list)
  df$fid <- sample(fids$bohemia_id[!is.na(fids$first_name)], nrow(df), replace = TRUE)
  df <- left_join(df, fids %>% mutate(fw_name = paste0(first_name, ' ', last_name)) %>%
                    dplyr::select(bohemia_id, fw_name), by = c('fid' = 'bohemia_id'))
  df$hamlet_code <- substr(df$id, 1, 3)
  df <- left_join(df, locations %>% dplyr::select(code, hamlet = Hamlet), by = c('hamlet_code' = 'code'))
  df$name <- paste0(sample(babynames::babynames$name, nrow(df), replace = TRUE))
  df$age <- round(rnorm(n = nrow(df), mean = 50, sd = 20)); df$age <- ifelse(df$age <0, df$age *-1, df$age)
  df$type_icf <- sample(c('HoH',
                          'Adult',
                          'Child 12-18',
                          'Parent/guardian'),
                        nrow(df),
                        replace = TRUE)
  df$pid <- df$id
  save(df, file = '/tmp/ifc.RData')
}

error_list <- c('Participant did not sign',
                'Participant did not date',
                'Witness did not sign',
                'Witness did not date',
                'Fieldworker did not sign',
                'Fieldworker did not date',
                'Dates do not match',
                'Fieldworker wrote participant name',
                'Fieldworker wrote participant date',
                'Fieldworker wrote witness name',
                'Fieldworker wrote witness date',
                'Unclear thumbprint',
                'Questions and/or answers were not written in correct place',
                'Questions were not recorded/not documented that there were no questions',
                'Answers not recorded',
                'Answers incorrect/misleading',
                'Participant ID not on each page',
                'Participant ID differs across pages',
                'Participant name is different to participant signature',
                'Witness name is different to witness signature',
                'Handwriting ilegibile',
                'Incorrect participant ID',
                'Overwriting and/or obliteration')


app_ui <- function(request) {
  options(scipen = '999')
  useShinyjs()
  
  tagList(
    mobile_golem_add_external_resources(),
    
    dashboardPage(
      dashboardHeader (title = "ICF tool"),
      dashboardSidebar(
        sidebarMenu(
          menuItem(
            text="ICF First Verification",
            tabName="icf1"),
          menuItem(
            text="ICF Return Verification",
            tabName="icf2"),
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
            tabName="icf1",
            fluidPage(
              fluidRow(
                uiOutput('top_button')
              ),
              
              fluidRow(
                column(4,
                       dateInput('date_of_visit', 'Date of visit',min = min(df$date),
                                 max = max(df$date))),
                column(4, 
                       uiOutput('ui_hh_id')),
                column(4, uiOutput('ui_person_id'))),
              fluidRow(column(12,
                              DT::dataTableOutput('person_table'))),
              fluidRow(
                h3('Transcription of errors detected in the field'),
                p('Check the "Verification list for supervisors", did the ICF present any of the following errors detected by the supervisor in the field?'),
                mod_error_check_ui("error_1", error_list[1]),
                mod_error_check_ui("error_2", error_list[2]),
                mod_error_check_ui("error_3", error_list[3]),
                mod_error_check_ui("error_4", error_list[4]),
                mod_error_check_ui("error_5", error_list[5]),
                mod_error_check_ui("error_6", error_list[6]),
                mod_error_check_ui("error_7", error_list[7]),
                mod_error_check_ui("error_8", error_list[8]),
                mod_error_check_ui("error_9", error_list[9]),
                mod_error_check_ui("error_10", error_list[10]),
                mod_error_check_ui("error_11", error_list[11]),
                mod_error_check_ui("error_12", error_list[12]),
                checkboxInput('no_errors', 'No errors', value = FALSE)
                
              ),
              fluidRow(
                h3('Errors detected by the archivist'),
                p('Does the ICF present any of the following errors?'),
                mod_error_check_archivist_ui('error_arc_1', error_list[1]),
                mod_error_check_archivist_ui('error_arc_2', error_list[2]),
                mod_error_check_archivist_ui('error_arc_3', error_list[3]),
                mod_error_check_archivist_ui('error_arc_4', error_list[4]),
                mod_error_check_archivist_ui('error_arc_5', error_list[5]),
                mod_error_check_archivist_ui('error_arc_6', error_list[6]),
                mod_error_check_archivist_ui('error_arc_7', error_list[7]),
                mod_error_check_archivist_ui('error_arc_8', error_list[8]),
                mod_error_check_archivist_ui('error_arc_9', error_list[9]),
                mod_error_check_archivist_ui('error_arc_10', error_list[10]),
                mod_error_check_archivist_ui('error_arc_11', error_list[11]),
                mod_error_check_archivist_ui('error_arc_12', error_list[12]),
                mod_error_check_archivist_ui('error_arc_13', error_list[13]),
                mod_error_check_archivist_ui('error_arc_14', error_list[14]),
                mod_error_check_archivist_ui('error_arc_15', error_list[15]),
                mod_error_check_archivist_ui('error_arc_16', error_list[16]),
                mod_error_check_archivist_ui('error_arc_17', error_list[17]),
                mod_error_check_archivist_ui('error_arc_18', error_list[18]),
                mod_error_check_archivist_ui('error_arc_19', error_list[19]),
                mod_error_check_archivist_ui('error_arc_20', error_list[20]),
                mod_error_check_archivist_ui('error_arc_21', error_list[21]),
                mod_error_check_archivist_ui('error_arc_22', error_list[22]),
                mod_error_check_archivist_ui('error_arc_23', error_list[23]),
                checkboxInput('other', 'Other', value = FALSE),
                uiOutput('ui_other'),
                checkboxInput('no_errors_arc', 'No errors', value = FALSE),
                uiOutput('ui_arc_end')
              )
            )
          ),
          tabItem(
            tabName = 'icf2',
            fluidPage(
              h1('Pending input')
            )),
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
                div(a(actionButton(inputId = "email", label = "info@databrew.cc",
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
  
  logged_in <- reactiveVal(value = TRUE)
  observeEvent(input$log_in,{
    logged_in(TRUE)
    removeModal()
  })
  
  output$top_button <- renderUI({
    li <- logged_in()
    if(li){
      actionButton("log_out", "Log out")
    } else {
      actionButton("show", "Log in")
    }
    
  })
  
  observeEvent(input$show, {
    logged_in(TRUE)
    # showModal(modalDialog(
    #   title = "Log in",
    #   fluidPage(
    #     fluidRow(
    #       column(6,
    #              textInput('email', 'Email')),
    #       column(6,
    #              passwordInput('password', 'Password'))
    #     ),
    #     fluidRow(
    #       actionButton('log_in', 'Log in')
    #     )
    #   )
    # ))
  })
  observeEvent(input$log_out, {
    logged_in(FALSE)
  })
  
  # create a reactive dataframe to store data
  x = reactiveValues(df=NULL)
  x$df <- data.frame(a = 1:3)
  
  output$ui_hh_id <- renderUI({
    date_of_visit <- input$date_of_visit
    if(is.null(date_of_visit)){
      NULL
    } else {
      choices <- df %>% filter(date == date_of_visit) 
      the_choices <- sort(unique(choices$hh_id))
      selectInput('hh_id', 'Household ID', choices = the_choices)
    }
  })
  
  output$ui_person_id <- renderUI({
    out <- df
    out <- data.frame(out)
    date_of_visit <- input$date_of_visit
    xhid <- input$hh_id
    done <- NULL
    if(!is.null(date_of_visit)){
      if(!is.null(xhid)){
        out <- out %>% 
          filter(date == date_of_visit) %>%
          filter(hh_id == xhid)
        id_choices <- out$pid
        done <- selectInput('person_id', 'Person ID', choices = id_choices)
      }
    }
    return(done)
  })
  
  dfr <- reactive({
    out <- df
    date_of_visit <- input$date_of_visit
    xhid <- input$hh_id
    person_id <- input$person_id
    if(!is.null(date_of_visit)){
      out <- out %>% filter(date == date_of_visit)
    }
    if(!is.null(xhid)){
      out <- out %>% filter(hh_id == xhid)
    }
    if(!is.null(person_id)){
      out <- out %>% filter(pid == person_id)
    }
    return(out)
  })
  
  output$person_table <- DT::renderDataTable({
    sub_df <- dfr()
    # pd <- t(sub_df)
    # pd <- data.frame(pd)
    # pd$field <- row.names(pd)
    # row.names(pd) <- NULL
    # pd$field <- gsub('_', ' ', toupper(pd$field))
    # pd <- pd %>% dplyr::select(Field = field, Value = pd)
    # DT::datatable(pd)
    DT::datatable(sub_df,
                  options = list(paging = FALSE,
                                 searching = FALSE))
  })
  
  
  output$ui_other <- renderUI({
    pd <- input$other
    if(!is.null(pd)){
      if(pd){
        textInput('other_text', 'Specify')
      }
    }
  })
  
  error_1 <- callModule(mod_error_check, 'error_1')
  error_2 <- callModule(mod_error_check, 'error_2')
  error_3 <- callModule(mod_error_check, 'error_3')
  error_4 <- callModule(mod_error_check, 'error_4')
  error_5 <- callModule(mod_error_check, 'error_5')
  error_6 <- callModule(mod_error_check, 'error_6')
  error_7 <- callModule(mod_error_check, 'error_7')
  error_8 <- callModule(mod_error_check, 'error_8')
  error_9 <- callModule(mod_error_check, 'error_9')
  error_10 <- callModule(mod_error_check, 'error_10')
  error_11 <- callModule(mod_error_check, 'error_11')
  error_12 <- callModule(mod_error_check, 'error_12')
  
  error_arc_1 <- callModule(mod_error_check_archivist, 'error_arc_1')
  error_arc_2 <- callModule(mod_error_check_archivist, 'error_arc_2')
  error_arc_3 <- callModule(mod_error_check_archivist, 'error_arc_3')
  error_arc_4 <- callModule(mod_error_check_archivist, 'error_arc_4')
  error_arc_5 <- callModule(mod_error_check_archivist, 'error_arc_5')
  error_arc_6 <- callModule(mod_error_check_archivist, 'error_arc_6')
  error_arc_7 <- callModule(mod_error_check_archivist, 'error_arc_7')
  error_arc_8 <- callModule(mod_error_check_archivist, 'error_arc_8')
  error_arc_9 <- callModule(mod_error_check_archivist, 'error_arc_9')
  error_arc_10 <- callModule(mod_error_check_archivist, 'error_arc_10')
  error_arc_11 <- callModule(mod_error_check_archivist, 'error_arc_11')
  error_arc_12 <- callModule(mod_error_check_archivist, 'error_arc_12')
  error_arc_13 <- callModule(mod_error_check_archivist, 'error_arc_13')
  error_arc_14 <- callModule(mod_error_check_archivist, 'error_arc_14')
  error_arc_15 <- callModule(mod_error_check_archivist, 'error_arc_15')
  error_arc_16 <- callModule(mod_error_check_archivist, 'error_arc_16')
  error_arc_17 <- callModule(mod_error_check_archivist, 'error_arc_17')
  error_arc_18 <- callModule(mod_error_check_archivist, 'error_arc_18')
  error_arc_19 <- callModule(mod_error_check_archivist, 'error_arc_19')
  error_arc_20 <- callModule(mod_error_check_archivist, 'error_arc_20')
  error_arc_21 <- callModule(mod_error_check_archivist, 'error_arc_21')
  error_arc_22 <- callModule(mod_error_check_archivist, 'error_arc_22')
  error_arc_23 <- callModule(mod_error_check_archivist, 'error_arc_23')
  
  # Create a reactive object for capturing any errors by part
  error_list_1 <- reactive({
    c(error_1(), error_2(), error_3(), error_4(), error_5(), error_6(),
      error_7(), error_8(), error_9(), error_10(), error_11(), error_12())
  })
  any_errors_part_1 <- reactive({
    # This is problematic because it's not taking into account the follow-up questions
    out <- any(
      error_list_1(),
      na.rm = T)
    message('Any errors in part 1: ', out)
    out
  })
  
  error_list_2 <- reactive({
    c(error_arc_1(), error_arc_2(), error_arc_3(), error_arc_4(), error_arc_5(), error_arc_6(),
      error_arc_7(), error_arc_8(), error_arc_9(), error_arc_10(), error_arc_11(), error_arc_12(),
      error_arc_13(), error_arc_14(), error_arc_15(), error_arc_16(), error_arc_17(), error_arc_18(),
      error_arc_19(), error_arc_20(), error_arc_21(), error_arc_22(), error_arc_23())
  })
  any_errors_part_2 <- reactive({
    out <- any(
      error_list_2(),
      na.rm = T)
    message('Any errors in part 2: ', out)
    out
  })
  
  output$ui_arc_end <- renderUI({
    
    # See if "no errors" were declared
    ne1 <- input$no_errors
    ne2 <- input$no_errors_arc
    
    # See if any errors were ticked
    ae1 <- any_errors_part_1()
    ae2 <- any_errors_part_2()
    
    out <- NULL
    
    # If any error was marked on #7 the information about each error will feed List 3: ICFs to be corrected and be submitted to the server.
    if(ae2){
      
      # Get the part 2 errors
      e2_index <- error_list_2()
      e2 <- error_list[e2_index]
      
      # Get the person-level data
      p2 <- dfr()
      
      # Combine them
      combined <- tibble(Error = e2)
      for(j in 1:ncol(p2)){
        combined[,names(p2)[j]] <- p2[,j]
      }
      combined_dt <- DT::datatable(combined)
      
      out <-
        fluidPage(
          fluidRow(h1('List 3')),
          fluidRow(combined_dt)
        )
    } else {
      if(ae1 & ne2){
        out <- "You have marked errors not corrected in the field by field worker in 'Transcription of errors detected in the field' but have marked no errors in 'Errors detected by the archivist'. Please review."
      } else if(ne2){
        out <- 'Congratulations. You can file this ICF.'
      } 
      if(!is.null(out)){
        out <- h3(out)
      }
    }
    
    
    return(out)
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
  # addResourcePath(
  #   'www', system.file('app/www', package = 'icf')
  # )
  
  
  share <- list(
    title = "Bohemia ICF tool",
    url = "https://bohemia.team/icf/",
    image = "https://www.databrew.cc/images/logo_clear.png",
    description = "Bohemia app",
    twitter_user = "data_brew"
  )
  
  tags$head(
    
    
    # If you have a custom.css in the inst/app/www
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