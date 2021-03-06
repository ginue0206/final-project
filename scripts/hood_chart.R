library(dplyr)

# Read in the shapefiles for each year
seattle_18 <- st_read("./data/2018_Fire_Calls_Seattle/2018_Fire_Calls_Seattle.shp", stringsAsFactors = F)
seattle_17 <- st_read("./data/2017_Fire_Calls_Seattle/2017_Fire_Calls_Seattle.shp", stringsAsFactors = F)

# Add on extra columns of increases and percentage increases for call locations to display stats
h17 <- seattle_17 %>% group_by(S_HOOD) %>% summarise(c17 = n())
h18 <- seattle_18 %>% group_by(S_HOOD) %>% summarise(c18 = n())
hood_names <- h17$S_HOOD
h17_count <- h17$c17
h18_count <- h18$c18
hood <- data.frame(hood_names, h17_count, h18_count) %>% 
        mutate(increase_count = h18_count - h17_count) %>% 
        mutate(total_count = h18_count + h17_count) %>% 
        mutate(increase_perc = increase_count / total_count)

# Returns a bar chart of the number of calls, grouped by neighborhoods
hood_chart <- function(year, neighborhood) {
  # Aggregate information for chosen neighborhood
  hood_df <- hood %>% filter(hood_names == neighborhood)
  direction <- ifelse(hood_df$increase_count < 0, "decrease", "increase")
  percentage <- paste0(round(hood_df$increase_perc[1] * 100, digits = 2), "%")
  stat <- list("y17" = hood_df$h17_count[1], "y18" = hood_df$h18_count[1], "direction" = direction, "percentage" = percentage)  
  
  # Creates initial bar chart to overlay dataset on
  p <- ggplot() +
        labs(caption = paste0("From 2017 to 2018, ", neighborhood, "'s number of 911 calls went from ", stat$y17,
                              " to ", stat$y18, " which meant a ", stat$direction, " of ", percentage, ".")) +
        theme(axis.text.x = element_text(angle = 45, hjust = 1),
              axis.title = element_text(vjust=1),
              legend.position = c(1, 1),
              legend.justification = c(1,1),
              legend.background = element_blank())
  
  # Determines which year of data set to display based upon input and then adds the bars that correspondingly
  if (is.element(18, year)) {
    s_18 <- seattle_18 %>% group_by(S_HOOD) %>% summarise(Count = n())
    colnames(s_18)[1] <- "Neighborhood"
    p <- p + geom_bar(s_18, mapping = aes(x = Neighborhood, y = Count, fill = "2018"), 
                      stat = "identity", position = "dodge") + 
                      guides(fill = guide_legend(title = "Year"))
  }
  
  if (is.element(17, year)){
    s_17 <- seattle_17 %>% group_by(S_HOOD) %>% summarise(Count = n())
    colnames(s_17)[1] <- "Neighborhood"
    p <- p + geom_bar(s_17, mapping = aes(x = Neighborhood, y = Count, fill = "2017"), 
                      stat = "identity", position = "dodge") + 
                      guides(fill = guide_legend(title = "Year"))
  }
  
  # Converts the ggplot chart to a ggplotly chart to make it interactive friendly
  # Many of the layout arguments had to be redone, referenced from here: https://plot.ly/r/reference/#layout
  g <- ggplotly(p, tooltip = c('x', 'y')) %>% 
        layout(title = paste0("911 Call Locations by Neighborhood"),
               margin = list(b = 150, l = 100, t = 50),
               legend = list(x = .95, y = .95),
               annotations = list(x = 1, y = 1, showarrow = F, xanchor = "left", yanchor = "bottom",
                                  text = paste0("From 2017 to 2018, ", neighborhood, 
                                                "'s number of 911 calls went from ", stat$y17, " to ", 
                                                stat$y18, " which meant a ", stat$direction, " of ", 
                                                percentage, ".")))
  
  return(g)
}

# We did some further statistical analysis, but was unable to incorporate/pass it back to the ui
# #####################statistical analysis#######################
# pop_data <- read.csv("./data/Population_Density_2017.csv", stringsAsFactors = FALSE)
# # Finds total number of calls in each neighborhood
# neighborhood_calls <- seattle_18 %>% group_by(S_HOOD) %>% summarize(total_numb_calls=n()) %>% arrange(desc(total_numb_calls))
# # Calculates average number of calls per neighborhood.
# average_numb_calls <- nrow(seattle_18)/(length(unique(seattle_18$S_HOOD)))
# # Max number of calls per neighborhood
# max_calls_neighborhood <- neighborhood_calls[which.max(neighborhood_calls$total_numb_calls),]
# # Min number of calls per neighborhood
# min_calls_neighborhood <-neighborhood_calls[which.min(neighborhood_calls$total_numb_calls),]
# # Range
# range_calls_neighborhood <- max_calls_neighborhood$total_numb_calls - min_calls_neighborhood$total_numb_calls
# # Median
# median_calls_neighborhood <- median(neighborhood_calls$total_numb_calls)
# # Calculates top 10 neighborhoods with the most calls.
# top_10_neighborhoods <- neighborhood_calls %>% head(10) %>% select(S_HOOD, total_numb_calls)
# 
# ###########correlation between population ##########
# # Calculates difference in the number of calls in 2018 to 2017
# diff_numb_calls <- nrow(seattle_18) - nrow(seattle_17)
# # Calculates the percent change in the number of calls from 2017 to 2018
# calls_percent_change <- (diff_numb_calls/nrow(seattle_17)) * 100
# # Calculates difference in total pop from 2017 to 2016
# pop_change <- sum(pop_data$Estimated.Total.Population.2017)-sum(pop_data$Estimated.Total.Population.2016)
# # Calculates percent change in total population from 2016 to 2017
# pop_percent_change <- (pop_change/sum(pop_data$Estimated.Total.Population.2016)) * 100
