suppressPackageStartupMessages(library(shiny))
suppressPackageStartupMessages(library(data.table))
suppressPackageStartupMessages(library(rhandsontable))
suppressPackageStartupMessages(library(shinyjs))
suppressPackageStartupMessages(library(shinyBS))
suppressPackageStartupMessages(library(shinythemes))


shinyUI(fluidPage(
  theme=shinytheme("paper"),
  useShinyjs(),
  inlineCSS(list(".red" = "background: #ffc7c7",
                 ".blue" = "background: #6d9eed",
                 ".pdf" = "position:fixed; width:49%; height:200px",
                 "#logo" = "height:65px; margin-top:-2%; margin-left:0%"#,
                 # "body" = "background: url(tabula.png) bottom left no-repeat fixed; background-size: 80px; background-position: 1% 99%"
                 )
  ),
  tags$link(rel = "stylesheet", type = "text/css", href = "scraper.css"),
  tags$head(tags$meta(name="description", 
                      content="Convert PDF to Excel, CSV data in your browser in a few clicks. Supports multi-page scraping and auto-detection.")),
  tags$head(tags$link(rel="shortcut icon", href="favicon.ico", type="image/x-icon")),
  
  
  tags$head(tags$script('
                        var dimension = [0, 0];
                        $(document).on("shiny:connected", function(e) {
                        dimension[0] = window.innerWidth;
                        dimension[1] = window.innerHeight;
                        $("#uploadButton_progress").remove();
                        
                        Shiny.onInputChange("dimension", dimension);
                        });
                        
                        $(window).resize(function(e) {
                        dimension[0] = window.innerWidth;
                        dimension[1] = window.innerHeight;
                        Shiny.onInputChange("dimension", dimension);
                        });
                        ')),
  tags$head(tags$link(href="https://fonts.googleapis.com/css?family=Open+Sans", rel="stylesheet")),
  tags$head(tags$title("PDF Table Extractor")),
  
  div(id="links",
      div(
        p("Made possible by:", id="links-text"),
        a(img(src="tabula.png", id='logo'),target="_blank", href="http://tabula.technology/"),
        a(img(src="ropensci.png", id='logo'),target="_blank", href="https://ropensci.org/", style="margin-left:10px"),
        style="padding-bottom:5px"
      )
      ),
  
  
  column(width=6,
         # fluidRow(column(width=3, a(img(src="nrgi_logo.png", id='logo'),target="_blank", href="https://resourcegovernance.org/"), style="padding-top:20px"),
         #          column(width=9, h3("PDF Table Extractor"), style="padding-top:20px")),
         fluidRow(column(width=1, a(img(src="nrgi_logo.png", id='logo', height="66px"),target="_blank", href="https://resourcegovernance.org/"), style="padding-top:25px; padding-left:50px;"),
                  column(width=1),
                  column(width=9, h3("PDF Table Extractor"), style="padding-top:20px")),
         column(width=12,
                
                id="text-row",
                p("Use this tool to extract structured, machine-readable tables from PDF reports in a few clicks. Load a PDF into the app and 
                  extract tables right in the browser, ready for export to CSV. See the source code and
                  instructions", a("here.", href="https://github.com/NRGI/pdf-scraper", target="_blank")
                ),
                
                div(class="col-md-4 no-padding url-input",#style="display:inline-block",
                    textInput("downloadURL", label="", placeholder = "Insert URL for online PDF")),#, width="110px", style=""),
                div(class="col-md-2",#style="display:inline-block",
                    actionButton("downloadButton", label="Load URL"), style=""),
                div(class="col-md-2", id="uploadButton-div",#style="display:inline-block",
                    fileInput("uploadButton", label="", buttonLabel="Local source", placeholder="", accept=".pdf"), style=""),
                div(class="col-md-2",style="position:absolute; right:15px",
                    downloadButton("fileDownload", "Download")),
                bsTooltip("downloadButton", placement = "top", trigger="hover", title="Download a PDF from the web for scraping. URL must point directly to the PDF."),
                bsTooltip("uploadButton-div", placement = "top", trigger="hover", title="Upload a PDF from your computer for scraping. Size limit: 8mb")
         ),
         column(width=12,
                id="scrapeRow",
                div(class="col-md-6 no-padding url-input",
                    textInput("pageNumber", label="", placeholder = 'Page(s). For multiple: "1,2,7" or "5:10"')),
                div(class="col-md-2",#style="display:inline-block",
                    actionButton("scrapeButton", label="Scrape")),
                div(class="col-md-2",#style="display:inline-block",
                    actionButton("drawButton", label="Custom scrape")),
                bsTooltip("scrapeButton", placement = "top", trigger="hover", title="Click here to auto detect the table on the page(s)."),
                bsTooltip("drawButton", placement = "top", trigger="hover", title="Click here to drag a rectangle around the table in your PDF. Works one page at a time.")
         ),
         
         div(class="col-md-12", rHandsontableOutput("hot"))#,
         # img(src="nrgi_logo.jpg", id="logo")#, bottom="0", left="0", height="100px", position="fixed")
  ),
  
  column(width=6,
         style="height:100%",
         actionButton("done", label="Done"),
         actionButton("cancel", label="Cancel"),
         plotOutput("plot", height = "800px", brush = shiny::brushOpts(id = "plot_brush")),
         htmlOutput("pdfOut", class="pdf")
  )
  )
  )
#)
