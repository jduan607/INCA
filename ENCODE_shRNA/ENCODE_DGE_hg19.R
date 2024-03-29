library(data.table)
library(doMC)
cores=detectCores(); registerDoMC(cores=cores-5)

directory = 'https://raw.github.com/jduan607/INCA/master'

file = fread(file.path(directory,'ENCODE_shRNA/files.txt'), header=FALSE,nrow=1)[[1]]
metadata = fread(file)
metadata = metadata[`File assembly`=='hg19',] # hg19 genome assembly only
metadata = metadata[`File Status`=='released',] # Omit archived files
metadata = metadata[`Output type`=='differential expression quantifications',] # DGE analysis
metadata[,`Experiment target` := gsub('-human','', `Experiment target`)] # Drop '-human' suffix

target = unique(metadata[,.(`Experiment target`,`Biosample term name`)]) # Experiment targets

## Differential gene expression analyis from shRNA RNA-seq
foreach(i = 1:nrow(target), .combine=c) %dopar% {
    files = suppressMessages( dplyr::left_join(target[i,], metadata, multiple='all') )

    dge = sapply(files[,`File download URL`], function(x) 'gene' %in% fread(x, nrow=1, header=FALSE))
    data = fread(files[dge, `File download URL`])                 
    
    output = paste(target[[1]][i], target[[2]][i], 'DGE.txt.gz', sep='_')
    fwrite(data, file.path(directory,'DGE',output), sep='\t')
}
