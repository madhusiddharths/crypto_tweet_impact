# =============================================================================
# Bitcoin Tweet-Effects Dashboard
# -----------------------------------------------------------------------------
# An interactive Shiny app for exploring how individual Elon Musk Bitcoin tweets
# relate to subsequent BTC price action. For each tweet it shows the text, the
# 30-day forward price path, and the realized 1-/7-/30-day returns.
#
# Run from the repository root:
#     shiny::runApp("dashboard")
# or from this directory:
#     shiny::runApp()
#
# Data dependencies (resolved relative to the repo root):
#   data/processed/BTC_USD_data_2013_to_present.csv
#   data/processed/sentiment_classified.csv
#   data/raw/tweet_text_metadata.csv   (large, git-ignored; see data/README.md)
# =============================================================================

library(shiny)
library(dplyr)
library(ggplot2)
library(readr)

# --- Locate the data directory whether the app is launched from the repo root
#     or from within dashboard/ -------------------------------------------------
data_dir <- if (dir.exists("data")) "data" else file.path("..", "data")
processed <- function(f) file.path(data_dir, "processed", f)
raw       <- function(f) file.path(data_dir, "raw", f)

# --- Load and prepare Bitcoin price data -------------------------------------
btc_data <- read_csv(processed("BTC_USD_data_2013_to_present.csv"),
                     show_col_types = FALSE) %>%
  mutate(date = as.Date(date)) %>%
  arrange(date) %>%
  mutate(
    change_usd      = c(NA, diff(close)),
    change_pct      = c(NA, (diff(close) / head(close, -1)) * 100),
    next_day_return = lead(close, 1) / close - 1,
    return_7d       = lead(close, 7) / close - 1,
    return_30d      = lead(close, 30) / close - 1
  )

# --- Load Bitcoin-categorized tweets and join to price data ------------------
bitcoin_tweets <- read_csv(processed("sentiment_classified.csv"),
                           col_types = cols(tweet_id = col_character())) %>%
  filter(category == "Bitcoin") %>%
  transmute(tweet_id, createdAt = as.Date(createdAt), sentiment)

tweet_effects <- btc_data %>%
  left_join(bitcoin_tweets, by = c("date" = "createdAt")) %>%
  filter(!is.na(sentiment))

# --- Attach tweet text (optional: file is large and git-ignored) -------------
text_path <- raw("tweet_text_metadata.csv")
if (file.exists(text_path)) {
  tweet_text <- read_csv(text_path, col_types = cols(tweet_id = col_character())) %>%
    select(tweet_id, fullText)
  tweet_effects <- tweet_effects %>% left_join(tweet_text, by = "tweet_id")
} else {
  tweet_effects$fullText <- NA_character_
  warning("tweet_text_metadata.csv not found; tweet text will be unavailable. ",
          "See data/README.md for how to obtain it.")
}

tweet_ids <- tweet_effects$tweet_id
n_tweets  <- nrow(tweet_effects)

# --- UI -----------------------------------------------------------------------
ui <- fluidPage(
  titlePanel("Bitcoin Tweet-Effects Dashboard"),
  sidebarLayout(
    sidebarPanel(
      width = 3,
      helpText("Browse Elon Musk's Bitcoin-related tweets and inspect the BTC ",
               "price reaction over the following 30 days."),
      actionButton("prev_btn", "← Previous"),
      actionButton("next_btn", "Next →"),
      tags$hr(),
      selectInput("select_tweet_id", "Select Tweet ID:",
                  choices = tweet_ids, selected = tweet_ids[1])
    ),
    mainPanel(
      width = 9,
      h4(textOutput("tweet_id_display")),
      tags$blockquote(textOutput("tweet_text_display")),
      tags$em(textOutput("tweet_date_display")),
      plotOutput("trend_plot"),
      fluidRow(
        column(4, h5("Next-Day Return"), textOutput("next_day_return")),
        column(4, h5("7-Day Return"),    textOutput("return_7d")),
        column(4, h5("30-Day Return"),   textOutput("return_30d"))
      )
    )
  )
)

# --- Server -------------------------------------------------------------------
server <- function(input, output, session) {

  current_index <- reactiveVal(1)

  observeEvent(input$prev_btn, {
    new_val <- max(1, current_index() - 1)
    current_index(new_val)
    updateSelectInput(session, "select_tweet_id", selected = tweet_ids[new_val])
  })

  observeEvent(input$next_btn, {
    new_val <- min(n_tweets, current_index() + 1)
    current_index(new_val)
    updateSelectInput(session, "select_tweet_id", selected = tweet_ids[new_val])
  })

  observeEvent(input$select_tweet_id, {
    idx <- which(tweet_ids == input$select_tweet_id)
    if (length(idx) == 1) current_index(idx)
  })

  pct <- function(x) if (is.na(x)) "n/a" else sprintf("%+.2f%%", x * 100)

  output$tweet_id_display <- renderText(
    paste0("Tweet ID: ", tweet_effects$tweet_id[current_index()])
  )

  output$tweet_text_display <- renderText({
    txt <- as.character(tweet_effects$fullText[current_index()])
    if (length(txt) == 0 || is.na(txt) || nchar(txt) == 0) "Tweet text not available" else txt
  })

  output$tweet_date_display <- renderText(
    paste0("Posted: ", tweet_effects$date[current_index()])
  )

  output$next_day_return <- renderText(pct(tweet_effects$next_day_return[current_index()]))
  output$return_7d       <- renderText(pct(tweet_effects$return_7d[current_index()]))
  output$return_30d      <- renderText(pct(tweet_effects$return_30d[current_index()]))

  output$trend_plot <- renderPlot({
    start_index <- match(tweet_effects$date[current_index()], btc_data$date)
    if (is.na(start_index)) return(NULL)

    end_index <- min(nrow(btc_data), start_index + 29)
    plot_data <- btc_data[start_index:end_index, ]

    ggplot(plot_data, aes(x = date, y = close)) +
      geom_line(color = "#2C3E50") +
      geom_point(color = "#E74C3C", size = 1.5) +
      labs(title = "BTC Closing Price - 30 Days After Tweet",
           x = "Date", y = "Close Price (USD)") +
      theme_minimal()
  })
}

shinyApp(ui = ui, server = server)
