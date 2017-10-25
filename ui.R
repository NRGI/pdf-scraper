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
                 "#logo" = "height:65px; margin-top:-2%; margin-left:0%"#,
                 # "body" = "background: url(tabula.png) bottom left no-repeat fixed; background-size: 80px; background-position: 1% 99%"
                 )
  ),
  tags$link(rel = "stylesheet", type = "text/css", href = "scraper.css"),
  tags$head(tags$link(rel="shortcut icon", href="favicon.ico", type="image/x-icon")),
  tags$head(tags$script( async="", src=paste0("https://www.googletagmanager.com/gtag/js?id=", ga_path))),
  tags$head(tags$script(
                        paste0(' 
                        window.dataLayer = window.dataLayer || [];
                        function gtag(){dataLayer.push(arguments);}
                        gtag("js", new Date());
                      
                        gtag("config", "', ga_path,'");

                        $(document).on("click", "#downloadButton", function() {
                          gtag("event", "button_click", {
                            "event_action": "load pdf"
                          });
                          console.log("load pdf")
                        });

                        $(document).on("click", "#fileDownload", function() {
                          gtag("event", "button_click", {
                            "event_action": "download csv"
                               });
                          console.log("download")
                        });
                        
                                 '))),
  
  tags$head(tags$script('
                        var dimension = [0, 0];
                        $(document).on("shiny:connected", function(e) {
                        dimension[0] = window.innerWidth;
                        dimension[1] = window.innerHeight;
                        $("label").remove();
                        Shiny.onInputChange("dimension", dimension);
                        });
                        $(window).resize(function(e) {
                        dimension[0] = window.innerWidth;
                        dimension[1] = window.innerHeight;
                        Shiny.onInputChange("dimension", dimension);
                        });
                        ')),
  tags$head(tags$link(href="https://fonts.googleapis.com/css?family=Open+Sans", rel="stylesheet")),
  tags$head(tags$title("NRGI PDF Table Extractor")),
  
  div(id="links",
      p("Made possible by:", id="links-text"),
      a(img(src="tabula.png", id='logo'),target="_blank", href="http://tabula.technology/"),
      a(img(src="ropensci.png", id='logo'),target="_blank", href="https://ropensci.org/", style="margin-left:10px")),
  
  column(width=6,
         fluidRow(column(width=3, a(img(src="nrgi_logo.jpg", id='logo'),target="_blank", href="https://resourcegovernance.org/"), style="padding-top:50px; padding-left:50px; padding-bottom:10px"),
                  column(width=9, h3("PDF Table Extractor"), style="padding-top:50px")),
         # div(style="display:inline-block", #width="200px",
         #     a(img(src="nrgi_logo.png", id='logo'),href="https://resourcegovernance.org/")),
         # div(style="display:inline-block",
         #     h2("PDF Table Scraper")),
         
         
         # h2(a(img(src="nrgi_logo.png", id='logo'),href="https://resourcegovernance.org/"), "PDF Table Scraper"),
         # img(src="nrgi_logo.jpg", id="logo", href="https://resourcegovernance.org/"),#, bottom="0", left="0", height="100px", position="fixed")
         # h4("PDF Table Scraper"),
         # fileInput("fileUp", label="Upload a file"),
         
         column(width=12,
                id="text-row",
                p("Use this tool to produce structured, machine-readable tables from static PDF reports in a few clicks. Load a 
                   PDF into the app and extract tables in the browser, ready for export to CSV format. See the source code
                   and instructions", a("here.", href="https://github.com/NRGI/ptg-scraper", target="_blank")
                ),
                  
                
                div(style="display:inline-block", 
                    textInput("downloadURL", label="", placeholder = "Insert PDF URL")),
                div(style="display:inline-block",
                    actionButton("downloadButton", label="Load"))#,
                # bsTooltip("downloadButton", placement = "top", trigger="hover", title="Download a PDF for scraping. URL must point directly to the PDF.")
         ),
         column(width=12,
                id="scrapeRow",
                div(style="display:inline-block", width="100px",
                    textInput("pageNumber", label="", placeholder = 'Page(s). For multiple: "1,2,7" or "5:10"')),
                div(style="display:inline-block",
                    actionButton("scrapeButton", label="Scrape")),
                div(style="display:inline-block",
                    actionButton("drawButton", label="Custom scrape")),
                div(style="display:inline-block",
                    downloadButton("fileDownload", "Download")),
                bsTooltip("scrapeButton", placement = "top", trigger="hover", title="Click here to auto detect the table on the page(s)."),
                bsTooltip("drawButton", placement = "top", trigger="hover", title="Click here to drag a rectangle around the table in your PDF. Works one page at a time.")
         ),
         
         rHandsontableOutput("hot")
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
