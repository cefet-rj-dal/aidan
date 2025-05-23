#source("experiment.R")

dataset <- load("input/emissions.RData")
dataset <- get("emissions")

params <- list(
  sw_size = 4,
  input_size = 1:3,
  ranges = list(size=1:10, decay=seq(0,1,0.1), maxit=1000),
  filter = ts_fil_none(), #ts_fil_none
  preprocess = list(ts_norm_gminmax()), #ts_norm_gminmax, ts_norm_an, ts_norm_ean, ts_norm_swminmax, ts_norm_diff
  augment = list(ts_aug_awareness()) #ts_aug_none, ts_aug_awareness, ts_aug_awaresmooth, ts_aug_flip, ts_aug_jitter, ts_aug_shrink, ts_aug_stretch
)

for (j in (1:length(dataset))) {
  country <- names(dataset)[j]
  create_directories(country)
  filename <- sprintf("%s_%s", "mlp", country)
  run_ml(x=dataset[[j]], filename=filename, base_model=ts_mlp(), train_size=53, test_size=8, params=params)
}