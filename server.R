suppressPackageStartupMessages(library(shiny))
suppressPackageStartupMessages(library(data.table))
suppressPackageStartupMessages(library(rhandsontable))
suppressPackageStartupMessages(library(shinyjs))
suppressPackageStartupMessages(library(shinyBS))
suppressPackageStartupMessages(library(shinythemes))
suppressPackageStartupMessages(library(png))
suppressPackageStartupMessages(library(httr))
suppressPackageStartupMessages(library(purrr))




shinyServer(function(input, output, session) {
  
  library(tabulizer)
  
  
  runjs('//$("#text-row > div:nth-child(4) > div > div.input-group > input").remove();
        $("#nwediv > div:nth-child(3) > div > div > input").remove()
        //$("#text-row > div:nth-child(4) > div.form-group.shiny-input-container").remove()
        $("#text-row > div:nth-child(4) > div > label").remove()'
  )
  current <- reactiveValues(current=data.frame(V1="", V2="", V3="", V4="", V5=""))#NA)#current=
  
  
  source('drawScrape.R', local=TRUE)
  source('functions.R', local=TRUE)
  
  hide("done"); hide("cancel"); hide("plot"); hide("scrapeRow"); hide("fileDownload")# hide("hot")
  
  pdf <- reactiveValues(pdf_folder = NA,
                        pdfPath = NA,
                        i = "NA",
                        i2 = NA,
                        counter = 0)
  
  tables <- reactiveValues(df=NA)
  safe_GET <- safely(GET)
  assign_extension <- function(response){
    if(is.null(response$result)){
      print("no response")
      # response$result$status_code
      "no response"
    } else{
      if(response$result$status_code==200){
        con_type <- response$result$headers$`content-type`
        if(grepl("pdf", con_type)){
          ext <- "pdf"
        } else if(grepl("zip", con_type)){
          ext <- "zip"
        } else if(grepl("html", con_type)){
          ext <- "html"
        } else {
          ext <- "other"
        }
        ext
      } else {
        print("bad response")
        response$result$status_code
        # stop()
      }
    }
  }
  ################################################################################################
  
  
  observeEvent(input$downloadButton, {
    req(input$downloadURL)
    showModal(waitingModal())
    url <- input$downloadURL
    pdf$pdf_folder <- "pdf_folder"
    
    
    x <- safe_GET(url)
    
    ext <- assign_extension(x)
    
    
    
    if(ext!='pdf') {
      print("bad extension")
      showNotification("This link does not work!", duration=3, type=c("warning"))
      removeModal()
      req(FALSE)
    }
    
    # if(!file.exists(pdf$pdf_folder)){
    suppressWarnings(dir.create("pdf_folder"))
    # }
    
    temp <- tempfile(fileext = ".pdf", tmpdir = "pdf_folder")
    
    download.file(url, temp, mode = "wb", quiet=TRUE)
    
    addResourcePath("pdf_folder", pdf$pdf_folder)
    
    
    output$pdfOut <- renderUI({
      tags$iframe(src=temp, style=paste0("height:", input$dimension[2],"px; width:100%"))
    })
    
    pdf$pdfPath <- temp
    removeModal()
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
  
  observeEvent(input$uploadButton, {
    if (is.null(input$uploadButton)){
      return(NULL)
    }
    
    # pdf$i <- round(runif(1)*10000000)
    # print(pdf$i)
    
    #####
    showModal(waitingModal())
    show("scrapeRow"); show("hot")
    
    
    
    pdf$pdfPath <- input$uploadButton$datapath#paste0("pdf_folder/", pdf$i, ".pdf")
    
    
    
    
    output$pdfOut <- renderUI({
      
      # 
      addResourcePath("pdf_folder",gsub("/0.pdf","",input$uploadButton$datapath))#"pdf_folder")
      
      
      tags$iframe(src=paste0("pdf_folder", "/0.pdf"), style=paste0("height:", input$dimension[2],"px; width:100%"))
      # tags$iframe(src=paste0(input$uploadButton$datapath), style=paste0("height:", input$dimension[2],"px; width:100%"))
    })
    
    
    
    removeModal()
    updateTextInput(session, inputId = "downloadURL", value="")
    
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
