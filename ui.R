library(shiny)
library(ggplot2)
library(data.table)

shinyUI(pageWithSidebar(
    
    # Application title
    headerPanel("Michigan Educational Financial Data"),
    
    # Sidebar with a select box input for year
    sidebarPanel( 
        a("Bulletin 1014 Layout 2004-2012", href="http://www.michigan.gov/documents/b1014_04_doc_128274_7.pdf", target = "_blank"),
        br(),
        
        # Tab 1: Summary
#         conditionalPanel(condition = "input.tabs == 'Summary'"    
#                          # Other useful links ???                      
#          ),
        
        # Tab 2: District Comparison
        conditionalPanel(condition = "input.tabs == 'District Comparison'",
                         wellPanel(
                             selectInput("year", "Select year for district comparison",
                                         choices = 2004:2012,
                                         selected = 2012
                             )#,
                             
#                              uiOutput("outputSelecter.District1"), # district1 selection menu. "" is default.
#                              uiOutput("outputSelecter.District2") # district2 selection menu. "" is default.  
                             
                             # show choropleth plot
                             ## add slider if checked, and plot
                         )

        ),        
        
        # Tab 3: County Comparison
        conditionalPanel(condition = "input.tabs == 'County Comparison'",
                         wellPanel(
                             selectInput("year", "Select year for county comparison",
                                         choices = 2004:2012,
                                         selected = 2012
                             ),
    
                             uiOutput("outputSelecter.County1"), # county1 selection menu. "ALCONA" is default.
                             uiOutput("outputSelecter.County2") # county2 selection menu. "ALCONA" is default.  
                             
                             # show choropleth plot
                             ## add slider if checked, and plot
                         )
        ),
        
        # Tab 4: Explore Bulletin1014
        conditionalPanel(condition = "input.tabs == 'Explore Bulletin1014'",
                         a("Bulletin 1014 Home (Michigan Department of Education)", href="http://www.michigan.gov/mde/0,1607,7-140-6530_6605-21514--,00.html", target = "_blank"),
                         br(),
                         downloadButton("download.1014", label = "Download Bulletin 1014 Dataset (2004-2012)")                
        )
               
    ),
   
    mainPanel(
        tags$head(
            tags$link(rel = 'stylesheet',
                       type = 'text/css',
                       href = 'MI_ed.css')),
        tabsetPanel(id = "tabs",
                    
            tabPanel("Summary",
                     h3("Statewide Education Finances, inflation-adjusted"),
                     plotOutput("stateTotals.plot", height="700px", width="600px"),
                     tableOutput("stateTotals.dt") # put these in a column format; make prettier
                     
                     # explanatory text
                     ),
            
            tabPanel("District Comparison",
                     h3("District Comparison, inflation-adjusted")#,
#                      tableOutput("district.comp.table")
#                      plotOutput("MI.district.choro.map", height="800px")
                     ),   
            
            tabPanel("County Comparison",
                     h3("County Comparison, inflation-adjusted"), 
                     h4(textOutput("year.header")),
                     tableOutput("county.comp.table")
#                      plotOutput("MI.county.choro.map", height="800px")
                     ), 
            
            tabPanel("Explore Bulletin1014",
                     h3("Bulletin 1014 (2004-2012), not adjusted for inflation."),
                     dataTableOutput("bulletin1014.full.dt")
            )
            
        )                
    )   
))
