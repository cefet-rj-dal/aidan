library(dplyr)
library(stringr)

carrega <- function(co2 = FALSE) {
  dataset <- read.table("raw_data/Emissions_Totals_E_All_Data_NOFLAG.csv", header=TRUE, sep=",")
  
  #countries: usa, china, germany, japan, india, united kingdom, france, brazil, italy, canada
  countries <- c(231, 351, 79, 110, 100, 229, 68, 21, 106, 33)
  
  data <- dataset %>%
    filter((Element == "Emissions (CO2)") | (Element == "Emissions (CH4)") | (Element == "Emissions (N2O)")) %>%
    filter(Item == "All sectors with LULUCF") %>%
    filter(Area.Code %in% countries) %>%
    arrange(match(Area.Code, countries))
  
  data$Area.Code <- NULL
  data$Area.Code..M49. <- NULL
  data$Item.Code <- NULL
  data$Item <- NULL
  data$Element.Code <- NULL
  data$Source.Code <- NULL
  data$Source <- NULL
  data$Unit <- NULL
  data$Y2030 <- NULL
  data$Y2050 <- NULL
  
  data$Area[data$Area == "United States of America"] <- "USA"
  data$Area[data$Area == "United Kingdom of Great Britain and Northern Ireland"] <- "UK"
  
  data <- data %>%
    mutate(
      Element = case_when(
        str_detect(Element, "Emissions \\(CO2\\)") ~ "CO2",
        str_detect(Element, "Emissions \\(CH4\\)") ~ "CH4",
        str_detect(Element, "Emissions \\(N2O\\)") ~ "N2O",
        TRUE ~ str_replace_all(Element, "Emissions \\(|\\)", "")
      ),
      Area = tolower(sprintf("%s_%s", str_replace_all(Area, " ", ""), Element))
    )
  
  if (co2) {
    data <- data %>%
      filter(Element == "CO2") %>%
      select(Area, matches("^Y(1990|199[1-9]|200[0-9]|201[0-9]|2020|2021)$"))
  } else {
    data <- data %>%
      filter(Element == "CH4" | Element == "N2O")
    data$Element <- NULL
  }
  
  dataset <- list()
  for (i in 1:nrow(data)) {
    x <- as.vector(t(data[i, 2:ncol(data)]))
    names(x) <- str_replace(colnames(data)[2:ncol(data)], "Y", "")
    dataset[[i]] <- x
  }
  names(dataset) <- data$Area
  
  return(dataset) 
}

emissions <- carrega()
if (!file.exists("input"))
  dir.create("input")
save(emissions, file="input/emissions.RData")
write.csv(emissions, file="input/emissions.csv", row.names = FALSE)

emissions <- carrega(co2=TRUE)
save(emissions, file="input/emissions-co2.RData")
write.csv(emissions, file="input/emissions-co2.csv", row.names = FALSE)

