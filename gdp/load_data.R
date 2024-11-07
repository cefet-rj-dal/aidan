library(dplyr)
library(stringr)

carrega <- function() {
  dataset <- read.csv("raw_data/Macro-Statistics_Key_Indicators_E_All_Data_NOFLAG.csv", header=TRUE, sep=',')
  
  #countries: usa, china, germany, japan, india, united kingdom, france, brazil, italy, canada
  countries <- c(231, 351, 79, 110, 100, 229, 68, 21, 106, 33)
  
  data <- dataset %>%
    filter(Item.Code == 22008) %>%
	filter(Element.Code == 6110) %>%
    filter(Area.Code %in% countries) %>%
    arrange(match(Area.Code, countries))
  
  data$Area.Code <- NULL
  data$Area.Code..M49. <- NULL
  data$Item.Code <- NULL
  data$Item <- NULL
  data$Element.Code <- NULL
  data$Element <- NULL
  data$Unit <- NULL
  
  data$Area[data$Area == "United States of America"] <- "USA"
  data$Area[data$Area == "United Kingdom of Great Britain and Northern Ireland"] <- "UK"
  data$Area <- paste(str_replace_all(tolower(data$Area), " ", "-"), "_gdp", sep = "")
  
  dataset <- list()
  for (i in 1:nrow(data)) {
    x <- as.vector(t(data[i, 2:ncol(data)]))
    names(x) <- str_replace(colnames(data)[2:ncol(data)], "Y", "")
    dataset[[i]] <- x
  }
  names(dataset) <- data$Area
  
  return(dataset)
}

gdp <- carrega()
if (!file.exists("input"))
  dir.create("input")
save(gdp, file="input/gdp.RData")
write.csv(gdp, file="input/gdp.csv", row.names = FALSE)
