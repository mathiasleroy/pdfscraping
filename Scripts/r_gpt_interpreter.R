# install.packages("devtools")
devtools::install_github("umatter/OpenAIR")

# load the package
library("TheOpenAIR")

# register your api key
openai_api_key("xxxxxxxxxxxxxxxxxxxxxxxxx")

# use chat() to interact with ChatGPT through the R console
chat("Write R code to extract the 3 tables that are on page 4 of the pdf called Examples/PDF-1.pdf")

#### RESULT :

# # Install required packages
# # install.packages("tabulizer")
# # install.packages("dplyr")
# # Load required libraries
# library(tabulizer)
# library(dplyr)
# # Set the path to the PDF file
# pdf_path <- "Examples/PDF-1.pdf"
# # Extract tables from page 4 of the PDF
# tables <- extract_tables(pdf_path, pages = 4)
# # Adjust tables and convert them to data frames
# df1 <- as.data.frame(tables[[1]], stringsAsFactors = FALSE) %>%
#   mutate_all(trimws)
# df2 <- as.data.frame(tables[[2]], stringsAsFactors = FALSE) %>%
#   mutate_all(trimws)
# df3 <- as.data.frame(tables[[3]], stringsAsFactors = FALSE) %>%
#   mutate_all(trimws)
# # Print the extracted tables
# df1
# df2
# df3


#### ISSUES
# apparently tabulizer in not in cran anymore, and needs to be installed differently: devtools::install_github("ropensci/tabulizer")
# my laptop has java isntalled in 32bit and therefore the installation fails; without admin rigths impossible to fix


