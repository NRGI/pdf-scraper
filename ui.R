library(shiny)
library(shinyjs)
library(rhandsontable)

shinyUI(fluidPage(
  useShinyjs(),
  inlineCSS(list(.red = "background: #ffc7c7")),
  
  fluidRow(column(width=2,
                  fluidRow(
                    #column(width=6, textInput("pages", label="Pages", value='All')),
                    column(width=12, textInput("url", label="Insert URL", width="100%"))
                    ),
                  fluidRow(
                    column(width=4, actionButton("urlLoadScrape", label="ESTMA", value="")),
                    column(width=4, actionButton("urlLoad", label="Download", value="")),
                    column(width=4, actionButton("urlView", label="View", value=""))
                    )
                  ),
           column(width=2,
                  fluidRow(
                    column(width=12, uiOutput("pickTable"),
                           numericInput("pageScrapeNum", label="Scrape from page", value=NULL))
                    ),
                  fluidRow(
                    column(width=4, actionButton("reset", label="Reset"),
                           actionButton("pageScrape", label="Scrape table")),
                    column(width=4, actionButton("newGov", label="Govt")),
                    column(width=4, actionButton("newProj", label="Project"))
                    )
                  ),
           column(width=2,#h5("Row Actions"),
                  fluidRow(
                    column(width=12, textInput("doRow", label="Select rows (separate with comma)", value=1))
                    ),
                  fluidRow(
                    column(width=5, actionButton("deleteRowButton", label="Remove row")),
                    column(width=7, actionButton("changeHeaderButton", label="Set as column headers"))
                    )
                  ),
           column(width=2,
                  #h5("Column Actions"),
                  textInput("meltColumns", label="Select columns (separate with comma)", value=NULL),
                  actionButton("deleteColButton", label="Remove column")
                  ),
           column(width=1,# h3("Push"),
                  actionButton("melt", label="Reshape data"),
                  actionButton("addToMaster", label="Add to master"),
                  actionButton("newSheetPush", label="Push to new sheet"),
                  actionButton("addToRemote", label="Add to database")
                  ),
            column(width=2,
                   #numericInput("pageScrapeNum", label="Scrape from page", value=NULL),
                   #actionButton("pageScrape", label="Scrape table"),
                   actionButton("hidePanel", label="Hide view panel"),
                   actionButton("showPanel", label="Show view panel")
           
           )
           ),
  fluidRow(
    column(width=6,
           tabsetPanel(
             id='tabset',
             tabPanel(title="Reports",
                      tabsetPanel(id='infoTabset',
                                  tabPanel(title="ESTMA",
                                           uiOutput("ui"),
                                           tableOutput("pdfTable")
                                  ),
                                  tabPanel(title="Sourcelist",
                                           uiOutput("sourcelist"),
                                           tableOutput("sourcelistTable")
                                           )
                                  )
                     
                      #dataTableOutput("pdfTable")
                      ),
             tabPanel(title="Add report",
                      tabsetPanel(id="addTabset",
                                  tabPanel(title="Metadata",
                                           fluidRow(
                                             column(4,
                                                    textInput("sourceName", label="Source name"),
                                                    textInput("sourceID", label="Source ID Number"),
                                                    textInput("sourceURL", label="Source URL"),
                                                    textInput("sourceDate", label="Source date (YYYY-MM-DD)"),
                                                    actionButton("clearMeta", label="Clear all fields")
                                             ),
                                             column(4,
                                                    textInput("companyName", label="Company name"),
                                                    textInput("companyURL", label="Company website"),
                                                    textInput("companyCountry", label="Company country"),
                                                    textInput("reportStart", label="Report start date (YYYY-MM-DD)"),
                                                    textInput("reportEnd", label="Report end date (YYYY-MM-DD)")
                                             ),
                                             column(4,
                                                    uiOutput("currencyOut"),
                                                    selectInput("multiplier", label="Currency multiplier", choices=c("None"=1, "Tens"=10, "Hundreds"=100,
                                                                                                                     "Thousands"=1000, "Millions"=1000000)),
                                                    textInput("openCorp", label="OpenCorporates URL"),
                                                    selectInput("sourceType", label="Source type", choices=c("Extractive Sector Transparency Measures Act Report","Others"))
                                             )
                                           )
                                  ),
                                  tabPanel(title="Edit table",
                                           textInput("nada", label=NULL, value=NULL, width="100%"),
                                           rHandsontableOutput('hot')
                                           ),
                                  tabPanel(title="Export",
                                           value="export",
                                           tableOutput("tableout")
                                           #actionButton("addToMaster", label="Add to master")
                                           )
                                  )
                      ),
             
             # tabPanel(title="Metadata",
             #          fluidRow(
             #            column(4,
             #                   textInput("sourceName", label="Source name"),
             #                   textInput("sourceID", label="Source ID Number"),
             #                   textInput("sourceURL", label="Source URL"),
             #                   textInput("sourceDate", label="Source date (YYYY-MM-DD)"),
             #                   actionButton("clearMeta", label="Clear all fields")
             #                   ),
             #            column(4,
             #                   textInput("companyName", label="Company name"),
             #                   textInput("companyURL", label="Company website"),
             #                   textInput("companyCountry", label="Company country"),
             #                   textInput("reportStart", label="Report start date (YYYY-MM-DD)"),
             #                   textInput("reportEnd", label="Report end date (YYYY-MM-DD)")
             #                   ),
             #            column(4,
             #                   uiOutput("currencyOut"),
             #                   selectInput("multiplier", label="Currency multiplier", choices=c("None"=1, "Tens"=10, "Hundreds"=100,
             #                                                                                    "Thousands"=1000, "Millions"=1000000)),
             #                   textInput("openCorp", label="OpenCorporates URL"),
             #                   selectInput("sourceType", label="Source type", choices=c("Extractive Sector Transparency Measures Act Report","Others"))
             #                   )
             #            )
             #          ),
             # tabPanel(title="Export",
             #          value="export",
             #          tableOutput("tableout")
             #          #actionButton("addToMaster", label="Add to master")
             #          ),
             # tabPanel(title="Edit table",
             #          textInput("nada", label=NULL, value=HTML("Use this space to paste multi-line values copied from the pdf before pasting into the table"), width="100%"),
             #          rHandsontableOutput('hot')
             #          ),
             tabPanel(title="Master",
                      tabsetPanel(id="addTabset",
                                  tabPanel(title="Gov. Master",
                                           tableOutput("masterGovOut"),
                                           #actionButton("writeGovBtn", label="Write to CSV")
                                           downloadButton("writeGovtBtn", label="Download file")
                                           ),
                                  tabPanel(title="Project Master",
                                           tableOutput("masterProjectOut"),
                                           #actionButton("writeProjectBtn", label="Write to CSV")
                                           downloadButton("writeProjectBtn", label="Download file")
                                           ),
                                  tabPanel(title="Source Master",
                                           tableOutput("masterSource"),
                                           #actionButton("writeSourceBtn", label="Write to CSV")
                                           downloadButton("writeSourceBtn", label="Download file")
                                           )
                                  )
                      )
                                  
             # tabPanel(title="Gov. Master",
             #          tableOutput("masterGovOut"),
             #          #actionButton("writeGovBtn", label="Write to CSV")
             #          downloadButton("writeGovtBtn", label="Download file")
             #          ),
             # tabPanel(title="Project Master",
             #          tableOutput("masterProjectOut"),
             #          #actionButton("writeProjectBtn", label="Write to CSV")
             #          downloadButton("writeProjectBtn", label="Download file")
             #          ),
             # tabPanel(title="Source Master",
             #          tableOutput("masterSource"),
             #          #actionButton("writeSourceBtn", label="Write to CSV")
             #          downloadButton("writeSourceBtn", label="Download file")
             #          )
             # )
             )
           ),
    
        column(width=6,
               #conditionalPanel("input.hidePanel%2==0", htmlOutput("pdfOut"))
               htmlOutput("pdfOut")
               )
    )
  )
)
