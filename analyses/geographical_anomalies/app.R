#
# This is a Shiny web application. You can run the application by clicking
# the 'Run App' button above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)
library(leaflet)
source('code.R')

# Define UI for application that draws a histogram
ui <- fluidPage(

    # Application title
    titlePanel("Geographic anomalies identifier"),

    # Sidebar with a slider input for number of bins 
    sidebarLayout(
        sidebarPanel(
            radioButtons('country', 'Country', choices = c('Mozambique', 'Tanzania')),
            uiOutput('ui_hamlet'),
            checkboxInput('show_all', 'Show ALL households', value = FALSE),
            checkboxInput('show_previous', 'Show data already submitted', value = FALSE)
        ),

        mainPanel(
           leafletOutput("map"),
           DT::dataTableOutput('table'),
           uiOutput('ui_table'), uiOutput('ui_table2'),
           uiOutput('ui_previous'),
           DT::dataTableOutput('previous_table')
        )
    )
)

# Define server logic required to draw a histogram
server <- function(input, output) {
    
    uuids <- reactiveValues(done = c(),
                            pending = c())
    

    
    
    output$ui_previous <- renderUI({
        show_previous <- input$show_previous
        if(show_previous){
            h3('Previously submitted data')
        } else {
            NULL
        }
    })
    
    counter <- reactiveVal(value = 0)
    
    # observeEvent(counter(), {
    #     message('Getting list of uuids')
    #     cc <- input$country
    #     all_uuids <- df$instance_id[df$country == cc]
    #     done_uuids <- dir(paste0('rdas/', cc))
    #     done_uuids <- gsub('.rds', '', done_uuids)
    #     pending_uuids <- all_uuids[!all_uuids %in% done_uuids]
    #     uuids$done <- done_uuids
    #     uuids$pending <- pending_uuids
    # },
    # ignoreNULL = FALSE)
    
    observeEvent(input$show_previous, {
        old <- counter()
        newc <- old +1
        counter(newc)
    })
    observeEvent(input$submit, {
        old <- counter()
        newc <- old +1
        counter(newc)
    })
    
    previous_data <- reactiveValues(data = data.frame())
    
    observeEvent(counter(), {
        # show_previous <- input$show_previous
        # if(show_previous){
            cc <- input$country
            # done <- uuids$done
            done <- dir(paste0('rdas/', cc))
            done <- gsub('.rds', '', done)
            out_list <- list()
            if(length(done) > 0){
                for(i in 1:length(done)){
                    iid <- done[i]
                    file_path <- paste0('rdas/', cc, '/', iid, '.rds')
                    temp <- readRDS(file_path)
                    out_list[[i]] <- temp
                }
                done_table <- bind_rows(out_list)
                message('Number of rows in previous table:')
                message(nrow(done_table))
                message('Number of rows in dir')
                message(length(dir(paste0('rdas/', cc))))
                previous_data$data <- done_table
            }
        # } else {
        #     previous_data$data <- data.frame()
        # }
    })
    
    output$previous_table <- DT::renderDataTable({
        pd <- previous_data$data
        # save(pd, file = '/tmp/pd.RData')
        if(!is.null(pd)){
            if(nrow(pd) > 0){
                bohemia::prettify(pd, nrows = nrow(pd),
                                  download_options = TRUE)
            }
        }
    })

    output$ui_hamlet <- renderUI({
        # pending_uuids <- uuids$pending
        # pd <- df %>% filter(instance_id %in% pending_uuids) %>%
        #     arrange(hh_id)
        # choices <- as.character(pd$instance_id)
        # names(choices) <- pd$hh_id
        choices <- codes
        cc <- input$country
        locs <- bohemia::locations %>% filter(Country == cc)
        choices <- choices[choices %in% locs$code]
        selectInput('hamlet',
                    'Hamlet',
                    choices = choices )
    })
    output$map <- renderLeaflet({
        
        x <- previous_data$data
        x <- input$submit
        
        l <- leaflet() %>%
            addProviderTiles(providers$Esri.WorldImagery)
        
        this_code <- input$hamlet
        ok <- FALSE
        if(!is.null(this_code)){
            if(length(this_code) == 1){
                ok <- TRUE
                these_pts <- combined[combined@data$code %in% this_code,]
                this_hull <- hull_list[[this_code]]
            }
        }
        
        if(ok){
            message('Map is okay')
            l <- l %>%
                clearShapes() %>%
                addPolygons(data = this_hull,
                            color = 'red',
                            fillColor = 'black',
                            fillOpacity = 0.2,
                            weight = 1) %>%
                addCircleMarkers(data = these_pts,
                                 popup = these_pts@data$hh_id,
                                 fillColor = 'orange',
                                 color = NA,
                                 radius = 4,
                                 fillOpacity = 0.8,
                                 layerId = these_pts@data$instance_id) 
        }
        show_all <- input$show_all
        if(show_all){
            
            cc <- input$country
            
            colors <- rainbow(length(unique(codes)))
            colors <- sample(colors, size = length(colors))
            cols <- colors[as.numeric(factor(combined$code))]
            pd <- combined
            pd$color <- cols
            pd <- pd[pd@data$country == cc,]
            l <- l %>%
                addCircleMarkers(data = pd,
                                 popup = pd@data$hh_id,
                                 fillColor = pd$color,
                                 color = NA,
                                 radius = 3,
                                 fillOpacity = 0.6,
                                 layerId = pd@data$instance_id) 
            if(!is.null(these_pts)){
                l <- l %>%
                    leaflet::setView(lng = median(these_pts@data$lng),
                                     lat = median(these_pts@data$lat),
                                     zoom = 12)
            }
        }
        show_previous <- input$show_previous
        if(show_previous){
            previous <- previous_data$data

            if(!is.null(previous)){
                if(nrow(previous) > 0){
                    previous_rows <- combined[combined@data$instance_id %in% previous$instance_id,]
                    l <- l %>%
                        addMarkers(data = previous_rows,
                                   layerId = previous$instance_id,
                                   popup = paste0(unlist(previous), collapse = '; '))
                }
            }
        }
        
            l
        
    })
    
    # Observe the clicked household
    click_data <- reactiveValues(data = NULL)
    observeEvent(input$map_marker_click, {
        click_point <- input$map_marker_click
        # print(click_point)
        # Get the data for that clickpoint
        iid <- click_point$id
        save(click_point, iid, combined, file = '/tmp/click_point.RData')
        
        pd <- combined@data %>%
            dplyr::filter(instance_id == iid) %>%
            dplyr::select(instance_id, hh_id)
        click_data$data <- pd

    })
    

    submit_data <- reactive({
        pd <- click_data$data
        ok <- FALSE
        if(!is.null(pd)){
            if(nrow(pd) > 0){
                ok <- TRUE
            }
        }
        if(ok){
            category <- input$category
            if(!is.null(category)){
                pd$category <- category
            }
            comment <- input$comment
            if(!is.null(comment)){
                pd$comment <- comment
            }
            new_code <- input$new_code
            if(!is.null(new_code)){
                pd$new_code <- new_code
            }
            pd
        }
    })
    
    output$table <- DT::renderDataTable({
        pd <- click_data$data
        ok <- FALSE
        if(!is.null(pd)){
            if(nrow(pd) == 1){
                ok <- TRUE
            }
        }
        if(ok){
            pd
        }
    })
    
    output$ui_table <- renderUI({
        pd <- click_data$data
        ok <- FALSE
        if(!is.null(pd)){
            if(nrow(pd) == 1){
                ok <- TRUE
            }
        }
        if(ok){
            fluidRow(
                column(6,
                       selectInput('category',
                                   'Category',
                                   choices = c('Is correct as is',
                                               'Requires removal',
                                               'Requires change of code'))),
                column(6,
                       textInput('comment',
                                 'Comments'))
            )
        }
    })
    
    output$ui_table2 <- renderUI({
        pd <- click_data$data
        ok <- FALSE
        nc <- NULL
        if(!is.null(pd)){
            if(nrow(pd) == 1){
                ok <- TRUE
                category <- input$category
                if(!is.null(category)){
                    if(category == 'Requires change of code'){
                        nc <- textInput('new_code', 'New code')
                    }
                }
            }
        }
        if(ok){
            fluidRow(
                column(6,
                       nc),
                column(6,
                       actionButton('submit', 'Submit'))
            )
        }
    })
    
    # Observe submission
    observeEvent(input$submit,{
        pd <- submit_data()
        iid <- pd$instance_id
        cc <- input$country
        file_path <- paste0('rdas/', cc, '/', iid, '.rds')
        message('Saving the following data to ', file_path)
        print(pd)
        saveRDS(pd, file_path)
    })
}

# Run the application 
shinyApp(ui = ui, server = server)
