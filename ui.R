library(shiny)
library(ggplot2)
library(data.table)

shinyUI(pageWithSidebar(
    
    # Application title
    headerPanel("Michigan Educational Financial Data"),
    
    # Sidebar with a select box input for year
    sidebarPanel( 
        h5("Exploring Michigan Education Financial Data with Bulletin 1014."),
        br(),
        
        # Tab 1: Summary
        conditionalPanel(condition = "input.tabs == 'Summary'",
                         HTML("<p>Bulletin 1014, put out each year by the Michigan Department of Education, is a core financial document for Michgian.<br><br>                            
                              Find Find out more about <a href='http://www.michigan.gov/mde/0,1607,7-140-6530_6605-21514--,00.html'>Bulletin 1014</a>.</p>"
                          )                         
         ),
        
        
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
                             checkboxInput("showPlotCounty", "Show County Choropleth Plot?", value = TRUE),
                             conditionalPanel(condition = "input.showPlotCounty",
                                              uiOutput("outputSliderCounty"), 
                                              
                                              selectInput("fldnm", "Select Financial Measure",
                                                          choices = c("Average Teacher Salary"   = "TCHR_SAL.AVG.COUNTY",
                                                                      "Expenditure per Pupil"    = "EXP.PER.PUPIL.COUNTY",
                                                                      "Revenue per Pupil"        = "REV.PER.PUPIL.COUNTY",                                    
                                                                      "Student/Teacher Ratio"    = "PUPIL.PER.TCHR.COUNTY"),
                                                          selected = "EXP.PER.PUPIL.COUNTY"
                                              ),
                                              
                                              p("County names appear in the center of the county.")
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
        ),
        
        HTML("<hr><p>This project brought to you by <a href='http://www.linkedin.com/pub/g-jake-nagel/10/36b/47'>Jake Nagel</a></p>")
               
    ),
   
    mainPanel(
        tags$head(
            tags$link(rel = 'stylesheet',
                       type = 'text/css',
                       href = 'MI_ed.css')),
        tabsetPanel(id = "tabs",
                    
            tabPanel("Summary",
                     h3("Annual Michigan Education Finances, inflation-adjusted"),
                     tableOutput("stateTotals.dt"),
                     plotOutput("stateTotals.plot", height="700px", width="600px")                                                              
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
