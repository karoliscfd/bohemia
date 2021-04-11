library(shiny)
library(ggplot2)
library(shinyjs)

mod_error_check_ui <- function(id, question = 'Some rando') {
  useShinyjs()
  ns <- NS(id)
  # tagList(
  #   checkboxInput(ns('question1'), question, value = FALSE),
  #   radioButtons(ns('questionx'), label = 'Check the ICF, has the error been corrected in the field by the field worker?', 
  #                choices = c('Yes', 'No'),
  #                selected = character(length = 0))
  # )
  fluidRow(
    column(4,
           checkboxInput(ns('question1'), question, value = FALSE)),
    column(4,
           radioButtons(ns('question2'), label = 'Check the ICF, has the error been corrected in the field by the field worker?',
                        choices = c('Yes', 'No'),
                        selected = character(length = 0)))#,
    # column(4,
    #        uiOutput(ns('q2')))
  )
}

mod_error_check <- function(input, output, session) {

  ns <- session$ns
  
  observeEvent(input$question1, {
    q <- input$question1
    if(q){
      shinyjs::show(ns('question2'), asis = TRUE)
    } else {
      shinyjs::hide(ns('question2'), asis = TRUE)
    }
  })

  ro <- reactive({
    out <- input$question2
    if(is.null(out)){
      out <- FALSE
    } else {
      out <- ifelse(out == 'Yes', FALSE, TRUE)
    }
    message('the return object is ')
    print(out)
    out
  })
  return(ro)
}
