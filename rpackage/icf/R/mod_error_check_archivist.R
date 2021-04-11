library(shiny)
library(ggplot2)

mod_error_check_archivist_ui <- function(id, question = 'Some rando') {
  ns <- NS(id)
  fluidRow(
    column(4, 
           checkboxInput(ns('question1'), question, value = FALSE))#,
    # column(8,
    #        uiOutput(ns('q2')))
  )
}

mod_error_check_archivist <- function(input, output, session) {
  return(reactive(input$question1))
  
  # output$q2 <- renderUI({
  #   x <- input$question1
  #   message('X IS ', x)
  #   if(!is.null(x)){
  #     if(x){
  #       radioButtons('question2', label = 'Check the ICF, has the error been corrected in the field by the field worker?', 
  #                    choices = c('Yes', 'No'),
  #                    selected = character(0))
  #     }
  #   }
  # })
}
