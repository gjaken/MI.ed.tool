library(shiny)
library(ggplot2)
library(data.table)

shinyUI(pageWithSidebar(
    
    # Application title
    headerPanel("Michigan Educational Financial Data"),
    
    # Sidebar with a select box input for year
    sidebarPanel( 
        p("Exploring Michigan Education Financial Data with Bulletin 1014."),
        br(),
        
        # Tab 1: Summary
#         conditionalPanel(condition = "input.tabs == 'Summary'"    
#                          # Other useful links ???                      
#          ),
        
        
        # Tab 3: County Comparison
        conditionalPanel(condition = "input.tabs == 'County Comparison'",
                         wellPanel(
                             selectInput("yearCounty", "Select year for county comparison",
                                         choices = 2004:2012,
                                         selected = 2012
                             ),
    
                             uiOutput("outputSelecter.County1"), # county1 selection menu. "ALCONA" is default.
                             uiOutput("outputSelecter.County2") # county2 selection menu. "ALCONA" is default.  
                         ),
                         
                         wellPanel(
                             checkboxInput("showPlotCounty", "Show County Choropleth Plot?", value = FALSE),
                             conditionalPanel(condition = "input.showPlotCounty",
                                              uiOutput("outputSliderCounty"), 
                                              
                                              selectInput("fldnm", "Select Financial Measure",
                                                          choices = c("Average Teacher Salary"   = "TCHR_SAL.AVG.COUNTY",
                                                                      "Expenditure per Pupil"    = "EXP.PER.PUPIL.COUNTY",
                                                                      "Revenue per Pupil"        = "REV.PER.PUPIL.COUNTY",                                    
                                                                      "Student/Teacher Ratio"    = "PUPIL.PER.TCHR.COUNTY"),
                                                          selected = "EXP.PER.PUPIL.COUNTY"
                                              )     
                             )
                         )
        ),
        
        # Tab 4: Explore Bulletin1014
        conditionalPanel(condition = "input.tabs == 'Explore Bulletin1014'",
                         a("Bulletin 1014 Layout 2004-2012", href="http://www.michigan.gov/documents/b1014_04_doc_128274_7.pdf", target = "_blank"),
                         br(),
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
            
            tabPanel("County Comparison",
                     h3("County Comparison, inflation-adjusted"), 
                     h4(textOutput("year.header")),
                     tableOutput("county.comp.table"),
                     plotOutput("MI.county.choro.map")
                     ), 
            
            tabPanel("Explore Bulletin1014",
                     h3("Bulletin 1014 (2004-2012), not adjusted for inflation."),
                     dataTableOutput("bulletin1014.full.dt")
            )
            
        )                
    )   
))
