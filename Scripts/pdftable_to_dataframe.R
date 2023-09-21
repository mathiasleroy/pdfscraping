
pacman::p_load(dplyr, pdftools, stringr)

### DESCRIPTION -----
## This function parses pdf as text and splits values into colums using a regex (default: min 2 spaces)
## it then converts the results into a dataframe and returns that
## the benefits of this approach is speed, being able to run in ms per pdf, 
## this solution would be appropriate big lists of daily/weekly pdf's for example

### ADVANTAGES -----
## - no complicated packages (tabulizer is not easy to isntall, requires java)
## - modifiable regex for column splits
## - quite fast
## - built-in loop over multiple files -> returns 1 dataframe for all the pdfs
## - treating all as text; doesn't parse numbers (can be done by user after the extract)

### ISSUES -----
## 1. it's a bit hard to guess from scratch what to set as start and end lines work -> could make a helper function to search a text and return the line of occurence
##    but since it runs super fast (~instant) it's easy to try 1-990 and refine afterwards
## 2. only extracts lines that have a value in each column -> summary totals are sometimes not kept + some tables have large blanks which are undetecable (changing regex can solve in some cases)

### PARAMS -----
## - files:           vector of filenames (relative to your wd)
## - keeppages:       vector of numbers of the pages you wan to keep (usually just 1 number)
## - start:           number of the line at which to start scanning for table rows (recommend excluding header)
## - end:             number of the line at which to stop scanning for table roww
## - setcols:         vector of strings to set as names [optional] (default is empty which results into col names x1, x2...)
## - splitcolsregex:  regex to use in the split function that splits columns [optional] (default is "\\s{2,}")
## - debug:           bool or number | FALSE: no prints ; TRUE: Prints the rows after splitting ; 2: prints also the rows before splitting

pdftable_to_dataframe = function(files, keeppages, start, end, setcols=c(), splitcolsregex="\\s{2,}", debug=FALSE){
  if(debug) print(paste('going to extract' ,length(files), "file(s)"))
  
  for(file_i in 1:length(files)){
    file = files[file_i] 
    # print(paste0('file #', file_i, ': ', file))
    
    pages = pdf_text(file)                      ## EXTRACT ALL TEXT INTO PAGES
    # print(paste('pages:',length(pages)))
    pages = pages[keeppages]                    ## TRIM SELECTED PAGES
    alltext = paste(pages, collapse = '\n')     ## MERGE ALL PAGES
    # print(alltext)

    lines = alltext %>% strsplit(split="\n")    ## SPLIT INTO LINES
    lines = lines[[1]]                          ## UNLIST
    lines = lines[start:end]                    ## TRIM SELECTED LINES
    if(debug==2) print(lines)
    
    splittedlines = lines%>%strsplit(split=splitcolsregex)          ## SPLIT VALUES INTO COLS (default: 2 or more spaces)
    splittedlines = splittedlines[lapply(splittedlines,length)>0]   ## REMOVE E:PTY LINES
    # if(debug) print(splittedlines)
    
    ### FIND MAX NUMBER OF COLS -----
    ncols = 0
    for (line_j in splittedlines){
      # print(length(line_j))
      if(ncols < length(line_j)) ncols = length(line_j)
    }
    
    
    if(file_i==1) df = data.frame()               ## INIT EMPTY DF
    for (line_i in splittedlines){
      if(debug) print(paste(length(line_i), 'cols: ', paste(line_i, collapse = " | ")))
      if(length(line_i) == ncols ) {              ## KEEP ONLY LINES WITH ALL VALUES (alternative would be to complete vector of values to make sure the length is the same)
        df_i = data.frame(t(line_i))              ## CONVERT TO SINGLE LINE DF
        df = rbind(df, df_i)                      ## APPEND TO MAIN DF
      }
    }
  }
  
  if(debug) print(paste('keeping only row with', ncols, 'columns'))
  
  if(length(setcols) > 0) names(df) = setcols     ## SET COL NAMES
  
  return(df)
}
















# ################# TESTING #####################################

# tic = function(){ start.time <<- Sys.time() }
# # toc = function(){ round(Sys.time() - start.time, 1) }
# toc = function(r=FALSE, v=start.time, round=-1){ 
#   elapsed = difftime(Sys.time(), v, units = "secs")[[1]]
#   if(round>=0) elapsed = round(elapsed, round)
#   if(r==FALSE) cat("<---", round(elapsed), "sec", "--->", "\n")
#   else return(elapsed)
# }
# tic()


# setwd(dirname(rstudioapi::getSourceEditorContext()$path)) ## all files refs are relative to this script location

# ### PDF 1 -----
# pdftable_to_dataframe(c('../Examples/PDF-1.pdf'), 4, 5, 25, c('Division'
#                                                            ,'New Tests (last 7 Days)'
#                                                            ,'New Tests (last 8-14 Days)'
#                                                            ,'Test/100K/Week'
#                                                            ,'% change in new tests'
#                                                            ,'% of new tests'
#                                                            ,'Test Positivity'
#                                                            ,'% change in test positivity'
#                                                            ,'Test/Case')) %>%  ## tbl 1 page 4 --> ok
#   mutate(
#     across(c(`New Tests (last 7 Days)`,
#                   `New Tests (last 8-14 Days)`,
#                   `Test/100K/Week`,
#                   `Test/Case`),
#                 ~ as.numeric(gsub('\\s','',.x))),
#     across(c(`% change in new tests`,
#                   `% of new tests`,
#                   `Test Positivity`,
#                   `% change in test positivity`),
#                 ~ as.numeric(gsub('%','',.x,fixed=T)))
#     )

# pdftable_to_dataframe(c('../Examples/PDF-1.pdf'), 4, 26, 48) ## tbl 2 page 4 --> ok
# pdftable_to_dataframe(c('../Examples/PDF-1.pdf'), 4, 52, 71) ## tbl 3 page 4 --> ok
# pdftable_to_dataframe(c('../Examples/PDF-1.pdf'), 6, 1, 30, debug=2, splitcolsregex="\\s{2,13}") ## tbl 1 page 6 --> 

# ### PDF 2 -----
# pdftable_to_dataframe(c('../Examples/PDF-2.pdf'), 1, 1, 20)    ## table 1 page 1 --> ok
# pdftable_to_dataframe(c('../Examples/PDF-2.pdf'), 1, 25, 35)   ## table 2 page 1 --> ok
# pdftable_to_dataframe(c('../Examples/PDF-2.pdf'), 2, 1, 30)    ## both tables page 2 --> ok
# pdftable_to_dataframe(c('../Examples/PDF-2.pdf'), c(6,7), 1, 999)    ## 1 table on page 6-7 --> ok
# pdftable_to_dataframe(c('../Examples/PDF-2.pdf'), c(8,9,10), 15, 99, splitcolsregex="\\s{2,59}", debug=F)    ## 1 table on page 6-7 
# # --> for this table it is not working well : 
# #     1. first col is a merged cell, this results in creating empty col and only 1 row has the value: not bad, its actually how we want it, there is no better way to deal with merged cells
# #     2. empty cells are not detected: tried to change the regex to a max number of blanks (e.g. splitcolsregex="\\s{2,59}" works best here) but those are not consistent (sometimes 38 blanks are not a column split, sometimes 28 spaces are a column split)


# pdftable_to_dataframe(c('../Examples/20230919_mpox__external-sitrep-28.pdf'), c(17,18,19), 22, 150, debug=2, splitcolsregex="\\s{2,25}") ## tbl page 17 --> not working immediatly, also not with different regexes because different pages have different number of spaces for col delimiters --> could wi=ork if we do it 1 step per page


# toc()

