library(dplyr)
library(stringr)

library(ggplot2)
library(ggridges)
library(khroma)

source(here::here("src/make_data", "func_wrangle.R"))

# create custom plotting theme
theme_custom <- theme(plot.title = element_text(face = "bold", hjust = 0.5),
                      panel.background = element_blank(),
                      axis.line = element_line(colour = "black"),
                      legend.position = "bottom",
                      legend.direction = "horizontal")

# Load and Wrangle --------------------------------------------------------
data_bq <- readRDS(file = here::here("data", "bg_pgviews_devicecategory.RDS"))
data_bq <- func_wrangle(data = data_bq)

# compute proportions
data_bq <- data_bq %>%
  # filter out earlier dates to get more focussed plots
  filter(date >= as.Date("2019-02-21")) %>% 
  group_by(date, date_period, datetime_hour, deviceCategory) %>% 
  # sum of all pageviews for each day-hour for each category
  summarise(total_pageviews = sum(x = pageviews)) %>%
  # calculate proportion of hourly pageviews by category  
  mutate(prop_pageviews = total_pageviews/(sum(x = total_pageviews)))


# Plot --------------------------------------------------------------------

  # Plot: Time ---------------------------------------------------------------
data_timeplot <- data_bq %>% 
  group_by(date, deviceCategory) %>% 
  summarise(total_pageviews = sum(x = total_pageviews)) %>% 
  mutate(prop_pageviews = total_pageviews/sum(x = total_pageviews))

plot_devicecategory <- ggplot(data = data_timeplot, mapping = aes(x = date, y = prop_pageviews, colour = deviceCategory)) +
  geom_line() +
  geom_vline(xintercept = as.Date(c("2019-12-20", "2020-03-15")),
             linetype = "dotted", colour = "black", size = 0.5) +
  labs(title = "Time Plot of GOV.UK Daily Shares of Pageviews by Device Category", 
       x = "Date", 
       y = "Share of page views",
       colour = guide_legend(title = "Key:")) +
  scale_colour_bright() +
  theme_custom

# save to 16:9 aspect ratio suitable for full-bleed slides
ggsave(filename = "reports/figures/devicecategory_time_all.jpg", plot = plot_devicecategory, width = 9, height = 5.0625, units = "in")


  # Plot: Density ------------------------------------------------------------
n_categories <- n_distinct(x = data_bq$deviceCategory)

plot_devicecategory <- data_bq %>%
  # fill shades change according to x-values
  ggplot(mapping = aes(x = prop_pageviews, y = date_period, fill = stat(x))) + 
  geom_density_ridges_gradient(quantile_lines = TRUE, quantiles = 2, scale = 0.9) +
  scale_fill_YlOrBr() +
  scale_y_discrete(expansion(mult = c(0.01, 1))) +
  scale_x_continuous(expand = c(0,0)) +
  coord_cartesian(clip = "off") +
  facet_wrap(reformulate(termlabels = "deviceCategory"), ncol = n_categories) +
  labs(
    x = "Share of hourly page views",
    y = "Year and month",
    title = paste("Density Distribution Plot of GOV.UK Hourly Shares of Pageviews by Device Category")) +
  theme_custom +
  theme(axis.title.y = element_blank())

# save to 16:9 aspect ratio suitable for full-bleed slides
ggsave(filename = "reports/figures/devicecategory_density_all.jpg", plot = plot_devicecategory, width = 9, height = 5.0625, units = "in")
