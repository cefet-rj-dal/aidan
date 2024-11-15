# Instalar e carregar pacotes necessários
if (!requireNamespace("progress", quietly = TRUE)) {
  install.packages("progress")
}
library(progress)
source("experiment.R")

# Define o diretório onde estão os arquivos .R
dir <- "run"

# Verifica se o diretório existe
if (!dir.exists(dir)) {
  stop(paste("O diretório", dir, "não existe."))
}

# Lista todos os arquivos .R no diretório especificado
files <- list.files(path = dir, pattern = "\\.R$", full.names = TRUE)
files <- files[!grepl("^ok_", basename(files))]
files <- files[grepl("emissions_", basename(files)) & grepl("rfr", basename(files))] # <== select here

# Cria a barra de progresso
pb <- progress::progress_bar$new(
  format = "[:bar]:percent :elapsed/:eta ",
  total = length(files),
  clear = FALSE,
  width = 40
)

# Inicializa variáveis para o cálculo do tempo
start_time <- Sys.time()
total_time <- 0
processed_files <- 0

# Função para atualizar a barra de progresso e a estimativa de tempo
update_progress <- function() {
  pb$tick()
  elapsed_time <- as.numeric(difftime(Sys.time(), start_time, units = "secs"))
  avg_time <- total_time / processed_files
  remaining_files <- length(files) - processed_files
  estimated_time <- avg_time * remaining_files
  eta <- start_time + elapsed_time + estimated_time
}

# Loop para cada arquivo .R no diretório
counter <- 0
for (file in files) {
  counter <- counter + 1
  progress <- sprintf("%d/%d", counter, length(files))
  
  cat("(", progress, ") Executando:", basename(file), "\n")
  start_file_time <- Sys.time()
  
  # Executa o arquivo .R usando source
  tryCatch({
    source(file)
    # Renomeia o arquivo adicionando "ok_" antes do nome
    new_name <- file.path(dir, paste("ok", basename(file), sep="_"))
    file.rename(file, new_name)
  }, error = function(e) {
    cat("Erro em", basename(file), ":", e$message, "\n")
  })
  end_file_time <- Sys.time()
  file_duration <- as.numeric(difftime(end_file_time, start_file_time, units = "secs"))
  
  # Atualiza o tempo total e o número de arquivos processados
  total_time <- total_time + file_duration
  processed_files <- processed_files + 1
  update_progress()
}

end_time <- Sys.time()
total_duration <- as.numeric(difftime(end_time, start_time, units = "secs"))
average_time <- if (processed_files > 0) total_time / processed_files else 0

cat("Tempo total: ", format(as.POSIXct(total_duration, origin="1970-01-01", tz = "UTC"), "%H:%M:%S"), "\n")
cat("Tempo médio por arquivo: ", format(as.POSIXct(average_time, origin="1970-01-01", tz = "UTC"), "%H:%M:%S"), "\n")
