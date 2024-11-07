library(daltoolbox)
library(tspredit)
library(stringi)
library(dplyr)
library(stringr)
library(ggplot2)
set.seed(120770)


create_directories <- function(country) {
  dir_name <- sprintf("%s/%s", "hyper", country)
  if (!file.exists(dir_name))
    dir.create(dir_name, recursive = TRUE)
  #dir_name <- sprintf("%s/%s", "graphics", country)
  #if (!file.exists(dir_name))
  #  dir.create(dir_name, recursive = TRUE)
  dir_name <- sprintf("%s/%s", "results", country)
  if (!file.exists(dir_name))
    dir.create(dir_name, recursive = TRUE)
}


run_ml <- function(x, filename, base_model, train_size, test_size, ro = TRUE, steps_ahead = 1, params=list()) {
  country <- sub(".*?_", "", filename)
  myexp <- wf_experiment(filename, base_model, train_size)
  myexp <- set_params(myexp, params)
  myexp <- train(myexp, x)
  results <- NULL
  
  #rolling origin
  for (j in 1:test_size) {
    result <- test(myexp, x, test_pos = train_size+1, test_size = j, steps_ahead = 1, ro = TRUE, img = (j==test_size))
    results <- rbind(results, result$df)
  }
  
  #steps ahead
  result <- test(myexp, x, test_pos = train_size+1, test_size = test_size, steps_ahead = test_size, ro = FALSE, img = TRUE)
  results <- rbind(results, result$df)
  
  filename <- sprintf("results/%s/%s", country, result$name)
  save(results, file=sprintf("%s.rdata", filename))
}


describe <- function(obj) {
  if (is.null(obj))
    return("")
  else
    return(as.character(class(obj)[1]))
}


# class wf_experiment
wf_experiment <- function(filename, base_model, train_size,
                          sw_size = 0,
                          input_size = c(1),
                          filter = ts_fil_none(),
                          preprocess = list(ts_norm_none()),
                          augment = list(ts_aug_none()),
                          ranges = list()) {
  obj <- dal_transform()
  obj$filename <- filename
  obj$base_model <- base_model
  obj$sw_size <- sw_size
  obj$input_size <- input_size
  obj$train_size <- train_size
  obj$filter <- filter
  obj$preprocess <- preprocess
  obj$augment <- augment
  obj$ranges <- ranges
  
  class(obj) <- append("wf_experiment", class(obj))
  return(obj)
}


train <- function(obj, x) {
  obj$desc_input_size <- stri_paste(as.character(obj$input_size), collapse = '_')
  obj$desc_preprocess <- stri_paste(sapply(obj$preprocess, function(x) { as.character(describe(x)) }), collapse='_')  
  obj$desc_augment <- stri_paste(sapply(obj$augment, function(x) { as.character(describe(x)) }), collapse='_')  
  
  x <- x[1:obj$train_size]
  x <- na.omit(x)
  
  obj$train <- x[obj$sw_size:length(x)]
  obj$obs <- as.character(obj$train)
  if (length(names(obj$train)) > 0)
    obj$obs <- names(obj$train)[length(obj$train)]
  
  #apply filter
  xw <- ts_data(as.vector(x), obj$sw_size)
  xw <- transform(obj$filter, xw)
  xy <- ts_projection(xw)
  
  if (obj$sw_size != 0) {
    mytune <- ts_maintune(obj$input_size, obj$base_model, folds=10, preprocess = obj$preprocess, augment = obj$augment)
    obj$model <- fit(mytune, xy$input, xy$output, obj$ranges)
    obj$input_size <- obj$model$input_size
    obj$preprocess <- obj$model$preprocess
    obj$augment <- attr(obj$model, "augment")
  } else {
    obj$model <- fit(obj$base_model, x=xy$input, y=xy$output)
    obj$input_size <- 0
    obj$preprocess <- ts_norm_none()
    obj$augment <- ts_aug_none()
  }
  
  xw <- ts_data(as.vector(x), obj$sw_size)
  xy <- ts_projection(xw)      
  
  obj$adjust <- as.vector(predict(obj$model, xy$input))
  obj$ev_adjust <- evaluate(obj$model, as.vector(xy$output), obj$adjust)
  
  country <- sub(".*?_", "", obj$filename)
  filename <- tolower(paste(obj$filename,
                            sprintf("sw-%02d", obj$sw_size),
                            #gsub("_", "-", attr(obj$filter, "class")[1]),
                            gsub("_", "-", attr(obj$preprocess, "class")[1]),
                            gsub("_", "-", attr(obj$augment, "class")[1]), sep="_"))
  
  hyperparameters <- attr(obj$model, "hyperparameters")
  if (!is.null(hyperparameters)) {
    save(hyperparameters, file=sprintf("hyper/%s/%s_hparams.rdata", country, filename))
    #write.csv2(hyperparameters, file=sprintf("hyper/%s/%s_hparams.csv", country, filename), row.names = FALSE)
  }
  params <- attr(obj$model, "params")
  if (!is.null(params)) {
    #save(params, file=sprintf("hyper/%s/%s_params.rdata", country, filename))
    write.csv2(params, file=sprintf("hyper/%s/%s_params.csv", country, filename), row.names = FALSE)
  }
  
  return(obj)
}


test <- function(obj, x, test_pos, test_size, ro = TRUE, steps_ahead = 1, img) {
  
  obj$test <- x[test_pos:(test_pos+test_size-1)]
  if (obj$sw_size != 0)
    xwt <- ts_data(as.vector(x[(test_pos-obj$sw_size+1):(test_pos+test_size-1)]), obj$sw_size)
  else
    xwt <- ts_data(as.vector(x[test_pos:(test_pos+test_size-1)]), obj$sw_size)
  
  xyt <- ts_projection(xwt)    
  
  output <- as.vector(xyt$output)
  if (steps_ahead == 1)  {
    obj$prediction <- predict(obj$model, x=xyt$input, steps_ahead=steps_ahead)
  }
  else {
    obj$prediction <- predict(obj$model, x=xyt$input[1,], steps_ahead=steps_ahead)
    output <- output[1:steps_ahead]
  }  
  
  obj$prediction <- as.vector(obj$prediction)
  obj$ev_prediction <- evaluate(obj$model, output, obj$prediction)
  
  smape_train <- 100*obj$ev_adjust$smape
  smape_test <- 100*obj$ev_prediction$smape
  #print(smape_test)
  
  country <- sub(".*?_", "", obj$filename)
  experiment <- strsplit(country, "_")[[1]]
  filename <- paste(obj$filename,
                    sprintf("sw-%02d", obj$sw_size),
                    #gsub("_", "-", describe(obj$filter)),
                    gsub("_", "-", describe(obj$preprocess)),
                    gsub("_", "-", describe(obj$augment)), sep="_")
  
  if (ro) {
    imagename <- tolower(sprintf("%s_ro-%02d.jpg", filename, test_size))
    #if (img) save_image(obj, country, imagename)
  } else {
    imagename <- tolower(sprintf("%s_sa-%02d.jpg", filename, test_size))
    #save_image(obj, country, imagename)
  }
  
  result <- data.frame(full_name = filename,
                       country = experiment[1],
                       dataset = experiment[2],
                       #method = describe(obj$base_model),
                       model = describe(obj$model),
                       #filter = describe(obj$filter),
                       preprocess = describe(obj$preprocess),
                       augment = describe(obj$augment),
                       window_size = obj$sw_size,
                       input_size = obj$input_size,
                       #obs = obj$obs,
                       test_size = test_size,
                       steps_ahead = steps_ahead,
                       prediction = obj$prediction[length(obj$prediction)],
                       smape_train = smape_train,
                       smape_test = smape_test
  )
  
  return(list(df = result, name = filename))
}


save_image <- function(obj, country, imagename) {
  # 1. Filename
  jpeg(sprintf("graphics/%s/%s", country, imagename), width = 640, height = 480)
  # 2. Create the plot
  yvalues <- c(obj$train, obj$test)
  xlabels <- 1:length(yvalues)
  if(!is.null(names(yvalues)))
    xlabels <- as.integer(names(yvalues))
  grf <- plot_ts_pred(x = xlabels, y = yvalues, yadj=obj$adjust, ypre=obj$prediction)
  plot(grf)
  # 3. Close the file
  dev.off()
}
