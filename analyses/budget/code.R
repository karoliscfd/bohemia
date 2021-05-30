library(dplyr)
library(gsheet)
library(databrew)
library(ggplot2)
url <- 'https://docs.google.com/spreadsheets/d/1Rf12eBUL4-NnwLtJTm8n0v3_cfWN8_b7nNdkR37IzCA/edit#gid=1700791765'

df <- gsheet2tbl(url)
out <- df[,c(1,8:10)]
databrew::prettify(out, nrows = nrow(out))

# Example plot

# grand total
gt <- out[nrow(out), ((ncol(out)-2):ncol(out))]
names(gt) <- c('lwr', 'pt', 'upr')
# Get monthly
monthly <- gt / 8

# Make dataframe
ts <- tibble(date = seq(as.Date('2021-05-15'), as.Date('2022-12-15'), by = 'month'))
ts$n <- 1:nrow(ts)
ts$lwr <- ts$n * monthly$lwr
ts$pt <- ts$n * monthly$pt
ts$upr <- ts$n * monthly$upr

options(scipen = '999')
ts <- ts %>% filter(date <= '2021-12-31')

# Example of actual expenditure
ts$real <- c(8000, 20100, 28000, 31000, 45000, 49000, NA, NA) * 1.3
ggplot(data = ts) +
  geom_ribbon(aes(x = date,
                  ymin = lwr,
                  ymax = upr),
              fill = 'darkorange',
              alpha = 0.6) +
  theme_bw() +
  geom_line(aes(x = date,
                y = pt)) +
  geom_line(aes(x = date,
                y = real),
            color = 'red') + 
  geom_point(aes(x = date,
                y = real),
            color = 'red') +
  scale_y_continuous(breaks = seq(0, max(ts$upr), by = 20000)) +
  labs(x = 'Month', y = 'Cumulative USD',
       title = 'Actual vs projected expenditures',
       subtitle = 'Illustrative purposes only')


