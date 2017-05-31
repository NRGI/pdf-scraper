
library(shiny)
library(tabulizer)
library(data.table)
library(rhandsontable)
library(rvest)
library(googlesheets)
library(httr)
library(shinyjs)


shinyServer(function(input, output, session) {
  
  scrapeTrue <- FALSE
  isNewSheet <- FALSE
  checkSourcePush <- FALSE

  iso <- fread('data/isoCurrency.csv')
  
  tables <- reactiveValues(df = NULL)
  current <- reactiveValues()
  
  checkURL <- function(url) {
    tryCatch(stop_for_status(GET(url)),
             http_404 = function(c) "That url doesn't exist",
             http_403 = function(c) "You need to authenticate!",
             http_400 = function(c) "You made a mistake!",
             http_500 = function(c) "The server screwed up"
    )
  }
  
  
  pushCheck <- function(key){
    
    rpSt <- grepl("[0-9]{4}-[0-9]{2}-[0-9]{2}", input$reportStart)
    rpEnd <- grepl("[0-9]{4}-[0-9]{2}-[0-9]{2}", input$reportEnd)
    srcSt <- grepl("[0-9]{4}-[0-9]{2}-[0-9]{2}", input$sourceDate)
    
    if(rpSt==FALSE) {
      showNotification("Incorrect format: Report start", duration=3, type="error")
      addClass("reportStart", "red")
      updateTabsetPanel(session, "tabset", selected="Add report")
      updateTabsetPanel(session, "addTabset", selected="Metadata")
    }
    if(rpEnd==FALSE) {
      showNotification("Incorrect format: Report end", duration=3, type="error")
      addClass("reportEnd", "red")
      updateTabsetPanel(session, "tabset", selected="Add report")
      updateTabsetPanel(session, "addTabset", selected="Metadata")
    }
    if(srcSt==FALSE) {
      showNotification("Incorrect format: Source date", duration=3, type="error")
      updateTabsetPanel(session, "tabset", selected="Add report")
      addClass("sourceDate", "red")
      updateTabsetPanel(session, "addTabset", selected="Metadata")
    }
    
    req(all(rpSt, rpEnd, srcSt))
    req(current$current)
    
    removeClass("reportStart", "red")
    removeClass("reportEnd", "red")
    removeClass("sourceDate", "red")
    
    if(input$companyName==""){showNotification("Add metadata: company name", duration=3, type="error")}
    if(input$sourceID==""){showNotification("Add metadata: source ID", duration=3, type="error")}
    
    req(input$companyName)
    req(input$sourceID)
    
    temp <- current$current
    print("Stop point 1")
    
    if(all(c("Country", "Notes","Payment type","Value","Company","id")%in%names(temp))!=TRUE){showNotification("Please reshape data", duration=3, type="error")}
    req(all(c("Country", "Notes","Payment type","Value","Company","id")%in%names(temp)))
    
    print("Stop point 2")
    if(nrow(temp)<1){
      showNotification("No data", duration=3, type="error")
    } else {
      
      if(nrow(temp[Country!=""])<1) {
        showNotification("Incomplete data: no country names", duration=3, type="error")
      } else{
        
        if("Payee Name" %in% names(temp)) {
          print("Stop point 3")
          gs_add_row(key, ws=2, input=temp)
          showNotification("Succesfully added", duration=3, type="message")
          print("Stop point 4")
        }
        
        if("Project Name" %in% names(temp)) {
          # final <- masterTable$masterProject
          # masterTable$masterProject <- unique(rbind(final, temp, fill=TRUE))
          print("Stop point 3.pro")
          gs_add_row(key, ws=3, input=temp)
          showNotification("Succesfully added", duration=3, type="message")
          print("Stop point 4.pro")
        }
        print("Stop point 5")
        temp2 <- data.table(CompanyName=input$companyName,
                            CompanyURL=input$companyURL,
                            CompanyCountry=input$companyCountry,
                            SourceName=input$sourceName,
                            SourceID=input$sourceID,
                            SourceURL=input$sourceURL,
                            SourceDate=input$sourceDate,
                            ReportStart=input$reportStart,
                            ReportEnd=input$reportEnd,
                            OpenCorporatesURL=input$openCorp,
                            Currency=substr(input$currency, nchar(input$currency)-3, nchar(input$currency)-1))
        
        if(checkSourcePush==FALSE){
          gs_add_row(key, ws=1, input=temp2)
          showNotification("Succesfully added", duration=3, type="message")
          checkSourcePush <<- TRUE
        }
        
        
        
        
      }
    }
  }
  
  hide("pickTable")
  hide("reset")
  hide("pageScrapeNum")
  hide("pageScrape")
  hide("showPanel")
  hide("newGov")
  hide("newProj")
  
  hide("deleteRowButton")
  hide("changeHeaderButton")
  hide("meltColumns")
  hide("deleteColButton")
  hide("doRow")
  
  ####################################################################################################################################################################################################
  ####################################################################################################################################################################################################
  ####################################################################################################################################################################################################
  
  
  ####################################################################################################################################################################################################
  #     Modal input
  
  ####################################################################################################################################################################################################
  password <- "password"
  password2 <- ""
  
  dataModal <- function(failed = FALSE) {
    modalDialog(
      passwordInput("password", 
                    "Insert passcode"
                    ),
      if (failed)
        div(tags$b("Invalid passcode", style = "color: red;")),
      footer = tagList(
        modalButton("Cancel"),
        actionButton("ok", "OK")
      )
    )
  }
  
  pushToMaster <- function(key) {
    if(!(is.null(masterTable$masterGov))) {gs_add_row(key, ws=2, input=masterTable$masterGov); showNotification("Government table succesfully added!", duration=3, type="message")} else {
      showNotification("No government data", duration=3, type="warning")
    }
    if(!(is.null(masterTable$masterProject))) {gs_add_row(key, ws=3, input=masterTable$masterProject); showNotification("Project table succesfully added!", duration=3, type="message")} else {
      showNotification("No project data", duration=3, type="warning")
    }
    if(!(is.null(masterTable$masterGov))) {gs_add_row(key, ws=1, input=masterTable$masterSource); showNotification("Source table succesfully added!", duration=3, type="message")} else {
      showNotification("No source data", duration=3, type="warning")
    }
  }
  
  
  observeEvent(input$ok, {
    password2 <<- input$password
    if (!is.null(input$password) && nzchar(input$password) && input$password==password) {
      pushToMaster(source_key)
      removeModal()
      #do other stuff here for pushing data
    } else {
      showModal(dataModal(failed = TRUE))
    }
  })
  
  observeEvent(input$addToRemote, {
    if(password2!=password){
      showModal(dataModal())
    }
    if(password2==password){
      pushToMaster(source_key)
      showNotification("Succesfully added!", duration=3, type="message")
    }
  })
  
  ###########
  #Toggle view panel
  ##
  observeEvent(input$hidePanel, {
    hide("hidePanel")
    hide("pdfOut")
    show("showPanel")
  })
  
  observeEvent(input$showPanel, {
    hide("showPanel")
    show("pdfOut")
    show("hidePanel")
  })
  
  ####################################################################################################################################################################################################
  #     Master data
  
  ####################################################################################################################################################################################################
  masterList <- data.table("Country"=NA,"Payee Name"=NA,"Payment type"=NA,"Value"=NA,"Notes"=NA) #data.table()+
  
  masterTable <- reactiveValues()
  new_sheet_key <- ""
  
  observeEvent(input$newSheetPush, {
    if(isNewSheet!=TRUE) {
      isNewSheet <<- TRUE
      showModal(
        modalDialog(
          textInput("newSheetName", label="Insert name"),
          footer = tagList(
            #modalButton("Cancel"),
            actionButton("sheetOK", "OK")
          )
        )
      )
    } else {
      
      print("New sheet is true")
      pushCheck(new_sheet_key)
    }
    updateTextInput(session, "url", value="")
    
  })
  
  observeEvent(input$sheetOK, {
    if(input$newSheetName=="") {showNotification("Add a new sheet name", type="error", duration=3)}
    req(input$newSheetName)
    gs_new(title=paste0(input$newSheetName, "_", Sys.Date(), "_ptgfile"),
           ws="Source",
           input=data.frame("CompanyName"='x', "CompanyURL"='x', "CompanyCountry"='x', "SourceName"='x', "SourceID"='x', "SourceURL"='x',	"SourceDate"='x',	"ReportStart"='x', "ReportEnd"='x',	"OpenCorporatesURL"='x', "Currency"='x'),
           byrow=TRUE
           )
    print("After create new")
    
    new_sheet_key <<- gs_title(x=paste0(input$newSheetName, "_", Sys.Date(), "_ptgfile"))
    print("After get sheet key")
    
    gs_ws_new(ss=new_sheet_key,
              ws_title="Government",
              input=data.frame("Country"='x',	"Payee Name"='x',	"Notes"='x',	"Payment Type"='x',	"Value"='x', "Company"='x',	"id"='x'),
              byrow=TRUE
              )
    gs_ws_new(ss=new_sheet_key,
              ws_title="Project",
              input=data.frame("Country"='x',	"Project Name"='x',	"Notes"='x',	"Payment Type"='x',	"Value"='x', "Company"='x',	"id"='x'),
              byrow=TRUE
              )
    new_sheet_key <<- gs_title(x=paste0(input$newSheetName, "_", Sys.Date(), "_ptgfile"))
    
    pushCheck(new_sheet_key)
    
    removeModal()
  })
  
    
    
  
  
  
  observeEvent(input$addToMaster, {
    rpSt <- grepl("[0-9]{4}-[0-9]{2}-[0-9]{2}", input$reportStart)
    rpEnd <- grepl("[0-9]{4}-[0-9]{2}-[0-9]{2}", input$reportEnd)
    srcSt <- grepl("[0-9]{4}-[0-9]{2}-[0-9]{2}", input$sourceDate)
    
    if(rpSt==FALSE) {
      showNotification("Incorrect format: Report start", duration=3, type="error")
      addClass("reportStart", "red")
      updateTabsetPanel(session, "tabset", selected="Add report")
      updateTabsetPanel(session, "addTabset", selected="Metadata")
      }
    if(rpEnd==FALSE) {
      showNotification("Incorrect format: Report end", duration=3, type="error")
      addClass("reportEnd", "red")
      updateTabsetPanel(session, "tabset", selected="Add report")
      updateTabsetPanel(session, "addTabset", selected="Metadata")
      }
    if(srcSt==FALSE) {
      showNotification("Incorrect format: Source date", duration=3, type="error")
      updateTabsetPanel(session, "tabset", selected="Add report")
      addClass("sourceDate", "red")
      updateTabsetPanel(session, "addTabset", selected="Metadata")
      }
    
    req(all(rpSt, rpEnd, srcSt))
    req(current$current)
    
    removeClass("reportStart", "red")
    removeClass("reportEnd", "red")
    removeClass("sourceDate", "red")
    
    if(input$companyName==""){showNotification("Add metadata: company name", duration=3, type="error")}
    if(input$sourceID==""){showNotification("Add metadata: source ID", duration=3, type="error")}
    
    req(input$companyName)
    req(input$sourceID)
    
    temp <- current$current
    str(temp)
    
    if(all(c("Country", "Notes","Payment type","Value","Company","id")%in%names(temp))!=TRUE){showNotification("Please reshape data", duration=3, type="error")}
    req(all(c("Country", "Notes","Payment type","Value","Company","id")%in%names(temp)))
    
    if(nrow(temp)<1){
      showNotification("No data", duration=3, type="error")
     } else {
      
       if(nrow(temp[Country!=""])<1) {
         showNotification("Incomplete data: no country names", duration=3, type="error")
       } else{
         
          if("Payee Name" %in% names(temp)) {
            final <- masterTable$masterGov
            masterTable$masterGov <- unique(rbind(final, temp, fill=TRUE))
          }
  
          if("Project Name" %in% names(temp)) {
            final <- masterTable$masterProject
            masterTable$masterProject <- unique(rbind(final, temp, fill=TRUE))
            print("works")
          }
  
          temp2 <- data.table(CompanyName=input$companyName,
                              CompanyURL=input$companyURL,
                              CompanyCountry=input$companyCountry,
                              SourceName=input$sourceName,
                              SourceID=input$sourceID,
                              SourceURL=input$sourceURL,
                              SourceDate=input$sourceDate,
                              ReportStart=input$reportStart,
                              ReportEnd=input$reportEnd,
                              OpenCorporatesURL=input$openCorp,
                              Currency=substr(input$currency, nchar(input$currency)-3, nchar(input$currency)-1))
  
  
          masterTable$masterSource <- unique(rbind(temp2, masterTable$masterSource))
          updateTextInput(session, "url", value="")
          
          updateTabsetPanel(session, "tabset", selected="Reports")
          updateTabsetPanel(session, "infoTabset", selected="ESTMA")
          
          # hide("pickTable")
          # hide("reset")
          # hide("pageScrapeNum")
          # hide("pageScrape")
          # hide("showPanel")
          # hide("deleteRowButton")
          # hide("changeHeaderButton")
          # hide("meltColumns")
          # hide("deleteColButton")
          # hide("doRow")
          # hide("newGov")
       }
     }
    
  })
  
  output$masterGovOut <- renderTable({masterTable$masterGov})
  
  output$masterProjectOut <- renderTable({masterTable$masterProject})
  
  output$masterSource <- renderTable({masterTable$masterSource})
  
  output$writeGovtBtn <- downloadHandler(
    filename = function() { paste('govt', Sys.Date(), '.csv', sep='') },
    content = function(file) {
      write.csv(masterTable$masterGov, file)
    }
  )
  
  output$writeProjectBtn <- downloadHandler(
    filename = function() { paste('project', Sys.Date(), '.csv', sep='') },
    content = function(file) {
      write.csv(masterTable$masterProject, file)
    }
  )
  
  output$writeSourceBtn <- downloadHandler(
    filename = function() { paste('source', Sys.Date(), '.csv', sep='') },
    content = function(file) {
      write.csv(masterTable$masterSource, file)
    }
  )
  
  ####################################################################################################################################################################################################
  #     Metadata functions
  
  ####################################################################################################################################################################################################
  
  output$currencyOut <- renderUI({
    selectInput("currency", label="Currency", choices=paste0(iso$Name, " (",iso$Code, ")"), selected="")
  })
  
  observeEvent(input$clearMeta, {
    updateTextInput(session, "sourceName", value=NA)
    updateTextInput(session, "sourceID", value=NA)
    updateTextInput(session, "sourceURL", value=NA)
    updateTextInput(session, "sourceDate", value=NA)
    updateTextInput(session, "companyName", value=NA)
    updateTextInput(session, "companyURL", value=NA)
    updateTextInput(session, "companyCountry", value=NA)
    updateTextInput(session, "reportStart", value=NA)
    updateTextInput(session, "reportEnd", value=NA)
    updateTextInput(session, "openCorp", value=NA)
  })
  
  ####################################################################################################################################################################################################
  #     Load functions
  
  ####################################################################################################################################################################################################
  
  observeEvent(input$urlLoad, {
    
    hide("pickTable")
    hide("reset")
    
    checkSourcePush <<- FALSE
    
    if(input$url=="" | input$url=="INPUT URL"){
      addClass("url", "red")
      showNotification("Input a URL", duration=3, type="error")
      
    } else {
      removeClass("url","red")
      url <- gsub(" ", "", input$url)
      
      checkOut <- checkURL(url)
      
      if(checkOut%in%c("That url doesn't exist","You need to authenticate!","You made a mistake!","The server screwed up")) {
        print("Didn't pass URL check")
        showNotification(checkOut, duration=3, type="error")
      } else {
        
        #if(grepl(".pdf", url)) {
        pdf_folder <<- "pdf_folder"
        if(!file.exists(pdf_folder))
          dir.create("pdf_folder")
        temp <- tempfile(fileext = ".pdf", tmpdir = "pdf_folder")
        download.file(url, temp, mode = "wb")
        addResourcePath("pdf_folder", pdf_folder)
          
        output$pdfOut <- renderUI({
          tags$iframe(src=temp, style="height:800px; width:100%")
        })
        #}
        updateTabsetPanel(session, "tabset", selected="Add report")
        updateTabsetPanel(session, "addTabset", selected="Metadata")
        updateTextInput(session, "sourceURL", value=url)
        
        if(grepl(".com", url)==TRUE) {
          company_url <- substr(url, 1, regexpr(".com", url)+3)
        } else if(grepl(".ca", url)) {
          company_url <- substr(url, 1, regexpr(".ca", url)+2)
        } else{
          company_url <- ""
        }
        
        scrapeTrue <<- TRUE
        str(temp)
        pdfPath <<- temp
        updateTextInput(session, "companyURL", value=company_url)
        updateTextInput(session, "companyName", value=outTable[SourceURL==url]$Company)
        
        show("pageScrapeNum")
        show("pageScrape")
        
        show("deleteRowButton")
        show("changeHeaderButton")
        show("meltColumns")
        show("deleteColButton")
        show("doRow")
        show("newGov")
        show("newProj")
      }
    }
  })

########### 
  
  observeEvent(input$urlView, {
    hide("pickTable")
    hide("reset")
    hide("pageScrapeNum")
    hide("pageScrape")
    
    scrapeTrue <<- FALSE
    checkSourcePush <<- FALSE
    
    if(input$url=="" | input$url=="INPUT URL"){
      addClass("url", "red")
      showNotification("Input a URL", duration=10, type="error")
    } else {
      removeClass("url", "red")
      url <- gsub(" ", "", input$url)
      
      checkOut <- checkURL(url)
      
      if(checkOut%in%c("That url doesn't exist","You need to authenticate!","You made a mistake!","The server screwed up")) {
        print("Didn't pass URL check")
        showNotification(checkOut, duration=3, type="error")
      } else {
      
        print(paste("URL:", url))
        output$pdfOut <- renderUI({
          tags$iframe(src=url, style="height:800px; width:100%")
        })
        
         updateTabsetPanel(session, "tabset", selected="Add report")
         updateTabsetPanel(session, "addTabset", selected="Metadata")
        updateTextInput(session, "sourceURL", value=url)
  
        if(grepl(".com", url)==TRUE) {
          company_url <- substr(url, 1, regexpr(".com", url)+3)
        } else if(grepl(".ca", url)==TRUE) {
          company_url <- substr(url, 1, regexpr(".ca", url)+2)
        } else{
          company_url <- ""
        }
  
        updateTextInput(session, "companyURL", value=company_url)
        
        show("deleteRowButton")
        show("changeHeaderButton")
        show("meltColumns")
        show("deleteColButton")
        show("doRow")
        show("newGov")
        show("newProj")
      }
    }
  })
  
###########
  
  observeEvent(input$urlLoadScrape, {
    hide("pageScrapeNum")
    hide("pageScrape")
    
    scrapeTrue <<- FALSE
    checkSourcePush <<- FALSE
    
    if(input$url=="" | input$url=="INPUT URL"){
      addClass("url", "red")
      showNotification("Input a URL", duration=3, type="error")
    } else {
        removeClass("url", "red")
        url <- gsub("\n", "", input$url)
        url <- gsub(" ", "", input$url)
        
        checkOut <- checkURL(url)
        
        if(checkOut%in%c("That url doesn't exist","You need to authenticate!","You made a mistake!","The server screwed up")) {
          print("Didn't pass URL check")
          showNotification(checkOut, duration=3, type="error")
        } else {
          pdf_folder <- "pdf_folder"
      
          if(!file.exists(pdf_folder))
            dir.create("pdf_folder")
          temp <- tempfile(fileext = ".pdf", tmpdir = "pdf_folder")
          download.file(url, temp, mode = "wb")
          addResourcePath("pdf_folder", pdf_folder)
          
          output$pdfOut <- renderUI({
            tags$iframe(src=temp, style="height:800px; width:100%")
            })
          
          updateTabsetPanel(session, "tabset", selected="Add report")
          updateTabsetPanel(session, "addTabset", selected="Metadata")
          
            tables$df <- extract_tables(temp, widget='reduced')
            tables$textPage <- extract_text(temp, pages=1)
            tables$tableTextPage <- extract_text(temp, pages=c(2,3))
            
            updateTextInput(session, "reportStart", value=gsub(" ", "", substr(tables$textPage, regexpr("From: ", tables$textPage)+6, regexpr("To:", tables$textPage)-1)))
            updateTextInput(session, "reportEnd", value=gsub(" ", "", substr(tables$textPage, regexpr("To:", tables$textPage)+4, regexpr('\n', tables$textPage)-1)))
            updateTextInput(session, "sourceDate", value=gsub("[\r\n,:, ,^a-zA-Z]", "", substr(tables$textPage, regexpr("Date:", tables$textPage)+4, regexpr("Date:", tables$textPage)+18)))
            updateTextInput(session, "sourceID", value=substr(tables$textPage, regexpr("E[0-9]{6}", tables$textPage), regexpr("E[0-9]{6}", tables$textPage)+6))
            updateTextInput(session, "sourceURL", value=url)
            
            if(grepl(".com", url)==TRUE) {
              company_url <- substr(url, 1, regexpr(".com", url)+3)
              } else if(grep(".ca", url)) {
                company_url <- substr(url, 1, regexpr(".ca", url)+2)
                } else{
                  company_url <- ""
                  }
            
            updateTextInput(session, "companyURL", value=company_url)
            nm1 <- substr(tables$textPage, regexpr("Extractive Sector Transparency Measures Act Report\r\n", tables$textPage)+52, nchar(tables$textPage))
            nm2 <- gsub("[.,\r]","", substr(nm1, 0, regexpr("\r\n", nm1)))
            updateTextInput(session, "companyName", value=outTable[SourceURL==url]$Company)
            updateSelectInput(session, "currency", selected="Canada Dollar (CAD)")
            
            show("pickTable")
            show("reset")
            
            show("deleteRowButton")
            show("changeHeaderButton")
            show("meltColumns")
            show("deleteColButton")
            show("doRow")
            show("newGov")
            show("newProj")
        }
       }
    })
  
  
  ################
  #Pick table to work on
  output$pickTable <- renderUI({
    selectInput("tableSelect", "Pick table", choices=1:length(tables$df), selected=NA)
  })
  
  ################
  #Table reset button
  observeEvent(input$reset, {
    
    req(length(tables$df)>0)
    
    val <- as.numeric(input$tableSelect)
    
    temp <- as.data.table(tables$df[[val]])
    
    if(any(unlist(temp[1])[unlist(temp[1]!="")]%in%c("Payments by Project","Payments by Payee"))){
      temp <- temp[-1]
    }
    
    temp <- temp[,sapply(temp, function(x) {!all(x%in%c("","$","-"," "))}), with=FALSE]
    
    current$current <- temp
    
    str(current$current)
    
    updateTabsetPanel(session, "tabset", selected="Add report")
    updateTabsetPanel(session, "addTabset", selected="export")
  })
  ################
  #Blank table button
  observeEvent(input$newGov, {
    updateTabsetPanel(session, "tabset", selected="Add report")
    updateTabsetPanel(session, "addTabset", selected="Edit table")
    
    #if(input$newGov%%2==0) {
      current$current <- data.table(Country=rep("", 10), "Payee Name"="", Taxes="", Royalties="", Fees="", 
                                  "Production Entitlements"="", Bonuses="", Dividends="", "Infrastructure Improvement Payments"="", Notes="")
    #} else {
    #  current$current <- data.table(Country=rep("", 10), "Project Name"="", Taxes="", Royalties="", Fees="", 
    #                                "Production Entitlements"="", Bonuses="", Dividends="", "Infrastructure Improvement Payments"="", Notes="")
      
    #}
  })
  observeEvent(input$newProj, {
    updateTabsetPanel(session, "tabset", selected="Add report")
    updateTabsetPanel(session, "addTabset", selected="Edit table")
    current$current <- data.table(Country=rep("", 10), "Project Name"="", Taxes="", Royalties="", Fees="", 
                                    "Production Entitlements"="", Bonuses="", Dividends="", "Infrastructure Improvement Payments"="", Notes="")
    
  })

  ####################################################################################################################################################################################################
  #     Scrape functions
  
  ####################################################################################################################################################################################################
  
  
  observeEvent(input$pageScrape, {
    if(scrapeTrue==TRUE){
      addResourcePath("pdf_folder", pdf_folder)
      
      
      print(file.exists(pdfPath))
      
      tables$df <- extract_tables(pdfPath, widget="reduced", pages=input$pageScrapeNum)
      
      print(paste("Length:", length(tables$df)))
      #str(as.data.table(tables$df[[1]]))
      
      if(length(tables$df)>0){
        temp <- as.data.table(tables$df[[1]])
        temp <- temp[,sapply(temp, function(x) {!all(x%in%c("","$","-"," "))}), with=FALSE]
        current$current <- temp
        updateTabsetPanel(session, "tabset", selected="Add report")
        updateTabsetPanel(session, "addTabset", selected="Edit table")
      } else {
        showNotification("Invalid data", duration=3, type="error")
      }
      
    } else {
      showNotification("Invalid option", duration=3, type="error")
    }
    
  })
  
  
    
  ####################################################################################################################################################################################################
  #     Information tab functions
  
  ####################################################################################################################################################################################################
  
  
  slLink <- "https://docs.google.com/spreadsheets/d/14s79csLQ-JYPkZBy6nJ7O1Gy6r9V2xosFltIqNnLjjY/pub?gid=0&single=true&output=csv"
  
  outTable <- read.csv(slLink, stringsAsFactors=FALSE)
  setDT(outTable)
  
  outTable[, Link:=paste0("<a target='_blank' href='", SourceURL,"'>Link</a>")]
  outTable <- outTable[, c(1:9,27)]
  
  observeEvent(input$loadSourcelist, {
    
    hide("loadSourcelist")
    output$sourcelistPDF <- renderTable({
      outTable[Scraped.==0, c(1:10)][Format=="PDF"][, c("Company","Link","SourceType","Format","Jurisdiction","Added","Added.by","Scraped.")]
      }, sanitize.text.function = function(x) x)
    
    output$sourcelistExcel <- renderTable({
      outTable[Scraped.==0, c(1:10)][Format=="Excel"][, c("Company","Link","SourceType","Format","Jurisdiction","Added","Added.by","Scraped.")]
      }, sanitize.text.function = function(x) x)
    
    output$sourcelistTBD <- renderTable({
      outTable[Scraped.==0, c(1:10)][Format=="TBD"][, c("Company","Link","SourceType","Format","Jurisdiction","Added","Added.by","Scraped.")]
      }, sanitize.text.function = function(x) x)
    
  })
  
  
  
  ####################################################################################################################################################################################################
  #     Row functions
  
  ####################################################################################################################################################################################################
  
  
  observeEvent(input$deleteRowButton, {
    rows <- as.numeric(unlist(strsplit(input$doRow,",")))
    req(all(is.na(rows)!=TRUE))
    
    if(any(rows>nrow(current$current))) {
      showNotification("Invalid columns", duration=3, type="error")
    } else {
      temp <- current$current[-rows,]
      current$current <- temp
    }
  })
  
  observeEvent(input$changeHeaderButton , {
    req(current$current)
    req(input$doRow)
    req(names(current$current))
    rows <- as.numeric(input$doRow)
    temp <- current$current
    newNames <- gsub("^$", "x", unlist(current$current[rows]))#unlist(current$current[rows])
    newNames[newNames=="NA"] <- "x"
    names(temp) <- newNames#gsub("^$", "x", unlist(current$current[rows]))#unlist(current$current[rows])
    if(!("Country"%in%newNames)) {
      temp <- cbind(data.table(Country=NA), temp)
    }
    if(!("Notes"%in%newNames)) {
      temp <- cbind(temp, data.table(Notes=NA))
    }
    current$current <- temp[-rows,]
  })
  
  
  
  ####################################################################################################################################################################################################
  #     Column functions
  
  ####################################################################################################################################################################################################
  
  observeEvent(input$deleteColButton, {
    if(input$meltColumns==""){showNotification("Add column number", duration=3, type="error")}
    req(input$meltColumns)
    cols <- as.numeric(unlist(strsplit(input$meltColumns,",")))
    if(any(is.na(cols))) {
      showNotification("Invalid column(s)", duration=3, type="error")
    } else {
      if(any(cols>length(current$current))) {
        showNotification("Invalid column(s)", duration=3, type="error")
        } else {
          temp <- current$current[,-cols, with=FALSE]
          current$current <- temp
        }
    }
  })
  
  observeEvent(input$melt, {
    req(current$current)
    str(current$current)
    temp <- current$current[,-c("x", "Total Amount paid to Payee","Total Amount paid by Project", "Total Amount paid by Project Notes", "Total Amount paid to Payee Notes", "Total")]
    print("Just made temp df")
    req(names(temp))
    
    if(input$companyName==""){
      showNotification("Add company name", duration=3, type="error")
      addClass("companyName", "red")
      updateTabsetPanel(session, "tabset", selected="Add report")
      updateTabsetPanel(session, "addTabset", selected="Metadata")
    }
    if(input$sourceID==""){
      showNotification("Add source ID", duration=3, type="error")
      addClass("sourceID", "red")
      updateTabsetPanel(session, "tabset", selected="Add report")
      updateTabsetPanel(session, "addTabset", selected="Metadata")
    }
    
    req(input$companyName)
    req(input$sourceID)
    
    removeClass("companyName", "red")
    removeClass("sourceID", "red")
    
    
    if(all(c("Country", "Notes","Payment type","Value","Company","id")%in%names(temp))) {
      req(temp=="banana")
    }
    
    if(any(names(temp)%in%"Country")==FALSE){showNotification("Invalid column names", duration=3, type="error")}
    req(any(names(temp)%in%"Country"))
    
    temp <- temp[Country!=""]
    str(temp)
    req(nrow(temp[Country!=""])>0)
    
    if(any(names(temp)%in%c("Project Name", "Payee Name"))==FALSE){showNotification("Invalid column names", duration=3, type="error")}
    req(any(names(temp)%in%c("Project Name", "Payee Name")))
    
    if("Payee Name" %in% names(temp)) {
      temp <- temp[Country!=""]
      print("This far made it")
      temp <- temp[!is.na(`Payee Name`)]
      
      if(any((c("Country","Payee Name","Notes")%in%names(temp))!=TRUE)){
        showNotification("Invalid column names", duration=3, type="error")
      } else {
        cols2 <- names(temp[, -c("Country","Payee Name","Notes"), with=FALSE])
        
        for(i in 1:length(cols2)) {
          temp[,cols2[i]] <- as.numeric(gsub("[,$*]","", eval(parse(text=paste0('temp$`', cols2[i],'`')))))
        }
        temp <- melt(temp, id.vars=c("Country","Payee Name","Notes"), variable.name="Payment type", value.name="Value", na.rm=TRUE)
        temp[, c("Company","id"):=list(c(input$companyName), c(input$sourceID))]
        temp[, Value := Value*as.numeric(input$multiplier)]
        cat("error here4")
        current$current <- temp
        cat("error 5")
      }
    } 
    
    if("Project Name" %in% names(temp)) {
      temp <- temp[Country!=""]
      temp <- temp[!is.na(`Project Name`)]
      
      if(any((c("Country","Project Name","Notes")%in%names(temp))!=TRUE)){
        showNotification("Invalid column names", duration=3, type="error")
      } else {
        print("check check")
        cols2 <- names(temp[, -c("Country","Project Name","Notes"), with=FALSE])
        
        for(i in 1:length(cols2)) {
          temp[,cols2[i]] <- as.numeric(gsub("[,$*]","", eval(parse(text=paste0('temp$`', cols2[i],'`')))))
        }
       
        temp <- melt(temp, id.vars=c("Country","Project Name","Notes"), variable.name="Payment type", value.name="Value", na.rm=TRUE)
        temp[, c("Company","id"):=list(c(input$companyName), c(input$sourceID))]
        current$current <- temp
      }
    }
    
    #}
  })
  ####################################################################################################################################################################################################
  #     handsontable functions
  
  ####################################################################################################################################################################################################
  
  
  observe({
    hot = input$hot #isolate(input$hot)
    if (!is.null(hot)) {
      current$current <- hot_to_r(input$hot)
    }
  })
  
  
  output$hot = renderRHandsontable({
    rhandsontable(current$current, useTypes = FALSE) %>%
      hot_table(highlightCol = TRUE, highlightRow = TRUE)
  })
  
  
  ####################################################################################################################################################################################################
  #      Output functions
  
  ####################################################################################################################################################################################################
  
  #output$tableout <- renderRHandsontable({current$current})
  output$tableout <- renderTable({current$current}, rownames=TRUE, striped=TRUE, bordered=TRUE)
  
  #output$metaTextOut <- renderText({tables$textPage})
  
  #output$tableTextOut <- renderText({tables$tableTextPage})
  
})
