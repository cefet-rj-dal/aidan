library(dplyr)
library(stringr)

carrega <- function() {
  dataset <- read.csv("raw_data/Inputs_FertilizersNutrient_E_All_Data_NOFLAG.csv", header=TRUE, sep=',')
  
  #countries: usa, china, germany, japan, india, united kingdom, france, brazil, italy, canada
  countries <- c(231, 351, 79, 110, 100, 229, 68, 21, 106, 33)
  
  data <- dataset %>%
    filter(Element.Code == 5159) %>%
    filter(Area.Code %in% countries) %>%
    arrange(match(Area.Code, countries))
  
  data$Area.Code <- NULL
  data$Area.Code..M49. <- NULL
  data$Item.Code <- NULL
  data$Element.Code <- NULL
  data$Element <- NULL
  data$Unit <- NULL
  
  data$Area[data$Area == "United States of America"] <- "USA"
  data$Area[data$Area == "United Kingdom of Great Britain and Northern Ireland"] <- "UK"
  
  data <- data %>%
    mutate(
      Item = case_when(
        str_detect(Item, "Nutrient nitrogen N \\(total\\)") ~ "N",
        str_detect(Item, "Nutrient phosphate P2O5 \\(total\\)") ~ "P2O5",
        str_detect(Item, "Nutrient potash K2O \\(total\\)") ~ "K2O",
        TRUE ~ str_replace_all(Item, "Nutrient potash | \\(total\\)", "")
      ),
      Area = tolower(sprintf("%s_%s", str_replace_all(Area, " ", ""), Item))
    )
  
  data$Item <- NULL
  
  dataset <- list()
  for (i in 1:nrow(data)) {
    x <- as.vector(t(data[i, 2:ncol(data)]))
    names(x) <- str_replace(colnames(data)[2:ncol(data)], "Y", "")
    dataset[[i]] <- x
  }
  names(dataset) <- data$Area
  
  return(dataset)
}

fertilizers <- carrega()
if (!file.exists("input"))
  dir.create("input")
save(fertilizers, file="input/fertilizers.RData")
write.csv(fertilizers, file="input/fertilizers.csv", row.names = FALSE)
