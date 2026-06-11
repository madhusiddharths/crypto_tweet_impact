# Data

This directory holds the datasets used by the analysis. It is split into
**`processed/`** (analysis-ready, version-controlled) and **`raw/`** (large
source scrapes, *git-ignored*).

```
data/
├── processed/   # cleaned, analysis-ready (committed)
└── raw/         # large source scrapes (git-ignored — see "Raw data" below)
```

---

## Processed data (committed)

### `processed/sentiment_classified.csv`  (~20,370 rows)
Tweet-level sentiment and category labels. Built from the raw Musk tweet scrape
through the pipeline described in [Provenance](#provenance).

| Column | Type | Description |
|---|---|---|
| `tweet_id` | string | Unique tweet identifier |
| `createdAt` | datetime | Tweet timestamp |
| `primary_group` | string | Primary topic group assigned to the tweet |
| `is_joke_or_meme` | bool | LLM flag: tweet is a joke/meme rather than a substantive statement |
| `overall_group_sentiment` | numeric | Aggregate sentiment for the tweet's group |
| `keyword` | string | Matched crypto keyword (e.g. `bitcoin`, `doge`) |
| `keyword_group` | string | Keyword grouping (incl. meme sub-classes) |
| `sentiment` | numeric (0–10) | Sentiment score for the tweet (LLM-scored) |
| `context_only_from_username` | bool | Whether relevance derives only from the username context |
| `context_is_relevant` | bool | LLM flag: tweet is contextually relevant to crypto |
| `category` | string | Final category (e.g. `Bitcoin`, `Doge Coin`, `Alt coins`) |
| `keyword_in_username` | bool | Whether the keyword appeared in a username |

> **Sentiment interpretation:** for the manually-verified `Bitcoin` and
> `Doge Coin` categories, `sentiment` reflects sentiment about that coin. For
> other categories it reflects sentiment about that topic, not Dogecoin.

### `processed/doge_daily_10years.csv`  (~2,918 rows)
Daily DOGE/USD OHLCV, sourced from Yahoo Finance via `quantmod`.

| Column | Type | Description |
|---|---|---|
| `Date` | date | Trading date |
| `Open`, `High`, `Low`, `Close` | numeric | Daily OHLC prices (USD) |
| `Volume` | numeric | Daily trading volume |

### `processed/BTC_USD_data_2013_to_present.csv`  (~4,098 rows)
Daily BTC/USD prices, sourced from Yahoo Finance via `quantmod`.

| Column | Type | Description |
|---|---|---|
| `date` | date | Trading date |
| `open`, `close` | numeric | Daily open/close prices (USD) |
| `volume_usd` | numeric | Daily trading volume (USD) |

> Both price files are **regenerated automatically** by the first chunks of
> `analysis/data_analysis.qmd` if they are missing, using live Yahoo Finance
> data (requires network access).

---

## Raw data (git-ignored)

These files are large source scrapes of Elon Musk's public posts. They are kept
locally so the pipeline runs end-to-end, but excluded from version control via
`.gitignore`. The dashboard and analysis fall back gracefully when raw files are
absent.

| File | Approx. size | Description |
|---|---|---|
| `raw/all_musk_posts.csv` | ~36 MB | Full scrape of Musk posts (`id`, `fullText`, `createdAt`, engagement metrics) |
| `raw/musk_quote_tweets.csv` | ~17 MB | Musk quote-tweets joined to the original tweet they quote |
| `raw/tweet_text_metadata.csv` | ~22 MB | Per-tweet text + engagement metadata; used to display tweet text in the dashboard |

### How to obtain
The raw scrapes were collected from public Twitter/X archives of Elon Musk's
account. To reproduce or refresh them, re-run your collection step and drop the
CSVs into `data/raw/` with the filenames above. The processed datasets in
`processed/` are sufficient to fully reproduce the statistical analysis; the raw
files are only required for the dashboard's tweet-text display and for
re-deriving `sentiment_classified.csv` from scratch.

---

## Provenance

`sentiment_classified.csv` was produced by a multi-step pipeline:

1. **Collection** — raw Musk posts scraped from public Twitter/X archives.
2. **Keyword filtering** — tweets matched against a crypto keyword list
   (`bitcoin`, `btc`, `ethereum`, `doge`, `crypto`, …).
3. **LLM sentiment scoring** — each tweet scored for sentiment via the OpenAI API.
4. **LLM classification** — tweets labelled as contextually relevant vs.
   joke/meme, and assigned to topic categories.
5. **Manual verification** — `Bitcoin` and `Doge Coin` categories were
   hand-checked for accuracy.

Price data (`doge_daily_10years.csv`, `BTC_USD_data_2013_to_present.csv`) comes
from Yahoo Finance via the `quantmod` R package.
