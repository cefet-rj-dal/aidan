#source("experiment.R")

dataset <- load("input/climate.RData")
dataset <- get("climate")

for (j in (1:length(dataset))) {
  country <- names(dataset)[j]
  create_directories(country)
  filename <- sprintf("%s_%s", "arima", country)
  run_ml(x=dataset[[j]], filename=filename, base_model=ts_arima(), train_size=55, test_size=8)
}