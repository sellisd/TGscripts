#!/usr/bin/env Rscript
args = commandArgs(trailingOnly = TRUE)
if(length(args) < 2){
  stop("missing input/output file name(s)")
}
inputFile <- args[1]  
outputFile <- args[2]
# Chapacuran:
# Rscript --vanilla ~/projects/tg/chapacuran/chapacura-207-GA.csv ~/projects/tg/chapacuran/chMultistate.tr.tab
# Cariban:
# Rscript --vanilla ~/projects/tg/cariban/cariban4multistate.csv ~/projects/tg/cariban/cbMultistate.tr.tab
# do not read languages as header to preserve the Unicode
ga <- read.csv(inputFile, sep = "\t", as.is = TRUE, header = FALSE)
meanings <- unique(ga[-1, 2])
# validate input
if(length(unique(gsub(" ", "", meanings))) != length(meanings)){
  stop("if space characters are the only difference between two entries, then it is probably something mistyped, e.g. good* vs good *")
}
noWords <- function(a){
  # check if there are no words in a line
  all(a == "?" | a == "-")
}
emptyLineB <- apply(ga[, c(-1,-2, -3)], 1, noWords)
if(any(emptyLineB)){
  meaningsColumn <- ga[, 2]
  subsetColumn <- ga[, 3]
  stop(paste("empty line(s):", paste(meaningsColumn[which(emptyLineB)], subsetColumn[which(emptyLineB)], collapse =", ")))
}
# check if states are unique for each meaning
for(m in meanings){
  #m <- meanings[1]
  setLetters <- ga[which(ga[,2] == m), 3]
  setValues <- character()
  if(isTRUE(all.equal(setLetters,LETTERS[1:length(setLetters)]))){
    setValues <- append(setValues, "alphabetical")
  }else if (isTRUE(all.equal(setLetters,as.character(c(1:length(setLetters)))))){
    setValues <- append(setValues, "numeric")
  }else{
    stop("unknown set values, or error at: ",m)
  }
}
if(all(setValues == "alphabetical")){
  cat("set values alphabetical (ABC...) \n")
}else if (all(setValues == "numeric")){
  cat("set values numeric (123...) \n")
}else{
  stop("mixed set values")
}

# add ASCII language names as column headers
languagesU <- ga[1, c(-1, -2, -3)] # unicode languages
header <- ga[1, ]
ga <- ga[-1, ]
header <- iconv(header, to = "ASCII", sub = "")
names(ga) <- header
languages <- header[-c(1, 2, 3)] # ASCII representation of language
if(length(unique(languages)) != length(unique(languagesU))){
  stop("At least two languages differ only by a Unicode character")
}
#languages <- names(ga)[c(-1,-2,-3)] # exclude No, English and Set columns
multistateM <- matrix(ncol = (1 + length(languages)), nrow = length(meanings))
matrixRowCounter <- 1
for(m in meanings){
  # m <- meanings[1]
  states <- character(length(languages))
  counter <- 1
  for(l in languages){
    #l <- languages[1]
    wordV <- ga[which(ga$English==m),l]
    if(all(wordV == "?")){
      states[counter] <- "?"
    }else{
      wordI <- which(wordV != "-")
      if(length(wordI) != 1){
        if(length(wordI) > 0){
          # multiple words
          stop("Error: multiple words")
          states[counter] <- paste(wordI, collapse = ",")
        }else{
          stop("no words?!")
        }
      }else{
        states[counter] <- wordI
      }
#      states[counter] <- paste(wordI, collapse = ",")
    }
    counter <- counter + 1
  }  
  multistateM[matrixRowCounter,] <- c(m, states)
  matrixRowCounter <- matrixRowCounter + 1
}
multistate2save <- cbind(c("", languagesU), t(multistateM))
# Save
write.table(multistate2save, file = outputFile, sep = "\t", quote = FALSE, row.names = FALSE, col.names = FALSE)
