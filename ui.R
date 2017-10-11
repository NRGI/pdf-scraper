library(shiny)
library(tabulizer)
library(data.table)
library(rhandsontable)
library(shinyjs)
library(shinyBS)
library(shinythemes)


shinyUI(fluidPage(
  theme=shinytheme("paper"),
  useShinyjs(),
  inlineCSS(list(".red" = "background: #ffc7c7",
                 ".blue" = "background: #6d9eed",
                 ".pdf" = "position:fixed; width:49%; height:200px",
                 "#logo" = "height:75px; margin-top:-2%; margin-left:0%"
                 # "body" = "background: url(nrgi_logo.jpg) bottom left no-repeat fixed; background-size: 180px; background-position: 1% 99%"
                 )
  ),
  
  tags$head(tags$script('
                        var dimension = [0, 0];
                        $(document).on("shiny:connected", function(e) {
                        dimension[0] = window.innerWidth;
                        dimension[1] = window.innerHeight;
                        Shiny.onInputChange("dimension", dimension);
                        });
                        $(window).resize(function(e) {
                        dimension[0] = window.innerWidth;
                        dimension[1] = window.innerHeight;
                        Shiny.onInputChange("dimension", dimension);
                        });
                        ')),
  
  column(width=6,
         h2(a(img(src="nrgi_logo.png", id='logo'),href="https://resourcegovernance.org/"), "PDF Table Scraper"),
         # img(src="nrgi_logo.jpg", id="logo", href="https://resourcegovernance.org/"),#, bottom="0", left="0", height="100px", position="fixed")
         # h4("PDF Table Scraper"),
         # fileInput("fileUp", label="Upload a file"),
         
         column(width=12,
                p("Use this tool to extract structured, machine-readable tables from PDF reports in a few clicks. Simply download a PDF into the app, 
                  select the pages with tables to extract and see the extracted data in your browser, ready for export to CSV.",
                  br(),
                  "This tool was made possible thanks to the open-source efforts of ",
                  a("Tabula", href="http://tabula.technology/", target="_blank"),
                  "and ",
                  a("rOpenSci", href="https://ropensci.org/", target="_blank"),
                  ". See the source code ",
                  a("here", href="https://github.com/NRGI/ptg-scraper", target="_blank")
                ),
                  
                
                div(style="display:inline-block", 
                    textInput("downloadURL", label="", placeholder = "Insert URL")),
                div(style="display:inline-block",
                    actionButton("downloadButton", label="Download")),
                bsTooltip("downloadButton", placement = "top", trigger="hover", title="Download a PDF for scraping. URL must point directly to the PDF.")
         ),
         column(width=12,
                id="scrapeRow",
                div(style="display:inline-block", width="200px",
                    textInput("pageNumber", label="", placeholder = 'Page(s). For multiple: "1,2,7" or "5:10"')),
                div(style="display:inline-block",
                    actionButton("scrapeButton", label="Scrape")),
                div(style="display:inline-block",
                    actionButton("drawButton", label="Custom scrape")),
                div(style="display:inline-block",
                    downloadButton("fileDownload", "Download CSV")),
                bsTooltip("scrapeButton", placement = "top", trigger="hover", title="Click here to auto detect the table on the page(s)."),
                bsTooltip("drawButton", placement = "top", trigger="hover", title="Click here to drag a rectangle around the table in your PDF. Works one page at a time.")
         ),
         
         rHandsontableOutput("hot")#,
         # img(src="nrgi_logo.jpg", id="logo")#, bottom="0", left="0", height="100px", position="fixed")
         ),
  
  column(width=6,
         style="height:100%",
         actionButton("done", label="Done"),
         # actionButton("other", label="Next page"),
         actionButton("cancel", label="Cancel"),
         plotOutput("plot", height = "800px", brush = shiny::brushOpts(id = "plot_brush")),
         htmlOutput("pdfOut", class="pdf")
  )
  )
  )
#)
