#' Convert week numbers to dates or aweek objects
#'
#' These are vectorized functions that take integer vectors and return Date or
#' an aweek objects, making it easier to convert bare weeks to dates. 
#'
#' @param week an integer vector, defaults to 1, representing the first week of the year.
#' @param year an integer vector, defaults to the current year
#' @param day  an integer vector, defaults to 1, representing the first day of
#'   the first week of the year.
#' @param start an integer (or character) vector of days that the weeks
#'   start on for each corresponding week. Defaults to the value of 
#'   [get_week_start()]. Note that these will not determine the final week. 
#' @inheritParams date2week
#' @param ... parameters passed on to [date2week()] 
#' @return
#'  - get_aweek(): an aweek object
#'  - get_date(): a Date object
#'
#' @note Any missing weeks, years, or start elements will result in a 
#'   missing element in the resulting vector. Any missing days will
#'   revert to the first day of the week.
#'   
#' @seealso [as.aweek()] [date2week()] [week2date()]
#' @export
#' @examples
#'
#' # The default results in the first week of the year using the default
#' # default week_start (from get_week_start())
#'
#' get_aweek()
#' get_date() # this is equivalent to as.Date(get_week()), but faster 
#' 
#' # Some years, like 2015, have 53 weeks
#'
#' get_aweek(53, 2015)
#'
#' # If you specify 53 weeks for a year that doesn't have 53 weeks, aweek will
#' # happily correct it for you
#'
#' get_aweek(53, 2014) # this will be 2015-W01-1
#' 
#' # you can use this to quickly make a week without worrying about formatting
#' # here, you can define an observation interval of 20 weeks
#' 
#' obs_start <- get_date(week = 10, year = 2018)
#' obs_end   <- get_date(week = 29, year = 2018, day = 7)
#' c(obs_start, obs_end)
#' 
#' # If you have a data frame of weeks, you can use it to convert easily
#'
#' mat <- matrix(c(
#'   2019, 11, 1, 7, # 2019-03-10
#'   2019, 11, 2, 7,
#'   2019, 11, 3, 7,
#'   2019, 11, 4, 7,
#'   2019, 11, 5, 7,
#'   2019, 11, 6, 7,
#'   2019, 11, 7, 7
#' ), ncol = 4, byrow = TRUE)
#'
#' colnames(mat) <- c("year", "week", "day", "start")
#' m <- as.data.frame(mat)
#' m
#' sun <- with(m, get_date(week, year, day, start))
#' sun
#' as.aweek(sun) # convert to aweek starting on the global week_start 
#' as.aweek(sun, week_start = "Sunday") # convert to aweek starting on Sunday
#' 
#' # You can also change starts
#' mon <- with(m, get_aweek(week, year, day, "Monday", week_start = "Monday"))
#' mon
#' as.Date(mon)
#'
#' # If you use multiple week starts, it will convert to date and then to
#' # the correct week, so it won't appear to match up with the original
#' # data frame.
#' 
#' sft <- with(m, get_aweek(week, year, day, 7:1, week_start = "Sunday"))
#' sft
#' as.Date(sft)
get_aweek <- function(
                      week = 1L,
                      year = format(Sys.Date(), "%Y"),
                      day = 1L,
                      start = week_start,
                      week_start = get_week_start(),
                      ...
                     ) {

  week_start <- parse_week_start(week_start)

  date2week(get_date(week = week, year = year, day = day, start = start), 
            week_start = week_start, ...)
}


#' @rdname get_aweek
#' @export
get_date <- function(
                     week = 1L,
                     year = format(Sys.Date(), "%Y"),
                     day  = 1L,
                     start = get_week_start()
                    ) {

  lens <- vapply(list(week, year, day, start), 
                 FUN = length, 
                 FUN.VALUE = integer(1), 
                 USE.NAMES = FALSE)

  if (any(lens == 0)) {
    stop("all arguments must not be NULL")
  }

  # if the week_start is length one, then we can just add it as a week
  # attribute and be done with it. Otherwise, we will have to convert to date
  # and then back to week.
  easy_week <- lens[[4]] == 1

  
  if (is.character(start)) {
    if (easy_week) {
      start <- weekday_from_char(start)
    } else {
      start <- vapply(start, weekday_from_char, integer(1))
    }
  }


  week <- as.integer(week)
  year <- as.integer(year)
  day  <- as.integer(day)
  start <- as.integer(start)

  stop_if_not_weekday(day)
  stop_if_not_weekday(start)
  stop_if_not_valid_week(week)

  # converting to date and then to week
  mat <- matrix(NA_integer_, ncol = 4L, nrow = max(lens))

  colnames(mat) <- c("year", "week", "day", "week_start")
  mat[, "year"] <- year
  mat[, "week"] <- week
  mat[, "day"]  <- day
  mat[, "week_start"] <- start

  date_from_week_matrix(mat)
}


