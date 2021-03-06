library(shiny)
library(ggplot2)
library(data.table)
library(reshape2)

# Read in dataset ---------------------------------------------------------

# bulletin1014.dt <- fread("bulletin1014.dt.csv")       # Note: NOT Adjusted for Inflation
bulletin1014.full.dt <- fread("bulletin1014.full.csv")  # Note: NOT Adjusted for Inflation
bulletin1014.county <- fread("bulletin1014.county.csv") # Note: Adjusted for Inflation
# MIcounty.map.dt <- fread("MIcounty.map.dt.csv")       # Note: Adjusted for Inflation
# setkey if it seems useful

# create totals data at state level
bulletin1014.state <- bulletin1014.county[, list(PUPIL.NUM.STATE = sum(PUPIL.NUM.COUNTY), 
                                                 TOTREV.STATE    = sum(TOTREV.COUNTY),
                                                 TOTEXP.STATE    = sum(TOTEXP.COUNTY),
                                                 TCHR.NUM.STATE  = sum(TCHR.NUM.COUNTY),
                                                 TCHR.SAL.STATE  = sum(TCHR.SAL.COUNTY)), 
                                          by = YEAR]

# create new ratio variables
bulletin1014.state[, `:=` (REV.PER.PUPIL.STATE     = TOTREV.STATE / PUPIL.NUM.STATE,
                           EXP.PER.PUPIL.STATE     = TOTEXP.STATE / PUPIL.NUM.STATE,
                           TCHR_SA.PER.PUPIL.STATE = TCHR.SAL.STATE / PUPIL.NUM.STATE,
                           TCHR_SAL.AVG.STATE      = TCHR.SAL.STATE / TCHR.NUM.STATE,
                           PUPIL.PER.TCHR.STATE    = PUPIL.NUM.STATE / TCHR.NUM.STATE)]

# shinyServer function ----------------------------------------------------
shinyServer(
    function(input, output) {
        
        MIcounty.map.reactive <- reactive({ #reactive function so that other functions are linked to this dataset changing        
            MIcounty.map.dt <- fread("MIcounty.map.dt.csv")         # Note: Adjusted for Inflation
            ## Round Data for County Map
            MIcounty.map.dt[, `:=` (EXP.PER.PUPIL.COUNTY  = round(EXP.PER.PUPIL.COUNTY,-2),
                                    REV.PER.PUPIL.COUNTY  = round(REV.PER.PUPIL.COUNTY,-2),
                                    TCHR_SAL.AVG.COUNTY   = round(TCHR_SAL.AVG.COUNTY,-2),
                                    PUPIL.PER.TCHR.COUNTY = round(PUPIL.PER.TCHR.COUNTY,0)
            )]
        })        

        # Tab 1: Statewide Table and Charts, annual data ----------------------------------------------------  
        output$stateTotals.dt <- renderTable({
            bulletin1014.state[, list(YEAR, "Revenue per Pupil" = REV.PER.PUPIL.STATE, "Expenditure per Pupil" = EXP.PER.PUPIL.STATE, "Teacher Salary per Pupil" = TCHR_SA.PER.PUPIL.STATE, "Average Teacher Salary" = TCHR_SAL.AVG.STATE, "Student / Teacher Ratio" = PUPIL.PER.TCHR.STATE)]
        }, include.rownames=FALSE)
        
        output$stateTotals.plot <- renderPlot({
            # facet label function
            fin.data.names <- list(
                "REV.PER.PUPIL.STATE" = "Revenue per Pupil",
                "EXP.PER.PUPIL.STATE" = "Expenditure per Pupil",
                "TCHR_SA.PER.PUPIL.STATE" = "Teacher Salary per Pupil",
                "TCHR_SAL.AVG.STATE" = "Average Teacher Salary",
                "PUPIL.PER.TCHR.STATE" = "Student / Teacher Ratio")
            
            fin.data_labeller <- function(variable, value) {
                return(fin.data.names[value])
            }
            
            # melt and filter for plotting                 
            p <- ggplot(data = melt(bulletin1014.state[, list(YEAR, REV.PER.PUPIL.STATE, EXP.PER.PUPIL.STATE, TCHR_SA.PER.PUPIL.STATE, TCHR_SAL.AVG.STATE, PUPIL.PER.TCHR.STATE)],
                                    id="YEAR")) +
                geom_line(aes(x = YEAR, y = value, color = variable, name = "datasets"), size = 1) +
                facet_grid(variable ~ ., scale = 'free_y', labeller = fin.data_labeller)+
                xlab("Year") + 
                ylab("Values (in 2012 $)") +
                ggtitle("Michigan Educational Financial Data") +
                theme(legend.position = "none")
            
            print(p)                        
        })
        
        # Tab 3: County Slider and Choropleth ----------------------------------------------------        
        output$outputSliderCounty <- renderUI({    
            MIcounty.map.dt.isolated <- isolate(MIcounty.map.reactive()) # pull in isolated data
            MIcounty.map.dt.isolated <- MIcounty.map.dt.isolated[YEAR == input$yearCounty]
            # set min, max, med, sd variables based on dataset            
            c.med <- median(MIcounty.map.dt.isolated[[input$fldnm]])
            c.sd  <- sd(MIcounty.map.dt.isolated[[input$fldnm]])
            c.min <- min(MIcounty.map.dt.isolated[[input$fldnm]])
            c.max <- max(MIcounty.map.dt.isolated[[input$fldnm]])
            
            # dynamically generate slider based on dataset
            sliderInput("inputSlider",
                        "Slider",
                        min = c.min,
                        max = c.max,
                        value = c(max(c.med - c.sd, c.min),
                                  min(c.med + c.sd, c.max))
            )
            
        })
        
        output$MI.county.choro.map <- renderPlot({
            # code to set range
            if(is.null(input$inputSlider) | !input$showPlotCounty) # Check for renderUI inputs before loading. If null, then return for now
                return()
            
            MIcounty.map.dt.isolated <- isolate(MIcounty.map.reactive()) # pull in isolated dataset
            MIcounty.map.dt.isolated <- MIcounty.map.dt.isolated[YEAR == input$yearCounty]
            fldnm.isolated <- isolate(input$fldnm) # pull in isolated field name (fldnm)
            
            MIcounty.map.dt.isolated[[fldnm.isolated]] <- pmax(MIcounty.map.dt.isolated[[fldnm.isolated]], input$inputSlider[1]) # sets min
            MIcounty.map.dt.isolated[[fldnm.isolated]] <- pmin(MIcounty.map.dt.isolated[[fldnm.isolated]], input$inputSlider[2]) # sets max
            
            # select dataset and color    
            fld.clr <- switch(fldnm.isolated,
                              "EXP.PER.PUPIL.COUNTY"  = "darkgreen",
                              "REV.PER.PUPIL.COUNTY"  = "darkblue",
                              "TCHR_SAL.AVG.COUNTY"   = "darkorchid",
                              "PUPIL.PER.TCHR.COUNTY" = "darkred")
            
            # code for chart
            p<- ggplot(data = MIcounty.map.dt.isolated,
                       aes(x = long, y = lat, group = group)) + 
                labs(title = "Michigan Education: Per Pupil Finances") +
                geom_polygon(aes_string(fill = fldnm.isolated)) + 
                scale_fill_gradient(high = fld.clr, low = "white") + 
                geom_path(color = "black", linestyle = 2) +
                geom_text(data = MIcounty.map.dt.isolated[subregion == input$county1 | subregion == input$county2], aes(x = clong, y = clat, label = subregion), size=5) +
                coord_equal() +
                theme(axis.title = element_blank(),
                      axis.text = element_blank(),
                      axis.ticks = element_blank())
            
            print(p)                       
        })
        
        # Tab 3: County Comparison Table and UI ----------------------------------------------------  
        output$county.comp.table <- renderTable({
            if(is.null(input$county1) | is.null(input$county2) | is.null(input$yearCounty)) # Check for renderUI inputs before loading. If null, then return for now
                return()
            
            total1 <- t(bulletin1014.county[DISTCOUNTY == input$county1 & YEAR == input$yearCounty,
                                            list("Expenditure" = round(TOTEXP.COUNTY),
                                                 "Revenue" = round(TOTREV.COUNTY),
                                                 "Teacher Salary" = round(TCHR.SAL.COUNTY),
                                                 "Number of Teachers" = round(TCHR.NUM.COUNTY),
                                                 "Number of Pupils" = round(PUPIL.NUM.COUNTY))])
            
            per.pupil1 <- t(bulletin1014.county[DISTCOUNTY == input$county1 & YEAR == input$yearCounty,
                                                list("Expenditure" = round(EXP.PER.PUPIL.COUNTY),
                                                     "Revenue" = round(REV.PER.PUPIL.COUNTY),
                                                     "Teacher Salary" = round(TCHR_SA.PER.PUPIL.COUNTY),
                                                     "Number of Teachers" = "",
                                                     "Number of Pupils" = "")])
            
            
            per.teacher1 <- t(bulletin1014.county[DISTCOUNTY == input$county1 & YEAR == input$yearCounty,
                                                  list("Expenditure" = "",
                                                       "Revenue" = "",
                                                       "Teacher Salary" = round(TCHR_SAL.AVG.COUNTY),
                                                       "Number of Teachers" = "",
                                                       "Number of Pupils" = round(PUPIL.PER.TCHR.COUNTY))])    
            
            total2 <- t(bulletin1014.county[DISTCOUNTY == input$county2 & YEAR == input$yearCounty,
                                            list("Expenditure" = round(TOTEXP.COUNTY),
                                                 "Revenue" = round(TOTREV.COUNTY),
                                                 "Teacher Salary" = round(TCHR.SAL.COUNTY),
                                                 "Number of Teachers" = round(TCHR.NUM.COUNTY),
                                                 "Number of Pupils" = round(PUPIL.NUM.COUNTY))])
            
            per.pupil2 <- t(bulletin1014.county[DISTCOUNTY == input$county2 & YEAR == input$yearCounty,
                                                list("Expenditure" = round(EXP.PER.PUPIL.COUNTY),
                                                     "Revenue" = round(REV.PER.PUPIL.COUNTY),
                                                     "Teacher Salary" = round(TCHR_SA.PER.PUPIL.COUNTY),
                                                     "Number of Teachers" = "",
                                                     "Number of Pupils" = "")])
            
            
            per.teacher2 <- t(bulletin1014.county[DISTCOUNTY == input$county2 & YEAR == input$yearCounty,
                                                  list("Expenditure" = "",
                                                       "Revenue" = "",
                                                       "Teacher Salary" = round(TCHR_SAL.AVG.COUNTY),
                                                       "Number of Teachers" = "",
                                                       "Number of Pupils" = round(PUPIL.PER.TCHR.COUNTY))])  
            
            county.comparison <- cbind(total1, per.pupil1, per.teacher1, total2, per.pupil2, per.teacher2)
            colnames(county.comparison) <- c(paste("Total", input$county1),
                                             paste("Per Pupil", input$county1),
                                             paste("Per Teacher", input$county1), 
                                             paste("Total", input$county2),
                                             paste("Per Pupil", input$county2),
                                             paste("Per Teacher", input$county2))  
            
            county.comparison
        })
        
        output$year.header <- renderText({
            paste("Side-by-Side County Comparison for ", input$yearCounty, ", inflation-adjusted", sep="")
        })
        
        output$outputSelecter.County1 <- renderUI({            
            # dynamically generate slider based on dataset
            selectInput("county1",
                        "Select 1st county for comparison",
                        choices = unique(bulletin1014.county[,DISTCOUNTY]),
                        selected = "ALCONA"
            )
            
        })
        
        output$outputSelecter.County2 <- renderUI({            
            # dynamically generate slider based on dataset
            selectInput("county2",
                        "Select 2nd county for comparison",
                        choices = unique(bulletin1014.county[,DISTCOUNTY]),
                        selected = "ALCONA"
            )
            
        })
        
        # Tab 4: Explore Bulletin 1014 ----------------------------------------------------  
        output$download.1014 <- downloadHandler(    
            filename = "bulletin1014.full.csv",
            content = function(file) {                
                write.csv(bulletin1014.full.dt, file)
            }
        )
        
        output$bulletin1014.full.dt <- renderDataTable({
            bulletin1014.full.dt[, list(YEAR, DISTNAME, DISTCOUNTY, AVG.FTE, RNK.FTE, LOCREV, AVG.LOCREV, RNK.LOCREV, STREV, AVG.STREV, RNK.STREV, FEDREV, AVG.FEDREV, RNK.FEDREV, TOTREV, AVG.TOTREV, RNK.TOTREV, TOTEXP, AVG.TOTEXP, RNK.TOTEXP, T.SAL, AVG.T.SAL, RNK.T.SAL, P.TCHR, AVG.P.TCHR, RNK.P.TCH)]
        })
        
    }
)
