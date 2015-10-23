# reduce states
# INPUT multistate encoded file (transposed)
# OUTPUT multistate file with no more than 10 states (MrBayes restriction)
mesquiteLetters <- c(1:8,11:14,16:26)
alphabet <- c(0:9, LETTERS[mesquiteLetters], letters[mesquiteLetters])

# useful function
reduce <- function(entry, lookup = lookup){
  reducedEntry <- unique(lookup[unlist(strsplit(entry,"&"))])
  #if only one and ? keep it else remove ?
  if(all(reducedEntry == "?")){
    newEntry <- "?"    
  }else{
    newEntryV <- reducedEntry[reducedEntry != "?"]
    if(length(newEntryV) > 1){
      newEntry <- paste("(", paste(reducedEntry[reducedEntry != "?"], collapse = ","), ")", sep = "")
    }else{
      newEntry <- newEntryV
    }
  }
  newEntry
}

stateNoMax <- 0 # overall maximum number of states
mst <- read.csv("~/projects/tg/data/tgMultistate.tr.csv", as.is = TRUE, sep = "\t", header = FALSE, stringsAsFactors = FALSE)
#mst <- mst[1:10,1:10]
meanings <- unname(unlist(as.vector(mst[1, -1])))
languages <- mst[ -1, 1]
mst <- mst[-1,-1] # matrix only (no meanings or languages)

emptyMeaning <- which(is.na(meanings))
if(length(emptyMeaning) != 0){ # if there are empty meanings, remove them
  warning(paste("Removed empty meaning(s):", emptyMeaning))
  if(!all(is.na(mst[, emptyMeaning]))){
    warning("not all empty meanings were NA")
  }
  mst <- mst[, -emptyMeaning]
  meanings <- meanings[-emptyMeaning]
}

# test for unexpected symbols in input
wrongSymbols <- unlist(strsplit(as.vector(unlist(mst)), ""))
wrongSymbols <- unique(wrongSymbols[!wrongSymbols %in% c(alphabet, "&", "?")])
stop("unexpected symbols not part of the expected alphabet: ", wrongSymbols)
reducedM <- matrix(ncol = ncol(mst), nrow = nrow(mst))
#i <- 7
for(i in c(1:length(meanings))){
  colChar <- unname(unlist(mst[, i, drop = TRUE]))
  charHist <- table(unlist(strsplit(colChar,"&")))
  for(a in c(1:length(charHist))){
    if(names(charHist[a]) == "?"){
      charHist[a] <- "?"
    }
    if(charHist[a] <= 1){
      charHist[a] <- "?"
    }
  }
  reducedStates <- names(charHist[charHist != "?"])
  charHist[reducedStates] <- alphabet[c(1:length(reducedStates))] # is there any discrepancy between reduced State names and the expected alphabet?
  stateNoCur <- length(unique(charHist[charHist != "?"]))
  if(stateNo < stateNoCur){
    stateNoMax <- stateNoCur
  }
  reducedM[, i] <- unlist(lapply(colChar, reduce, lookup = charHist))
}

if(stateNoMax > 10){
  warning("more than 10 states!!!")
}else{
  cat("maximum number of states:", stateNoMax,"\n")
}
DF <- cbind(c("", languages), rbind(meanings, reducedM))

write.table(DF, file = "~/projects/tg/data/tgMultistateReduced.tr.csv", sep = "\t", quote = FALSE, row.names = FALSE, col.names = FALSE)
