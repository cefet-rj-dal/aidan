#source("experiment.R")

dataset <- load("input/emissions-co2.RData")
dataset <- get("emissions")

params <- list(
  sw_size = 6,
  input_size = 1:5,
  ranges = list(kernel=c('radial','sigmoid','linear'), epsilon=seq(0,1,0.2), cost=seq(20,100,20)),
  filter = ts_fil_none(), #ts_fil_none
  preprocess = list(ts_norm_an()), #ts_norm_gminmax, ts_norm_an, ts_norm_ean, ts_norm_swminmax, ts_norm_diff
  augment = list(ts_aug_none()) #ts_aug_none, ts_aug_awareness, ts_aug_awaresmooth, ts_aug_flip, ts_aug_jitter, ts_aug_shrink, ts_aug_stretch
)

for (j in (1:length(dataset))) {
  country <- names(dataset)[j]
  create_directories(country)
  filename <- sprintf("%s_%s", "svm", country)
  run_ml(x=dataset[[j]], filename=filename, base_model=ts_svm(), train_size=24, test_size=8, params=params)
}