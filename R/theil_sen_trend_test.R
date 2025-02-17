#' Function to test a time series with the Theil-Sen estimator. 
#' 
#' @param df Input data frame, containing time series observations. 
#' 
#' @param variable Variable name to test. 
#' 
#' @param deseason Should the time series be deseaonsalised before the trend 
#' test is conducted?
#' 
#' @param alpha Confidence interval of the slope, default is 0.05 for 95 \%
#' confidence intervals.  
#' 
#' @param auto_correlation Should auto correlation be considered in the 
#' estimates?
#' 
#' @seealso \code{\link{TheilSen}}
#' 
#' @return Tibble with one observation/row. 
#' 
#' @author Stuart K. Grange.
#' 
#' @export
theil_sen_trend_test <- function(df, variable = "value", deseason = FALSE, 
                                 alpha = 0.05, auto_correlation = FALSE) {
  
  # Trend test errors when one observation is passed
  # Less than three observations results in no p-values and is not a valid procedure
  if (nrow(df) <= 2) {
    warning(
      "Too few observations were supplied, the trend test has not been conducted...",
      call. = FALSE
    )
    return(tibble())
  }
  
  # Get n
  n <- df %>% 
    pull(!!variable) %>% 
    na.omit() %>% 
    length()
  
  # Catch all missing
  if (n == 0) {
    warning(
      "There are no valid observations, the trend test has not been conducted...",
      call. = FALSE
    )
    return(tibble())
  }
  
  # Send plot to dev/null
  pdf(tempfile())
  
  # Do the test without any messages, quiet is for dplyr's progress bar
  quiet(
    df_test <- openair::TheilSen(
      df, 
      pollutant = variable,
      deseason = deseason,
      autocor = auto_correlation,
      avg.time = "month", 
      statistic = "mean",
      alpha = alpha,
      plot = FALSE,
      silent = TRUE
    )$data$res2
  )
  
  dev.off()
  
  # Catch a null, not sure when this is occuring
  if (is.null(df_test)) {
    warning("Trend tested returned NULL...", call. = FALSE)
    return(tibble())
  }
  
  # Clean names of returned data frame, remove duplicates and add date variables
  df_test <- df_test %>% 
    setNames(stringr::str_replace_all(names(.), "\\.", "_")) %>% 
    filter(is.finite(conc)) %>% 
    mutate(date_start = min(df$date), 
           date_end = max(df$date)) %>% 
    as_tibble()
  
  # Add p-value if it is not there
  if (!"p" %in% names(df_test)) df_test$p <- NA_real_
  
  # Select variables
  df_test <- df_test %>% 
    mutate(n = n,
           auto_correlation = auto_correlation,
           deseason = deseason,
           alpha = alpha) %>% 
    select(date_start,
           date_end,
           n,
           auto_correlation,
           alpha,
           deseason,
           p_value = p,
           intercept,
           intercept_lower,
           intercept_upper,
           slope, 
           slope_lower = lower,
           slope_upper = upper)
  
  return(df_test)
  
}


quiet <- function(x) {
  sink(tempfile())
  on.exit(sink())
  invisible(force(x))
}
