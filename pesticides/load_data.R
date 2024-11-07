library(dplyr)
library(stringr)

carrega <- function() {
  dataset <- read.csv("raw_data/Inputs_Pesticides_Use_E_All_Data_NOFLAG.csv", header=TRUE, sep=',')
  
  #countries: india, japan, canada, usa, china, germany, united kingdom, france, brazil, italy
  countries <- c(100, 110, 33, 231, 351, 79, 110, 229, 68, 21, 106)
  
  data <- dataset %>%
    filter(Item.Code == 1357) %>%
    filter(Element.Code == 5157) %>%
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
  
  data$Area <- paste(str_replace_all(tolower(data$Area), " ", "-"), "_pest", sep = "")
  
  dataset <- list()
  for (i in 1:nrow(data)) {
    x <- as.vector(t(data[i, 2:ncol(data)]))
    names(x) <- str_replace(colnames(data)[2:ncol(data)], "Y", "")
    dataset[[i]] <- x
  }
  names(dataset) <- data$Area
  
  return(dataset)
}

pesticides <- carrega()
if (!file.exists("input"))
  dir.create("input")
save(pesticides, file="input/pesticides.RData")
write.csv(pesticides, file="input/pesticides.csv", row.names = FALSE)