#source("experiment.R")

dataset <- load("input/emissions-co2.RData")
dataset <- get("emissions")

for (j in (1:length(dataset))) {
  country <- names(dataset)[j]
  create_directories(country)
  filename <- sprintf("%s_%s", "arima", country)
  run_ml(x=dataset[[j]], filename=filename, base_model=ts_arima(), train_size=24, test_size=8)
}