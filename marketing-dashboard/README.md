# Music Shadow Marketing Dashboard

Automated marketing intelligence dashboard for tracking trends and conversations in the shadow work, mental health, and music therapy niche.

## Quick Start

1. **Install dependencies:**
```bash
pip install -r requirements.txt
```

2. **Set up environment variables:**
```bash
cp .env.example .env
# Edit .env with your API keys
```

3. **Set up database:**
```bash
# Using PostgreSQL
createdb music_shadow_marketing
psql music_shadow_marketing < database/schema.sql
```

4. **Run scrapers:**
```bash
python scripts/run_scraper.py reddit
python scripts/run_scraper.py twitter
```

5. **Start dashboard:**
```bash
streamlit run dashboard.py
```

## API Keys Needed

- Reddit: https://www.reddit.com/prefs/apps
- Twitter/X: https://developer.twitter.com/
- Facebook: https://developers.facebook.com/ (optional)

## Project Structure

See `MARKETING_DASHBOARD_PROJECT.md` for full documentation.
