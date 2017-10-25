
selectScrape <- function() {
  if(any(strsplit(input$pageNumber,"")[[1]] %in% c(letters,LETTERS))){
    req(FALSE)
  }
  if(grepl("\\-", input$pageNumber) | grepl("\\.", input$pageNumber) | grepl("\\*", input$pageNumber) | grepl('\\"', input$pageNumber)){
    req(FALSE)
  }
  
  er <- try(get_n_pages(pdf$pdfPath))
  if(class(er)=="try-error"){req(FALSE)}
  
  req(length(unlist(strsplit(input$pageNumber, ",")))==1)
  
  pageScrapeNum <- as.numeric(unlist(strsplit(input$pageNumber, ",")))
  
  if(pageScrapeNum>get_n_pages(pdf$pdfPath)){
    showNotification("Page number doesn't exist", duration=3, type='error')
    hide("plot"); show("pdfOut")
  }
  req(pageScrapeNum<=get_n_pages(pdf$pdfPath))
  
  print(input$done)
  hide("pdfOut")
  show("cancel")
  show("plot")
  show("other")
  show("done")
  # show("transposeRow")
  
  pageNum <<- input$pageNumber
  
  dims <<- get_page_dims(pdf$pdfPath, pages = pageNum)
  dims <<- dims[[1]] #important when considering extra pages
  
  paths <<- make_thumbnails(pdf$pdfPath, outdir = tempdir(), pages = pageNum, format = "png", resolution = 100L)
  
  areas <<- rep(list(NULL), length(paths))
  
  area <<- NULL
  
  
  
  thispng <- readPNG(paths[[1]], native = TRUE)
  
  if (!length(area)) {
    startx <<- NULL
    starty <<- NULL
    endx <<- NULL
    endy <<- NULL
  } else {
    showArea <- function() {
      # convert from: top,left,bottom,right
      startx <<- area[2]
      starty <<- dims[2] - area[1]
      endx <<- area[4]
      endy <<- dims[2] - area[3]
      drawRectangle()
    }
    showArea()
  }
  
  print(paste("endx:", endx))
  
  drawPage <- function() {
    pre_par <<- graphics::par(mar=c(0,0,0,0), xaxs = "i", yaxs = "i", bty = "n")
    on.exit(graphics::par(pre_par), add = TRUE)
    graphics::plot(c(0, dims[1]), c(0, dims[2]), type = "n", xlab = "", ylab = "", asp = 1)
    graphics::rasterImage(thispng, 0, 0, dims[1], dims[2])
  }
  drawRectangle <- function() {
    if (!is.null(endx)) {
      graphics::rect(startx, starty, endx, endy, col = grDevices::rgb(1,0,0,.2) )
    }
  }
  
  output$plot <- shiny::renderPlot({
    pre_par <<- graphics::par(mar=c(0,0,0,0), xaxs = "i", yaxs = "i", bty = "n")
    on.exit(graphics::par(pre_par), add = TRUE)
    drawPage()
    
    #if (!is.null(input$plot_brush)) {
    startx <<- input$plot_brush$xmin
    endx <<- input$plot_brush$xmax
    starty <<- input$plot_brush$ymin
    endy <<- input$plot_brush$ymax
    print(paste("endx:", endx))
    drawRectangle()
    #}
  })
  
  print("Before click")
  
  print("After click")
  # show("transposeRow")
}

observeEvent(input$done, {
  if (is.null(startx)) {
    area <- NULL
  } else {
    # convert to: top,left,bottom,right
    print("do here?")
    area <- c(top = dims[2] - max(c(starty, endy)),
              left = min(c(startx,endx)),
              bottom = dims[2] - (min(c(starty,endy))),
              right = max(c(startx,endx)) )
  }
  area_list <- list(area)
  tables$df <- extract_tables(pdf$pdfPath, pages=pageNum, area=area_list)
  
  if(length(tables$df)==0){showNotification("No data detected: try again", type="warning", duration=5)}
  req(length(tables$df)>0)
  
  if(length(tables$df[[1]])>1){
    show("formatTableRow")
    temp <- as.data.table(tables$df[[1]])
    temp <- temp[,sapply(temp, function(x) {!all(x%in%c("","$","-"," "))}), with=FALSE]
    
    cols <- names(temp)
    
    for(i in 1:length(cols)) {
      temp[,cols[i]] <- gsub("\r"," ", eval(parse(text=paste0('temp$`', cols[i],'`'))))
    }
    
    current$current <- temp
    
  } else {
    showNotification("Invalid data", duration=3, type="error")
  }
  hide("plot"); show("pdfOut"); show("fileDownload"); hide("done"); hide("cancel")
})
















