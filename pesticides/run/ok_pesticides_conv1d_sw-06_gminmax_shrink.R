#source("experiment.R")

dataset <- load("input/pesticides.RData")
dataset <- get("pesticides")

params <- list(
  sw_size = 6,
  input_size = 1:5,
  ranges = list(epochs=1000),
  filter = ts_fil_none(), #ts_fil_none
  preprocess = list(ts_norm_gminmax()), #ts_norm_gminmax, ts_norm_an, ts_norm_ean, ts_norm_swminmax, ts_norm_diff
  augment = list(ts_aug_shrink()) #ts_aug_none, ts_aug_awareness, ts_aug_awaresmooth, ts_aug_flip, ts_aug_jitter, ts_aug_shrink, ts_aug_stretch
)

for (j in (1:length(dataset))) {
  country <- names(dataset)[j]
  create_directories(country)
  filename <- sprintf("%s_%s", "conv1d", country)
  run_ml(x=dataset[[j]], filename=filename, base_model=ts_conv1d(), train_size=25, test_size=8, params=params)
}