# loading necessary libraries
library(readr)
library(tidyr)
library(dplyr)
library(stringr)
library(ggplot2)
library(lubridate)


# loading account_info data set
account_info <- read.csv("C:\\Users\\stalo\\Documents\\R Projects\\Fit.ly_churn project\\da_fitly_account_info.csv")
account_info

glimpse(account_info)

#looking at the structure of the account_info data set
str(account_info)

View(account_info)

# DATA CLEANING AND VALIDATION ON account_info

# converting the plan character variables to factors
factor_vars <- c("plan")
account_info[factor_vars] <- lapply(account_info[factor_vars], as.factor)

str(account_info)

# Y represents people marked as churned on the initial churn_status in the account_info dataset
# Blank rows on the churn_status column represents people marked as not churned
# using 1 for people marked as churned and 0 for not churned

account_info <- account_info %>%
  mutate(churn_status = if_else(churn_status == "Y", 1, 0))

str(account_info)

summary(account_info)

# checking for duplicates in the customer_id column
any(duplicated(account_info$customer_id))

# checking for duplicates in the email column
any(duplicated(account_info$email))

# checking for non - US locations
unique(account_info$state)

# Create user_id from customer_id (remove "C" and convert to integer)
account_info <- account_info %>%
  mutate(
    user_id = as.integer(gsub("^C", "", customer_id))
  )

# Check for duplicates in user_id column
duplicates <- account_info %>%
  group_by(user_id) %>%
  filter(n() > 1) %>%
  nrow()
cat(sprintf("Duplicate user_ids in account_info: %d\n", duplicates))

# looking for missing values in the plan_list_price column, account_info data set
sum(is.na(account_info$plan_list_price))


View(account_info)

str(account_info)


# loading the customer_support data set
customer_support <- read.csv("C:\\Users\\stalo\\Documents\\R Projects\\Fit.ly_churn project\\da_fitly_customer_support.csv")
customer_support

glimpse(customer_support)
str(customer_support)

# DATA CLEANING AND VALIDATION ON customer_support

# Identify GDPR requests
gdpr_keywords <- c('erase', 'deletion', 'remove', 'forget', 'GDPR', 'erased', 'Delete', 'forgotten', 'Erase', 'Remove', 'Wipe', 'delete')
gdpr_pattern <- paste(gdpr_keywords, collapse = "|")

customer_support <- customer_support %>%
  mutate(
    is_gdpr_request = grepl(gdpr_pattern, 
                            tolower(comments), 
                            ignore.case = TRUE) & !is.na(comments)
  )

gdpr_count <- sum(customer_support$is_gdpr_request, na.rm = TRUE)
cat(sprintf("\nGDPR-related requests identified: %d\n", gdpr_count))



#gdpr_pattern <-"Please erase my information.|Request deletion of all records.|Pursuing GDPR erasure request.|GDPR erasure request submission.|Request full personal data deletion.|I want all data erased.|Delete any data about me.|Erase my data from your systems.|Request account and data deletion.|Delete my information entirely.|Requesting right to be forgotten.|Request to remove my data.|Erase all my user data.|Please delete all my personal data.|Wipe all data you hold.|Remove all information about me.|Erase my customer profile.|Remove my stored personal details.|Remove my personal records."

#customer_support <- customer_support[!grepl(gdpr_pattern, customer_support$comments,ignore.case = TRUE),]

str(customer_support)
View(customer_support)

# renaming rows with - in the channel column to unknown

customer_support <- customer_support %>%
  mutate(channel = if_else(channel =="-", "unknown", channel))

#checking the changes
table(customer_support$channel)

View(customer_support)

# converting the complex timestamp in the ticket_time column to a simple date for easy grouping
customer_support <- customer_support %>%
  mutate(
    # convert the string to a real Date-Time object
    ticket_timestamp = ymd_hms(ticket_time),
    
    # Extract just the Date (useful for grouping)
    ticket_date = as.Date(ticket_timestamp)
  )

View(customer_support)

# checking for duplicates in the user_id column, customer_support table
any(duplicated(customer_support$user_id))


# checking for inconsistencies in the topic column, customer_support table
table(customer_support$topic)

# Count how many rows have negative time in the resolution_time_hours column
sum(customer_support$resolution_time_hours < 0, na.rm = TRUE)



# loading the user_activity table
user_activity <- read.csv("C:\\Users\\stalo\\Documents\\R Projects\\Fit.ly_churn project\\da_fitly_user_activity.csv")
user_activity

View(user_activity)

# DATA CLEANING AND VALIDATION ON user_activity

#converting values in the event_time column, user_activity data set to real dates
user_activity <- user_activity %>%
  mutate(event_date = ymd_hms(event_time))


# View the frequency of every unique event in the event_type column, user_activity data set
table(user_activity$event_type)

# looking for missing values in the user_id column, user_activity data set
sum(is.na(user_activity$user_id))

# AGGREGATION

# Aggregate support tickets
tickets_per_user <- customer_support %>%
  group_by(user_id) %>%
  summarise(
    ticket_count = n(),
    avg_resolution_hours = mean(resolution_time_hours, na.rm = TRUE),
    median_resolution_hours = median(resolution_time_hours, na.rm = TRUE),
    resolved_count = sum(state == 1, na.rm = TRUE),
    unresolved_count = sum(state == 0, na.rm = TRUE),
    has_gdpr_request = any(is_gdpr_request, na.rm = TRUE),
    .groups = "drop"
  )

# Aggregate user activity

# Overall activity metrics
activity_per_user <- user_activity %>%
  group_by(user_id) %>%
  summarise(
    total_events = n(),
    first_activity = min(event_time),
    last_activity = max(event_time),
    .groups = "drop"
  ) %>%
  mutate(
    days_active = as.numeric(difftime(last_activity, first_activity, units = "days")) + 1,
    events_per_day = total_events / days_active
  )


# MERGING TABLES

# merge account_info with support data
merged_data <- account_info %>%
  left_join(tickets_per_user, by = "user_id")

# Count how many customers matched
customers_with_tickets <- sum(!is.na(merged_data$ticket_count))
cat(sprintf("Customers with support tickets: %d out of %d\n",
            customers_with_tickets, nrow(merged_data)))

# Fill NA with 0 for customers with no tickets
merged_data <- merged_data %>%
  mutate(
    ticket_count = ifelse(is.na(ticket_count), 0, ticket_count),
    resolved_count = ifelse(is.na(resolved_count), 0, resolved_count),
    unresolved_count = ifelse(is.na(unresolved_count), 0, unresolved_count),
    has_gdpr_request = ifelse(is.na(has_gdpr_request), FALSE, has_gdpr_request),
    has_tickets = ticket_count > 0
  )

cat("Created binary indicator: has_tickets\n")
cat(sprintf("  - With tickets: %d\n", sum(merged_data$has_tickets)))
cat(sprintf("  - Without tickets: %d\n", sum(!merged_data$has_tickets)))


# Merge with activity data
merged_data <- merged_data %>%
  left_join(activity_per_user, by = "user_id")

# Count how many customers matched
customers_with_activity <- sum(!is.na(merged_data$total_events))
cat(sprintf("Customers with activity records: %d out of %d\n",
            customers_with_activity, nrow(merged_data)))

# Fill NA with 0 for customers with no activity
activity_cols <- c("total_events", "days_active", "events_per_day")
for (col in activity_cols) {
  if (col %in% names(merged_data)) {
    merged_data[[col]][is.na(merged_data[[col]])] <- 0
  }
}

# Fill NA with 0 for event type columns
for (col in event_type_cols) {
  if (col %in% names(merged_data)) {
    merged_data[[col]][is.na(merged_data[[col]])] <- 0
  }
}

# Create binary indicator
merged_data <- merged_data %>%
  mutate(has_activity = total_events > 0)

cat("Created binary indicator: has_activity\n")
cat(sprintf("  - With activity: %d\n", sum(merged_data$has_activity)))
cat(sprintf("  - Without activity: %d\n", sum(!merged_data$has_activity)))


View(merged_data)

# CHURN ANALYSIS

# Basic churn statistics
overall_stats <- merged_data %>%
  summarise(
    total_customers = n(),
    churned = sum(churn_status == 1),
    active = sum(churn_status == 0),
    churn_rate = (churned / total_customers) * 100
  )

View(overall_stats)



# bar plot showing number of customers using each plan
ggplot(merged_data, aes(plan, fill = plan)) +
  geom_bar() +
  theme_classic() +
  labs(title = "Number of customers using each plan",
       y = "number of customers",
       x = "plan type")

# histogram showing distribution of subscription price paid by customers
paid_customers <- merged_data %>%
  filter(plan != "Free")

ggplot(paid_customers, aes(plan_list_price)) +
  geom_histogram(binwidth = 15) +
  labs(title = "Distribution of subscriprition prices paid by customers",
       x = "subscription price")



# churn by plan type
churn_by_plan <- merged_data %>%
  group_by(plan) %>%
  summarise(
    total_customers = n(),
    churned = sum(churn_status == 1),
    active = sum(churn_status == 0),
    churn_rate = (churned/total_customers) * 100,
    avg_price = mean(plan_list_price),
    .groups = "drop"
  ) %>%
  arrange(desc(churn_rate))

View(churn_by_plan)

# visualizing churn by plan type
ggplot(churn_by_plan, aes(x = plan, y = churned, fill = plan)) +
  geom_col()

# bar plot showing churn rate by plan type
ggplot(churn_by_plan, aes(x = plan, y = churn_rate, fill = plan)) +
  geom_col() +
  labs(title = "Churn Rate by Plan Type",
       x = "Plan Type",
       y = "Churn Rate (%)")

# churn by engagement level

# Binary: Has activity or not
churn_by_activity_binary <- merged_data %>%
  group_by(has_activity) %>%
  summarise(
    total_customers = n(),
    churned = sum(churn_status == 1),
    churn_rate = (churned / total_customers) * 100,
    avg_events = mean(total_events),
    avg_events_per_day = mean(events_per_day, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(
    activity_status = ifelse(has_activity, "With Activity", "No Activity"),
    activity_status = factor(activity_status, levels = c("No Activity", "With Activity"))
  )

View(churn_by_activity_binary)

# bar plot showing churn rate by customer engagement
ggplot(churn_by_activity_binary, aes(x = activity_status, y = churn_rate,
                                     fill = activity_status)) +
  geom_bar(stat = "identity", width = 0.6) +
  labs(title = "Churn Rate by Customer Engagement",
       x = "Engagement Status",
       y = "Churn Rate (%)")


# Support Contact Analysis
support_details <- merged_data %>%
  group_by(has_tickets) %>%
  summarise(
    total_customers = n(),
    churned = sum(churn_status == 1),
    churn_rate = (churned / total_customers) * 100,
    .groups = "drop"
  ) %>%
  mutate(
    support_status = ifelse(has_tickets, "Contacted support", "No contact"),
    support_status = factor(support_status, levels = c("No contact", "Contacted support"))
  )

View(support_details)

# bar plot showing churn rate by contact support status
ggplot(support_details, aes(x = support_status, y = churn_rate,
                                     fill = support_status)) +
  geom_bar(stat = "identity", width = 0.6) +
  labs(title = "Churn Rate by contact support status",
       x = "Contact Support Status",
       y = "Churn Rate (%)")



# Create engagement level categories
merged_data <- merged_data %>%
  mutate(
    engagement_level = case_when(
      total_events == 0 ~ "No Activity",
      total_events <= 2 ~ "Very Low",
      total_events <= 5 ~ "Low",
      total_events <= 10 ~ "Medium",
      TRUE ~ "High"
    ),
    engagement_level = factor(engagement_level, levels = c(
      "No Activity", "Very Low", "Low", 
      "Medium", "High"
    ))
  )

churn_by_engagement <- merged_data %>%
  group_by(engagement_level) %>%
  summarise(
    total_customers = n(),
    churned = sum(churn_status == 1),
    churn_rate = (churned / total_customers) * 100,
    avg_events = mean(total_events),
    .groups = "drop"
  )

View(churn_by_engagement)


# detailed engagement levels
ggplot(churn_by_engagement, 
               aes(x = engagement_level, y = churn_rate, fill = engagement_level)) +
    geom_bar(stat = "identity", width = 0.7) +
  labs(title = "Churn Rate by Engagement Level (Detailed)",
       x = "Engagement Level",
       y = "Churn Rate (%)") +
  theme_minimal(base_size = 12)


# GDPR request analysis

if ("has_gdpr_request" %in% names(merged_data)) {
  gdpr_summary <- merged_data %>%
    summarise(
      total_with_gdpr = sum(has_gdpr_request, na.rm = TRUE),
      pct_of_all_customers = mean(has_gdpr_request, na.rm = TRUE) * 100,
      all_gdpr_churned = sum(has_gdpr_request & churn_status == 1, na.rm = TRUE)
    )
  
  cat(sprintf("Customers with GDPR requests: %d (%.1f%% of all customers)\n",
              gdpr_summary$total_with_gdpr,
              gdpr_summary$pct_of_all_customers))
  cat(sprintf("GDPR requesters who churned: %d\n", gdpr_summary$all_gdpr_churned))
} else {
  cat("GDPR request data not available in merged dataset\n\n")
}

