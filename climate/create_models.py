import os


def ensure_directory_exists(directory):
    if not os.path.exists(directory):
        os.makedirs(directory)


def model_parameters(model:str):
  param_ranges = {
    'conv1d': "epochs=1000",
    'elm':    "nhid=1:20, actfun=c('sig','radbas','tribas','relu','purelin')",
    'lstm':   "epochs=1000",
    'knn':    "k=3:10",
    'mlp':    "size=1:10, decay=seq(0,1,0.1), maxit=1000",
    'rfr':    "nodesize=1:10, ntree=seq(20,100,20)",
    'svm':    "kernel=c('radial','sigmoid','linear'), epsilon=seq(0,1,0.2), cost=seq(20,100,20)"
  }
  return param_ranges[model]


def df_params(df:str):
  df_name = {
    'bioenergy':    "bioenergy",
    'climate':      "climate",
    'emissions':    "emissions",
    'emissions-co2':"emissions",
    'fertilizers':  "fertilizers",
    'gdp':          "gdp",
    'pesticides':   "pesticides"
  }
  
  sw_size = {
    'bioenergy':    [4, 5, 6],
    'climate':      [4, 5, 6],
    'emissions':    [4, 5, 6],
    'emissions-co2':[4, 5, 6],
    'fertilizers':  [4, 5, 6],
    'gdp':          [4, 5, 6],
    'pesticides':   [4, 5, 6]
  }
  
  train_size = {
    'bioenergy':    25,
    'climate':      55,
    'emissions':    53,
    'emissions-co2':24,
    'fertilizers':  54,
    'gdp':          46,
    'pesticides':   25
  }
  return df_name[df], sw_size[df], train_size[df]


# Função para criar o conteúdo do arquivo
def create_file_content(
  df: str, 
  df_name: str,
  sw: int,
  input_end: int,
  params: str,
  dn: str,
  da: str,
  ml: str,
  model_ts: str,
  train_size: str):
    
  wf_content = f"""#source("experiment.R")

dataset <- load("input/{df}.RData")
dataset <- get("{df_name}")

params <- list(
  sw_size = {sw},
  input_size = 1:{input_end},
  ranges = list({params}),
  filter = ts_fil_none(), #ts_fil_none
  preprocess = list(ts_norm_{dn}()), #ts_norm_gminmax, ts_norm_an, ts_norm_ean, ts_norm_swminmax, ts_norm_diff
  augment = list(ts_aug_{da}()) #ts_aug_none, ts_aug_awareness, ts_aug_flip, ts_aug_jitter, ts_aug_shrink, ts_aug_stretch
)

for (j in (1:length(dataset))) {{
  country <- names(dataset)[j]
  create_directories(country)
  filename <- sprintf("%s_%s", "{ml}", country)
  run_ml(x=dataset[[j]], filename=filename, base_model=ts_{model_ts}(), train_size={train_size}, test_size=8, params=params)
}}"""
    
  return wf_content


# Função para criar o conteúdo do arquivo
def create_arima_content(
  df: str, 
  df_name: str,
  train_size: str):
    
  wf_content = f"""#source("experiment.R")

dataset <- load("input/{df}.RData")
dataset <- get("{df_name}")

for (j in (1:length(dataset))) {{
  country <- names(dataset)[j]
  create_directories(country)
  filename <- sprintf("%s_%s", "arima", country)
  run_ml(x=dataset[[j]], filename=filename, base_model=ts_arima(), train_size={train_size}, test_size=8)
}}"""
    
  return wf_content


# Configuração dos parâmetros
list_data = ["clima"]
folder = "run"
list_model = ["conv1d", "elm", "lstm", "knn", "mlp", "rfr", "svm"]
list_preprocess = ["an", "ean", "gminmax", "swminmax", "diff"]
list_augment = ["none", "awareness", "flip", "jitter", "shrink", "stretch"]

# Garantindo que o diretório de saída existe
ensure_directory_exists(folder)

# Loop para gerar arquivos
for df in list_data:
  df_name, sw_size, train_size = df_params(df)
  for ml in list_model:
    for sw in sw_size:
      for dn in list_preprocess:
        input_end = sw - (1 if dn != "diff" else 2)
        for da in list_augment:
          params = model_parameters(ml)
          model_ts = "rf" if ml == "rfr" else ml
          
          file_name = f"{df}_{ml}_sw-{sw:02}_{dn}_{da}.R"
          file_content = create_file_content(
            df, df_name, sw, input_end, params, dn, da, ml, model_ts, train_size)
          
          with open(os.path.join(folder, file_name), "w") as f:
            f.write(file_content)

'''
# ARIMA
for df in list_data:
  df_name, sw_size, train_size = df_params(df)
  file_name = f"{df}_arima.R"
  file_content = create_arima_content(df, df_name, train_size)
  with open(os.path.join(folder, file_name), "w") as f:
    f.write(file_content)
'''
