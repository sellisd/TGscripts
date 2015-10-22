# do not read languages as header to preserve the Unicode
ga <- read.csv("~/projects/tg/chapacuran/chapacura-207-GA.csv", sep = "\t", as.is = TRUE, header = FALSE)
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
  stop(paste("emtpy line", which(emptyLineB)))
}
# check if states are unique for each meaning
for(m in meanings){
  #m <- meanings[1]
  setLetters <- ga[which(ga[,2] == m), 3]
  if(!isTRUE(all.equal(setLetters,LETTERS[1:length(setLetters)]))){
    stop(paste("problem with set values at",m))
  }
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
write.table(multistate2save, file = "~/projects/tg/chapacuran/chMultistate.tr.tab", sep = "\t", quote = FALSE, row.names = FALSE, col.names = FALSE)
