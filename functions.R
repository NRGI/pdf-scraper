checkURL <- function(url) {
  tryCatch(stop_for_status(GET(url)),
           http_404 = function(c) "That url doesn't exist",
           http_403 = function(c) "You need to authenticate!",
           http_400 = function(c) "You made a mistake!",
           http_500 = function(c) "The server screwed up"
  )
}

##------------------------------------------------------------------------------------------------
##------------------------------------------------------------------------------------------------

pageScrape <- function() {

  if(any(strsplit(input$pageNumber,"")[[1]] %in% c(letters,LETTERS))){
    req(FALSE)
  }
  
  if(grepl("\\-", input$pageNumber) | grepl("\\.", input$pageNumber) | grepl("\\*", input$pageNumber) | grepl('\\"', input$pageNumber)){
    req(FALSE)
  }
  
  
  
  
  if(!grepl(":", input$pageNumber)){
    pageScrapeNum <- as.numeric(unlist(strsplit(input$pageNumber, ",")))
  }
  
  if(grepl(":", input$pageNumber)){
    print("in the loop")
    tpy <- strsplit(input$pageNumber, ":")
    pageScrapeNum <- as.numeric(tpy[[1]][1]):as.numeric(tpy[[1]][2])
    print(pageScrapeNum)
  }
  print("out of loop")
  print(pageScrapeNum)
  
  pageScrapeNum_max <- max(pageScrapeNum)
  
  er <- try(get_n_pages(pdf$pdfPath))
  if(class(er)=="try-error"){req(FALSE)}
  
  
  
  if(pageScrapeNum_max>get_n_pages(pdf$pdfPath)){
    showNotification("Page number doesn't exist", duration=3, type='error')
  }
  
  req(pageScrapeNum_max<=get_n_pages(pdf$pdfPath))
  
  showModal(waitingModal())
  
  print("WHAT")
  
  scraped_table <- extract_tables(pdf$pdfPath, widget="reduced", pages=pageScrapeNum)
  
  print("WHY")
  
  removeModal()
  
  if(length(scraped_table)==0){showNotification("No data detected: try select scrape", type="warning", duration=5)}
  req(length(scraped_table)>0)
  
  if(length(scraped_table)>1){
    for(i in 1:length(scraped_table)){
      
      scraped_table[[i]] <- data.table(scraped_table[[i]])
    }
    scraped_table[[1]] <- rbindlist(scraped_table, fill=TRUE)
  }
  
  if(length(scraped_table[[1]])>1){
    
    print("One")
    temp <- as.data.table(scraped_table[[1]])
    
    #attempt: remove all \r from data on scrape
    # cols <- names(temp)
    # print(cols)
    # 
    # for(i in 1:length(cols)) {
    #   temp[,cols[i]] <- gsub("\r"," ", eval(parse(text=paste0('temp$`', cols[i],'`'))))
    # }
    print("three")
    print(temp)
    current$current <- temp
    
    
  } else {
    showNotification("Invalid data", duration=3, type="error")
  }

}

##------------------------------------------------------------------------------------------------
##------------------------------------------------------------------------------------------------

waitingModal <- function(failed=FALSE, issue) {
  modalDialog(
    p("Scraping..."),
    footer = tagList()
  )
}