# Install tabulizer package (requires a local installation of Java)
# devtools::install_github("ropensci/tabulizer")
library(tabulizer)
library(tidyverse)
library(janitor)

# WHO mpox sitrep example
# this is a relatively simple example
#who_pdf <- "https://www.who.int/docs/default-source/coronaviruse/situation-reports/20230919_mpox__external-sitrep-28.pdf"
who_pdf <- "Examples/20230919_mpox__external-sitrep-28.pdf"
t_who_raw <- extract_tables(who_pdf, output="matrix")
t_who_clean <-
  t_who_raw[[9]] %>%
  rbind(t_who_raw[[10]]) %>%
  rbind(t_who_raw[[11]]) %>%
  as_tibble() %>%
  row_to_names(row_number = 1) %>%
  clean_names() %>%

  # Fix Region Names (most problematic column)
  mutate(who_region = trimws(gsub("Region","", who_region))) %>%
  mutate(who_region = if_else(who_region=="",NA,as.character(who_region))) %>%
  fill(who_region) %>%
  mutate(who_region = case_when(who_region %in% c("African","Eastern Mediterranean","European","South-East Asia","Western Pacific") ~ paste0(who_region, " Region"),
                                who_region %in% "of the Americas" ~ paste0("Region ",who_region),
                                who_region %in% "Cumulative" ~ who_region)) %>%

  # Fix country column
  mutate(country = gsub("*","",country,fixed=T)) %>%

  # Fix numeric columns
  mutate(total_confirmed_cases = as.numeric(gsub(" ","",total_confirmed_cases))) %>%
  mutate(total_deaths_number = as.numeric(gsub(" ","",total_deaths_number)))


# PDF-1
# First table on page 4
pdf_1 <- "Examples/PDF-1.pdf"
t_1_raw <- extract_tables(pdf_1, output="matrix")
str(t_1_raw)
t_1_raw[[4]]
t_1_raw_headers <- t_1_raw[[4]][1:2,] %>%
  t() %>%
  as_tibble() %>%
  unite(name, c("V1","V2"), sep=" ") %>%
  mutate(name = trimws(name)) %>%
  pluck("name")
t_1_raw_headers
t_1_clean <-
  t_1_raw[[4]] %>%
  as_tibble() %>%
  tail(-2)
names(t_1_clean) <- t_1_raw_headers
t_1_clean
t_1_clean <- t_1_clean %>%
  mutate(across(c(`New Tests (last 7 Days)`,
                  `New Tests (last 8-14 Days)`,
                  `Test/100K/ Week`,
                  `Test/Case`),
                ~ as.numeric(gsub('\\s','',.x))),
         across(c(`% change in new tests`,
                  `% of new tests`,
                  `Test Positivity`,
                  `% change in test positivity`),
                ~ as.numeric(gsub('%','',.x,fixed=T))))
t_1_clean

# PDF-4
# Bangladesh Quarantine Isolation Report
# This is a VERY difficult example
pdf_4 <- "Examples/PDF-4 (confidential).pdf"
get_page_dims(pdf_4, pages=1) %>% unlist()
t_4_raw <- extract_tables(pdf_4, encoding="UTF-8", area=list(c(175,0,595,842)), pages=1, guess=FALSE)
t_4_clean <-
  t_4_raw[[1]] %>%
  as_tibble()
