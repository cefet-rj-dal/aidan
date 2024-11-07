library(purrr)
library(dplyr)

merge_results <- function(){
  
  current_path <- getwd()
  current_path <- basename(current_path)
  merge_path <- 'results/'
  filename <- paste(current_path, 'combined_results.rdata', sep="_")
  
  #Del file
  if (file.exists(paste(merge_path, filename, sep="")))
    file.remove(paste(merge_path, filename, sep=""))
  
  #Combine all files
  all_files <-list.files(merge_path, full.names=TRUE, recursive=TRUE, pattern='.rdata') %>%
    map_df(~ get(load(file=.x)))
  
  #Save
  save(all_files, file = paste(merge_path, filename, sep=''))
  write.csv2(all_files, file = gsub("rdata", "csv", paste(merge_path, filename, sep='')), row.names=FALSE)
  
}

merge_results()
