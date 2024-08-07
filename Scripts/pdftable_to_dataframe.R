pacman::p_load(dplyr, pdftools, stringr)
setwd(dirname(rstudioapi::getSourceEditorContext()$path))



#' Convert PDF table to dataframe
#'
#' This function parses PDF as text and splits values into columns using a regex (default: min 2 spaces).
#' It then converts the results into a dataframe and returns that. The benefits of this approach are speed,
#' being able to run in ms per PDF. This solution would be appropriate for big lists of daily/weekly PDFs, for example.
#'
#' @param files Vector of filenames (relative to your working directory)
#' @param keeppages Vector of numbers of the pages you want to keep (usually just 1 number)
#' @param start Number of the line at which to start scanning for table rows (recommend excluding header)
#' @param end Number of the line at which to stop scanning for table rows
#' @param setcols Vector of strings to set as names [optional] (default is empty which results in col names x1, x2...)
#' @param splitcolsregex Regex to use in the split function that splits columns [optional] (default is "\\s{2,}")
#' @param debug Boolean or number | FALSE: no prints ; TRUE: Prints the rows after splitting ; 2: prints also the rows before splitting
#'
#' @return A dataframe containing the extracted table data
#'
#' @details
#' Issues:
#' \enumerate{
#'   \item Doesn't work on table rows that have line return in cells
#'   \item All cells need a value, if a row has an empty cell, that row will be discarded
#'   \item The pages dont always correspong to what is shown in a pdf reader --> suggest to set debug to TRUE and try diffferent values
#'   \item it can be hard to guess at first what to set as start and end lines -> suggest to try many different values
#'   \item Only extracts lines that have a value in each column -> summary totals are sometimes not kept + some tables have large blanks which are undetectable
#'         (changing regex can solve in some cases).
#' }
#' 
#' Advantages:
#' \itemize{
#'   \item Fast
#'   \item No complicated packages (tabulizer is not easy to install, requires Java)
#'   \item Modifiable regex for column splits
#'   \item Built-in loop over multiple files -> returns 1 dataframe for all the PDFs
#'   \item Treating all as text; doesn't parse numbers (can be done by user after the extract)
#'   \item Outputted values are reliable
#' }
#'
#' @import dplyr pdftools stringr
#'
#' @examples
#' \dontrun{
#' # PDF 1 examples
#' result1 <- pdftable_to_dataframe(
#'   c("../Examples/PDF-1.pdf"), 4, 5, 25,
#'   c(
#'     "Division", "New Tests (last 7 Days)",
#'     "New Tests (last 8-14 Days)", "Test/100K/Week",
#'     "% change in new tests", "% of new tests",
#'     "Test Positivity", "% change in test positivity",
#'     "Test/Case"
#'   )
#' ) ## table 1 page 4
#' result1 <- result1 %>%
#'   mutate(
#'     across(
#'       c(
#'         `New Tests (last 7 Days)`, `New Tests (last 8-14 Days)`,
#'         `Test/100K/Week`, `Test/Case`
#'       ),
#'       ~ as.numeric(gsub("\\s", "", .x))
#'     ),
#'     across(
#'       c(
#'         `% change in new tests`, `% of new tests`,
#'         `Test Positivity`, `% change in test positivity`
#'       ),
#'       ~ as.numeric(gsub("%", "", .x, fixed = TRUE))
#'     )
#'   )
#'
#' # More examples from PDF 1
#' pdftable_to_dataframe(c("../Examples/PDF-1.pdf"), 4, 26, 48) # table 2 page 4
#' pdftable_to_dataframe(c("../Examples/PDF-1.pdf"), 4, 52, 71) # table 3 page 4
#' pdftable_to_dataframe(c("../Examples/PDF-1.pdf"), 6, 1, 30, debug = 2, splitcolsregex = "\\s{2,13}") # table 1 page 6
#'
#' # PDF 2 examples
#' pdftable_to_dataframe(c("../Examples/PDF-2.pdf"), 1, 1, 20) # table 1 page 1
#' pdftable_to_dataframe(c("../Examples/PDF-2.pdf"), 1, 25, 35) # table 2 page 1
#' pdftable_to_dataframe(c("../Examples/PDF-2.pdf"), 2, 1, 30) # both tables page 2
#' pdftable_to_dataframe(c("../Examples/PDF-2.pdf"), c(6, 7), 1, 999) # 1 table on page 6-7
#' pdftable_to_dataframe(c("../Examples/PDF-2.pdf"), c(8, 9, 10), 15, 99, splitcolsregex = "\\s{2,59}", debug = FALSE) # 1 table on page 8-10
#'
#' # Example with issues
#' pdftable_to_dataframe(c("../Examples/20230919_mpox__external-sitrep-28.pdf"), c(17, 18, 19), 22, 150, debug = 2, splitcolsregex = "\\s{2,25}") # table page 17 is not working immediatly, also not with different regexes because different pages have different number of spaces for col delimiters --> could work if we do fct call per page
#' 
#' df <- pdftable_to_dataframe(c("../Examples/2015-Second-edition-WHO-style-guide.pdf"), 63:69, 1, 400, setcols = c#' ("Short name", "Full name", "Adjective/People", "Capital city"), debug = FALSE) ## doesnt work on rows with linebreaks
#' df[2, ] ## 'Islamic Republic of' should be 'Islamic Republic of Afghanistan'
#'
#' }
#'
#' @export
pdftable_to_dataframe <- function(files, keeppages, start, end, setcols = c(), splitcolsregex = "\\s{2,}", debug = FALSE) {
  # Input validation
  if (!all(file.exists(files))) {
    stop("One or more specified files do not exist.")
  }
  if (start >= end) {
    stop("'start' must be less than 'end'.")
  }

  if (debug) message("\n", length(files), ifelse(length(files) > 1, " files", " file"), " to process")

  for (ii in 1:length(files)) {
    file_ii <- files[ii]
    if (debug) message("-", ii, ": ", file_ii)

    pages <- pdf_text(file_ii) ## EXTRACT ALL TEXT INTO PAGES
    if (debug) message(length(pages), ifelse(length(pages) > 1, " pages", " page"), " in total")
    pages <- pages[keeppages] ## TRIM SELECTED PAGES
    if (debug) message(length(pages), ifelse(length(pages) > 1, " pages", " page"), " kept")
    alltext <- paste(pages, collapse = "\n") ## MERGE ALL PAGES
    # print(alltext)

    lines <- alltext %>% strsplit(split = "\n") ## SPLIT INTO LINES
    lines <- lines[[1]] ## UNLIST
    lines <- lines[start:end] ## TRIM SELECTED LINES
    # if (debug == 2) print(lines)



    splittedlines <- lines %>% strsplit(split = splitcolsregex) ## SPLIT VALUES INTO COLS (default: 2 or more spaces)
    splittedlines <- splittedlines[lapply(splittedlines, length) > 0] ## REMOVE E:PTY LINES
    # if(debug) print(splittedlines)

    ### FIND MAX NUMBER OF COLS -----
    ncols <- 0
    for (line_j in splittedlines) {
      # print(length(line_j))
      if (ncols < length(line_j)) ncols <- length(line_j)
    }


    if (ii == 1) df <- data.frame() ## INIT EMPTY DF
    for (line_i in splittedlines) {
      if (debug == 2) message(paste('-', length(line_i), "cols: ", paste(line_i, collapse = " | ")))
      if (length(line_i) == ncols) { ## KEEP ONLY LINES WITH ALL VALUES (alternative would be to complete vector of values to make sure the length is the same)
        df_i <- data.frame(t(line_i)) ## CONVERT TO SINGLE LINE DF
        df <- rbind(df, df_i) ## APPEND TO MAIN DF
      }
    }
  }

  if (debug) message("keeping only rows with ", ncols, " values")

  if (length(setcols) == ncol(df)) names(df) <- setcols ## SET COL NAMES

  if (debug) df %>% glimpse()

  return(df)
}






### MEASURE SPEED -----

# tic = function(){ start.time <<- Sys.time() }
# # toc = function(){ round(Sys.time() - start.time, 1) }
# toc = function(r=FALSE, v=start.time, round=-1){
#   elapsed = difftime(Sys.time(), v, units = "secs")[[1]]
#   if(round>=0) elapsed = round(elapsed, round)
#   if(r==FALSE) cat("<---", round(elapsed), "sec", "--->", "\n")
#   else return(elapsed)
# }
# tic()
# toc()
