# Load the MASS library.

library(MASS)
library(rstanarm)
library(gt)
library(gtsummary)

# A form of weighted least squares (mm estimator; not as efficient, given the
# size of data, but it's going to handle the outlier).

fit_obj <- stan_glm(meanofmeans ~ approval_ratings,
              data = finalgraphtib, 
              refresh = 0)

print(fit_obj, view = FALSE)

# Create a table of the regression results:

tbl_regression(fit_obj) %>%
  as_gt() %>%
  tab_header(title = "Regression of Trump's Twitter Sentiment Scores", 
             subtitle = "The Effect of Approval Ratings on Trump's Twitter Sentiment Score") %>% 
  tab_source_note("Source: Trump Twitter Archive") 

# What sentiment score would we expect on 3 different days, with Donald Trump's
# approval rating at 30%, 45%, and 60%, respectively?

new <- tibble(approval_ratings = c(0.30, 0.45, 0.60))

set.seed(27)
pp <- posterior_predict(fit_obj, newdata = new) %>%
  as_tibble() %>%
  mutate_all(as.numeric)

head(pp, 10)

approvalratingdistribution <- pp %>% 
  rename(`30` = `1`) %>% 
  rename(`45` = `2`) %>% 
  rename(`60` = `3`) %>% 
  pivot_longer(cols = `30`:`60`,
               names_to = "parameter",
               values_to = "score") %>%
  ggplot(aes(x = score, fill = parameter)) +
  geom_histogram(aes(y = after_stat(count/sum(count))), 
                 alpha = 0.7,
                 bins = 100,
                 color = "white",
                 position = "identity") +
  labs(title = "Posterior Distributions for Sentiment Score",
       subtitle = "We have a much more precise estimate for a hypothetical Trump 
       with a 45% approval rating, given the data",
       x = "Sentiment Score",
       y = "Proportion") +
  scale_y_continuous(labels = scales::percent_format()) +
  scale_fill_manual(name = "Approval Rating",
                    values = c("dodgerblue", "salmon", "green")) +
  theme_bw()

approvalratingdistribution

# Read in stock data (another variable that could potentially influence Trump's
# daily Twitter score/can serve as a control).

stock_data <- read_csv("data/current_stock_data.csv")

# (Substantially) clean (yikes!) and subset the data to the relevant date range.

colnames(stock_data) <- c("Date", 
                "open", 
                "high",
                "low",
                "close")

stock_data <- stock_data[-1, ]


updated_stock_data <- stock_data %>%
  mutate(id = 1:4245) %>%
  filter(id >= 4203 & id <= 4225) %>%
  mutate(newdates = as.Date(Date, "%m/%d/%Y")) %>%
  mutate(open = as.numeric(open)) %>%
  mutate(high = as.numeric(high)) %>%
  mutate(low = as.numeric(low)) %>%
  mutate(close = as.numeric(close)) %>%
  mutate(range = high - low) %>%
  select(newdates, open, high, low, close, range) %>%
  add_row(newdates = as.Date("09/12/2020", "%m/%d/%Y"), 
          open = 28.6,
          high = 29.7,
          low = 26.5,
          close = 26.9,
          range = 3.22,
          .before = 2) %>%
  add_row(newdates = as.Date("09/13/2020", "%m/%d/%Y"), 
          open = 28.6,
          high = 29.7,
          low = 26.5,
          close = 26.9,
          range = 3.22,
          .before = 3) %>%
  add_row(newdates = as.Date("09/19/2020", "%m/%d/%Y"), 
          open = 26.6,
          high = 28.1,
          low = 25.3,
          close = 25.8,
          range = 2.82,
          .before = 9) %>%
  add_row(newdates = as.Date("09/20/2020", "%m/%d/%Y"), 
          open = 26.6,
          high = 28.1,
          low = 25.3,
          close = 25.8,
          range = 2.82,
          .before = 10) %>%
  add_row(newdates = as.Date("09/26/2020", "%m/%d/%Y"), 
          open = 28.17,
          high = 30.43,
          low = 26.02,
          close = 26.38,
          range = 4.41,
          .before = 16) %>%
  add_row(newdates = as.Date("09/27/2020", "%m/%d/%Y"), 
          open = 28.17,
          high = 30.43,
          low = 26.02,
          close = 26.38,
          range = 4.41,
          .before = 17) %>%
  add_row(newdates = as.Date("10/03/2020", "%m/%d/%Y"), 
          open = 28.87,
          high = 29.90,
          low = 26.93,
          close = 27.63,
          range = 2.97,
          .before = 23) %>%
  add_row(newdates = as.Date("10/04/2020", "%m/%d/%Y"), 
          open = 28.87,
          high = 29.90,
          low = 26.93,
          close = 27.63,
          range = 2.97,
          .before = 24) %>%
  add_row(newdates = as.Date("10/10/2020", "%m/%d/%Y"), 
          open = 26.20,
          high = 26.22,
          low = 24.03,
          close = 25.00,
          range = 2.19,
          .before = 30) %>%
  add_row(newdates = as.Date("10/11/2020", "%m/%d/%Y"), 
          open = 26.20,
          high = 26.22,
          low = 24.03,
          close = 25.00,
          range = 1.51,
          .before = 31)


final_stock_data <- updated_stock_data[-1, ]

finalstocktib <- inner_join(finalgraphtib, final_stock_data, by = "newdates")
