library(shiny)
library(tabulizer)
library(data.table)
library(rhandsontable)
library(shinyjs)
library(shinyBS)
library(shinythemes)
library(png)


shinyServer(function(input, output) {
  
  
  current <- reactiveValues(current=data.frame(V1="", V2="", V3="", V4="", V5=""))#NA)#current=
  
  source('drawScrape.R', local=TRUE)
  source('functions.R', local=TRUE)
  
  hide("done"); hide("cancel"); hide("plot"); hide("scrapeRow"); hide("fileDownload")# hide("hot")
  
  pdf <- reactiveValues(pdf_folder = NA,
                        pdfPath = NA)
  
  tables <- reactiveValues(df=NA)
  
  ################################################################################################
  
  observeEvent(input$downloadButton, {
    req(input$downloadURL)
    url <- input$downloadURL
    pdf$pdf_folder <- "pdf_folder"
   
    # if(!file.exists(pdf$pdf_folder)){
      dir.create("pdf_folder")
    # }
    
    temp <- tempfile(fileext = ".pdf", tmpdir = "pdf_folder")
    print("here1")
    download.file(url, temp, mode = "wb")
    print("here2")
    addResourcePath("pdf_folder", pdf$pdf_folder)
    
    output$pdfOut <- renderUI({
      tags$iframe(src=temp, style=paste0("height:", input$dimension[2],"px; width:100%"))
    })
    
    pdf$pdfPath <- temp
    show("scrapeRow"); show("hot")
  })
  
  ################################################################################################
  
  observeEvent(input$scrapeButton, {
    pageScrape()
    show("fileDownload")
  })
  
  ################################################################################################
  
  observeEvent(input$drawButton, {
    # show("plot"); hide("pdfOut")
    if(input$pageNumber==""){show("pdfOut"); req(FALSE)}
    selectScrape()
    
  })
  
  observeEvent(input$cancel, {
    hide("plot"); show("pdfOut")
  })
  
  ################################################################################################
  
  observe({
    # input$hotButton
    hot = input$hot #isolate(input$hot)#
    if (!is.null(hot)) {
      current$current <- hot_to_r(input$hot)
      
    }
  })
  
  output$hot = renderRHandsontable({
    rhandsontable(current$current, useTypes = FALSE) %>%
      hot_table(highlightCol = TRUE, highlightRow = TRUE)
  })
  ################################################################################################
  
  output$fileDownload <- downloadHandler(
    filename = function() {
      paste0("scraped-data", ".csv")
    },
    content = function(file) {
      # current$current <- hot_to_r(input$hot)
      write.csv(current$current, file, row.names = FALSE)
    }
  )
  
  
})
