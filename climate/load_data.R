library(dplyr)
library(stringr)

carrega <- function() {
  dataset <- read.csv("raw_data/Environment_Temperature_change_E_All_Data_NOFLAG.csv", header=TRUE, sep=',', fileEncoding="ISO-8859-1")
  
  #countries: usa, china, germany, japan, india, united kingdom, france, brazil, italy, canada
  countries <- c(231, 351, 79, 110, 100, 229, 68, 21, 106, 33)
  
  data <- dataset %>%
    filter(Months.Code == 7020) %>%
	filter(Element.Code == 7271) %>%
    filter(Area.Code %in% countries) %>%
    arrange(match(Area.Code, countries))
  
  data$Area.Code <- NULL
  data$Area.Code..M49. <- NULL
  data$Months.Code <- NULL
  data$Months <- NULL
  data$Element.Code <- NULL
  data$Element <- NULL
  data$Unit <- NULL
  
  data$Area[data$Area == "United States of America"] <- "USA"
  data$Area[data$Area == "United Kingdom of Great Britain and Northern Ireland"] <- "UK"
  data$Area <- paste(str_replace_all(tolower(data$Area), " ", "-"), "_clima", sep = "")
  
  dataset <- list()
  for (i in 1:nrow(data)) {
    x <- as.vector(t(data[i, 2:ncol(data)]))
    names(x) <- str_replace(colnames(data)[2:ncol(data)], "Y", "")
    dataset[[i]] <- x
  }
  names(dataset) <- data$Area
  
  return(dataset)
}

climate <- carrega()
if (!file.exists("input"))
  dir.create("input")
save(climate, file="input/climate.RData")
write.csv(climate, file="input/climate.csv", row.names = FALSE)
