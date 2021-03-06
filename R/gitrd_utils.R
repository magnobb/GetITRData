#' Converts a dataframe from gitr_GetITRData to the wide format
#'
#' @param data.in Data frame with financial information
#' @param data.in.cols Which data to go in rows values ('original' or 'inflation adjusted')
#'
#' @return A dataframe in the wide format
#' @export
#'
#' @examples
#'
#' # get example data from RData file
#' my.f <- system.file('extdata/ExampleReport_Petrobras.RData', package = 'GetITRData')
#' load(my.f)
#'
#' df.assets <- df.reports$fr.assets[[1]]
#' df.assets.wide <- gitrd.convert.to.wide(df.assets)
gitrd.convert.to.wide <- function(data.in, data.in.cols = 'original') {

  possible.types <- c('original','inflation adjusted')
  if ( !any(data.in.cols %in% possible.types) ) {
    stop('ERROR: input data.in.cols must be either "original" or "inflation adjusted"')
  }

  if (!any('data.frame' %in% class(data.in))) {
    stop('input data.in does not seems to be a dataframe..')
  }

  value.var <- switch(data.in.cols,
                      'original' = 'acc.value',
                      'inflation adjusted' =  'acc.value.infl.adj')

  df.wide <- reshape2::dcast(data = data.in,
                   formula = acc.number + acc.desc + company.name  ~ ref.date,
                   value.var = value.var, fill = 0)

  return(df.wide)

}

#' Helps users search for a company name
#'
#' @param char.to.search Character for partial matching
#'
#' @return Names of found companies
#' @export
#'
#' @examples
#'
#' \dontrun{ # dontrun: keep cran check fast
#' gitrd.search.company('GERDAU')
#' }
gitrd.search.company <- function(char.to.search) {

  df.info <- gitrd.get.info.companies()

  unique.names <- unique(df.info$name.company)
  char.target <- iconv(stringr::str_to_lower(unique.names),to='ASCII//TRANSLIT')
  char.to.search <- iconv(stringr::str_to_lower(char.to.search),to='ASCII//TRANSLIT')

  idx <- stringr::str_detect(char.target, pattern = stringr::fixed(char.to.search))

  char.out <- stats::na.omit(unique.names[idx])

  temp.df <- unique(df.info[df.info$name.company %in% char.out, c('name.company', 'id.date', 'situation')])

  cat('\n\nFound', length(char.out), 'companies:')

  for (i.company in char.out) {

    temp.df <- df.info[which(df.info$name.company == i.company), ]

    first.date <- min(stats::na.omit(temp.df$id.date))
    last.date  <- max(stats::na.omit(temp.df$id.date))

    cat(paste0('\n', paste0(i.company, paste0(rep(' ', max(nchar(char.out)) - nchar(i.company)),
                                              collapse = '' ),
                            ' | situation = ', temp.df$situation[1],
                            ' | first date = ', first.date,
                            ' | last date - ',  last.date) ) )
  }

  cat('\n\n')

}

#' Reads FWF file from bovespa (internal)
#'
#' @param my.f File to be read
#' @inheritParams gitrd.GetITRData
#' @inheritParams gitrd.read.zip.file
#' @return A dataframe with data
#' @export
#' @examples
#'
#' my.f <- system.file('extdata/ITRBPAE.001', package = 'GetITRData')
#'
#' df.assets <- gitrd.read.fwf.file(my.f, type.fin.report = 'itr')
gitrd.read.fwf.file <- function(my.f, type.fin.report) {

  if (file.size(my.f) ==0 ) {
    df.out <- data.frame(acc.number= NA,
                         acc.desc = NA,
                         acc.value = NA)
    return(df.out)
  }

  # set cols for fwf
  if (type.fin.report == 'itr') {

  my.col.types <- readr::cols(
    acc.number = readr::col_character(),
    acc.desc = readr::col_character(),
    acc.value = readr::col_integer()
  )

  my.col.names<-  c('acc.number', 'acc.desc', 'acc.value')
  my.pos <- readr::fwf_positions(start = c(15, 28, 74), end = c(27, 67, 82),
                                 col_names = my.col.names)

  }

  if (type.fin.report == 'dfp') {

    my.col.types <- readr::cols(
      acc.number = readr::col_character(),
      acc.desc = readr::col_character(),
      acc.value1 = readr::col_integer(),
      acc.value2 = readr::col_integer(),
      acc.value = readr::col_integer()
    )

    my.col.names<-  c('acc.number', 'acc.desc', 'acc.value1','acc.value2','acc.value')
    my.pos <- readr::fwf_positions(start = c(15, 28, 74,89,89+14+1), end = c(27, 67, 82,97,112),
                                   col_names = my.col.names)

  }

  df.out <- readr::read_fwf(my.f, my.pos,
                               locale = readr::locale(encoding = 'Latin1'), col_types =  my.col.types)


  if (type.fin.report == 'dfp') {
    df.out <- df.out[, c('acc.number', 'acc.desc', 'acc.value')]
  }
  # fix for empty data
  if (nrow(df.out) == 0) {
    df.out <- tibble::tibble(acc.number = NA,
                             acc.desc = NA,
                             acc.value = NA)
  }

  return(df.out)

}
