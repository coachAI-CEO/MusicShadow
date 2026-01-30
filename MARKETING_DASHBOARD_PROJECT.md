# Music Shadow - Marketing Dashboard Project

## 🎯 **Project Overview**

Build an automated marketing intelligence dashboard that tracks trends, conversations, and opportunities in the shadow work, mental health, and music therapy niche across Reddit, X (Twitter), and Facebook.

**Goal:** Automate trend monitoring, content discovery, and engagement opportunities to inform marketing strategy.

---

## 📊 **Dashboard Features**

### 1. **Trend Tracking Dashboard**
- Real-time trending topics/keywords
- Sentiment analysis
- Engagement metrics
- Time-series visualizations
- Alert system for spikes

### 2. **Social Media Monitoring**
- **Reddit**: Track subreddits, keywords, post performance
- **X (Twitter)**: Track hashtags, mentions, trending topics
- **Facebook**: Track groups, pages, public posts (within API limits)

### 3. **Content Discovery**
- Top performing content in niche
- Content gaps and opportunities
- Influencer identification
- Conversation starters

### 4. **Competitive Intelligence**
- Competitor mentions
- Feature comparisons
- Market positioning
- User sentiment

### 5. **Automation Workflows**
- Auto-generate content ideas
- Schedule social posts
- Engage with relevant conversations
- Track campaign performance

---

## 🛠️ **Technology Stack**

### Backend Options

#### Option 1: Python (Recommended)
```python
# Core Libraries
- FastAPI / Flask (API)
- Pandas (Data processing)
- SQLAlchemy (Database)
- Celery (Task queue)
- Redis (Caching)

# Social Media APIs
- PRAW (Reddit API)
- Tweepy (Twitter/X API)
- Facebook Graph API

# Data Analysis
- NLTK / spaCy (NLP)
- TextBlob / VADER (Sentiment)
- WordCloud (Visualization)

# Dashboard
- Streamlit (Quick prototype)
- Dash / Plotly (Advanced)
- React + D3.js (Custom)
```

#### Option 2: Node.js
```javascript
// Core
- Express.js (API)
- Prisma (Database)
- Bull (Task queue)
- Redis

// Social Media
- snoowrap (Reddit)
- twitter-api-v2 (Twitter)
- facebook-node-sdk (Facebook)

// Dashboard
- Next.js + React
- Recharts / Chart.js
- Tailwind CSS
```

### Database
- **PostgreSQL** (Primary data store)
- **Redis** (Caching, real-time data)
- **TimescaleDB** (Time-series data for trends)

### Infrastructure
- **Docker** (Containerization)
- **AWS / GCP / Railway** (Hosting)
- **GitHub Actions** (CI/CD)
- **Cron jobs** (Scheduled tasks)

---

## 📡 **Data Sources & APIs**

### Reddit API (PRAW)
```python
import praw

reddit = praw.Reddit(
    client_id="YOUR_CLIENT_ID",
    client_secret="YOUR_CLIENT_SECRET",
    user_agent="MusicShadowMarketing/1.0"
)

# Track subreddits
subreddits = [
    'r/shadowwork',
    'r/InternalFamilySystems',
    'r/therapy',
    'r/Music',
    'r/mentalhealth',
    'r/CPTSD',
    'r/emotionalintelligence',
    'r/musictherapy',
    'r/journaling',
    'r/selfimprovement'
]

# Keywords to track
keywords = [
    'shadow work',
    'music therapy',
    'emotional activation',
    'trigger',
    'nervous system',
    'inner child',
    'IFS',
    'music journal',
    'pattern recognition',
    'emotional intelligence'
]
```

### X (Twitter) API v2
```python
import tweepy

client = tweepy.Client(
    bearer_token="YOUR_BEARER_TOKEN",
    consumer_key="YOUR_KEY",
    consumer_secret="YOUR_SECRET",
    access_token="YOUR_ACCESS_TOKEN",
    access_token_secret="YOUR_ACCESS_SECRET"
)

# Track hashtags
hashtags = [
    '#ShadowWork',
    '#MusicTherapy',
    '#IFSTherapy',
    '#EmotionalIntelligence',
    '#MentalHealth',
    '#SelfAwareness',
    '#MusicHealing',
    '#TherapyTools'
]

# Track keywords
keywords = [
    'shadow work',
    'music activation',
    'emotional pattern',
    'nervous system activation',
    'music journal'
]
```

### Facebook Graph API
```python
# Limited - mostly public pages/groups
# Requires app review for advanced features

# Track public pages
pages = [
    'ShadowWork',
    'MusicTherapy',
    'InternalFamilySystems',
    'MentalHealth'
]

# Groups (requires permission)
# Most groups are private - focus on public groups
```

---

## 🗄️ **Database Schema**

```sql
-- Posts/Content
CREATE TABLE social_posts (
    id SERIAL PRIMARY KEY,
    platform VARCHAR(20) NOT NULL, -- 'reddit', 'twitter', 'facebook'
    post_id VARCHAR(255) UNIQUE NOT NULL,
    author VARCHAR(255),
    title TEXT,
    content TEXT,
    url TEXT,
    score INTEGER, -- upvotes/likes
    comment_count INTEGER,
    created_at TIMESTAMP,
    scraped_at TIMESTAMP DEFAULT NOW(),
    sentiment_score FLOAT,
    sentiment_label VARCHAR(20), -- 'positive', 'negative', 'neutral'
    keywords TEXT[], -- array of matched keywords
    subreddit VARCHAR(100), -- for Reddit
    hashtags TEXT[] -- for Twitter
);

-- Trends
CREATE TABLE trends (
    id SERIAL PRIMARY KEY,
    keyword VARCHAR(255) NOT NULL,
    platform VARCHAR(20) NOT NULL,
    mention_count INTEGER,
    engagement_score FLOAT,
    sentiment_avg FLOAT,
    date DATE NOT NULL,
    created_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(keyword, platform, date)
);

-- Influencers
CREATE TABLE influencers (
    id SERIAL PRIMARY KEY,
    platform VARCHAR(20) NOT NULL,
    username VARCHAR(255) NOT NULL,
    follower_count INTEGER,
    engagement_rate FLOAT,
    niche_tags TEXT[],
    last_post_date TIMESTAMP,
    contact_info TEXT,
    notes TEXT,
    UNIQUE(platform, username)
);

-- Content Ideas (Auto-generated)
CREATE TABLE content_ideas (
    id SERIAL PRIMARY KEY,
    idea_text TEXT NOT NULL,
    source_post_id INTEGER REFERENCES social_posts(id),
    category VARCHAR(50), -- 'educational', 'story', 'tip', 'question'
    priority INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT NOW(),
    used BOOLEAN DEFAULT FALSE
);

-- Campaigns
CREATE TABLE campaigns (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    start_date DATE,
    end_date DATE,
    metrics JSONB, -- flexible metrics storage
    created_at TIMESTAMP DEFAULT NOW()
);
```

---

## 🤖 **Automation Workflows**

### 1. **Daily Trend Collection**
```python
# Scheduled: Every 6 hours
def collect_trends():
    # Reddit
    reddit_trends = scrape_reddit_trends()
    
    # Twitter
    twitter_trends = scrape_twitter_trends()
    
    # Facebook (limited)
    facebook_trends = scrape_facebook_trends()
    
    # Store in database
    store_trends(reddit_trends + twitter_trends + facebook_trends)
    
    # Generate alerts for spikes
    check_for_spikes()
```

### 2. **Content Discovery**
```python
# Scheduled: Daily
def discover_content():
    # Find top performing posts
    top_posts = get_top_posts(days=7, min_score=50)
    
    # Analyze for content ideas
    for post in top_posts:
        idea = generate_content_idea(post)
        save_content_idea(idea)
    
    # Identify engagement opportunities
    opportunities = find_engagement_opportunities()
    send_notifications(opportunities)
```

### 3. **Sentiment Analysis**
```python
def analyze_sentiment(text):
    from textblob import TextBlob
    from vaderSentiment.vaderSentiment import SentimentIntensityAnalyzer
    
    # Use VADER (better for social media)
    analyzer = SentimentIntensityAnalyzer()
    scores = analyzer.polarity_scores(text)
    
    return {
        'compound': scores['compound'],
        'positive': scores['pos'],
        'negative': scores['neg'],
        'neutral': scores['neu'],
        'label': 'positive' if scores['compound'] > 0.1 
                else 'negative' if scores['compound'] < -0.1 
                else 'neutral'
    }
```

### 4. **Influencer Identification**
```python
def identify_influencers():
    # Find users with high engagement
    high_engagement_users = find_users_by_engagement(
        min_followers=1000,
        min_engagement_rate=0.03
    )
    
    # Check if they post about relevant topics
    for user in high_engagement_users:
        if is_relevant(user):
            save_influencer(user)
            send_notification(f"New influencer: {user.username}")
```

### 5. **Auto-Generate Content Ideas**
```python
def generate_content_ideas():
    # Analyze trending posts
    trending = get_trending_posts()
    
    # Generate ideas based on patterns
    ideas = []
    for post in trending:
        # Educational content
        if post.category == 'question':
            idea = f"Create educational post about: {extract_topic(post)}"
            ideas.append(idea)
        
        # Story content
        if post.sentiment == 'positive':
            idea = f"Share success story about: {extract_theme(post)}"
            ideas.append(idea)
    
    save_content_ideas(ideas)
```

---

## 📈 **Dashboard Views**

### 1. **Overview Dashboard**
```
┌─────────────────────────────────────────────────┐
│  Music Shadow Marketing Dashboard               │
├─────────────────────────────────────────────────┤
│                                                 │
│  📊 Key Metrics (Last 7 Days)                   │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐      │
│  │ Mentions │ │ Sentiment│ │ Engagement│      │
│  │   1,234  │ │   +0.65  │ │   8.2%   │      │
│  └──────────┘ └──────────┘ └──────────┘      │
│                                                 │
│  📈 Trending Topics                             │
│  ┌──────────────────────────────────────────┐ │
│  │ 1. Shadow Work (+45% this week)          │ │
│  │ 2. Music Therapy (+32%)                  │ │
│  │ 3. IFS Therapy (+28%)                    │ │
│  │ 4. Emotional Activation (+15%)            │ │
│  └──────────────────────────────────────────┘ │
│                                                 │
│  🔥 Top Performing Content                      │
│  ┌──────────────────────────────────────────┐ │
│  │ [Reddit] "How music helps with trauma"    │ │
│  │    2.3k upvotes | 156 comments            │ │
│  │ [Twitter] Thread about shadow work        │ │
│  │    450 retweets | 1.2k likes              │ │
│  └──────────────────────────────────────────┘ │
│                                                 │
│  💡 Content Ideas (Auto-generated)              │
│  ┌──────────────────────────────────────────┐ │
│  │ • "5 Songs That Activate Your Shadow"    │ │
│  │ • "Shadow Work for Beginners Guide"       │ │
│  │ • "Music Therapy vs. Shadow Work"          │ │
│  └──────────────────────────────────────────┘ │
└─────────────────────────────────────────────────┘
```

### 2. **Trend Analysis View**
- Time-series charts of keyword mentions
- Sentiment trends over time
- Platform comparison
- Geographic distribution (if available)

### 3. **Content Discovery View**
- Top posts by platform
- Content gaps analysis
- Engagement opportunities
- Best times to post

### 4. **Influencer Dashboard**
- List of identified influencers
- Engagement metrics
- Contact information
- Collaboration opportunities

---

## 🚀 **Implementation Plan**

### Phase 1: Setup (Week 1)
1. **Environment Setup**
   - Set up Python/Node.js environment
   - Install dependencies
   - Set up database (PostgreSQL)
   - Configure Redis

2. **API Setup**
   - Create Reddit app (get API keys)
   - Create Twitter/X developer account
   - Set up Facebook app (if needed)
   - Store credentials securely (environment variables)

3. **Basic Scraping**
   - Reddit scraper (PRAW)
   - Twitter scraper (Tweepy)
   - Facebook scraper (limited)
   - Store data in database

### Phase 2: Core Features (Week 2-3)
1. **Data Collection**
   - Implement scheduled scraping
   - Set up Celery tasks
   - Error handling and retries
   - Rate limiting

2. **Analysis**
   - Sentiment analysis
   - Keyword extraction
   - Trend detection
   - Engagement scoring

3. **Database**
   - Create all tables
   - Set up indexes
   - Data validation

### Phase 3: Dashboard (Week 4)
1. **Dashboard UI**
   - Choose framework (Streamlit/Dash/React)
   - Create overview page
   - Add charts and visualizations
   - Real-time updates

2. **Visualizations**
   - Trend charts (Plotly/Chart.js)
   - Sentiment distribution
   - Top content lists
   - Engagement metrics

### Phase 4: Automation (Week 5)
1. **Content Ideas**
   - Auto-generate ideas
   - Priority scoring
   - Category classification

2. **Alerts**
   - Trend spike alerts
   - Engagement opportunities
   - Influencer notifications

3. **Scheduling**
   - Set up cron jobs
   - Task scheduling
   - Monitoring

### Phase 5: Polish (Week 6)
1. **Testing**
   - Test all workflows
   - Error handling
   - Performance optimization

2. **Documentation**
   - API documentation
   - User guide
   - Deployment guide

---

## 📁 **Project Structure**

```
marketing-dashboard/
├── backend/
│   ├── app/
│   │   ├── __init__.py
│   │   ├── main.py              # FastAPI/Flask app
│   │   ├── models/              # Database models
│   │   │   ├── post.py
│   │   │   ├── trend.py
│   │   │   └── influencer.py
│   │   ├── scrapers/            # Social media scrapers
│   │   │   ├── reddit_scraper.py
│   │   │   ├── twitter_scraper.py
│   │   │   └── facebook_scraper.py
│   │   ├── analyzers/           # Analysis modules
│   │   │   ├── sentiment.py
│   │   │   ├── trends.py
│   │   │   └── content_ideas.py
│   │   ├── tasks/               # Celery tasks
│   │   │   ├── collect_trends.py
│   │   │   ├── analyze_content.py
│   │   │   └── identify_influencers.py
│   │   └── api/                 # API endpoints
│   │       ├── trends.py
│   │       ├── posts.py
│   │       └── dashboard.py
│   ├── requirements.txt
│   ├── Dockerfile
│   └── docker-compose.yml
│
├── frontend/                    # Optional: React dashboard
│   ├── src/
│   │   ├── components/
│   │   ├── pages/
│   │   └── services/
│   └── package.json
│
├── database/
│   ├── migrations/
│   └── schema.sql
│
├── scripts/
│   ├── setup.sh
│   ├── deploy.sh
│   └── seed_data.py
│
├── config/
│   ├── .env.example
│   └── settings.py
│
├── tests/
│   ├── test_scrapers.py
│   ├── test_analyzers.py
│   └── test_api.py
│
├── docs/
│   ├── API.md
│   ├── SETUP.md
│   └── DEPLOYMENT.md
│
└── README.md
```

---

## 🔧 **Quick Start Script**

### Python Setup
```python
# requirements.txt
fastapi==0.104.1
uvicorn==0.24.0
praw==7.7.1
tweepy==4.14.0
facebook-sdk==3.1.0
pandas==2.1.3
sqlalchemy==2.0.23
psycopg2-binary==2.9.9
redis==5.0.1
celery==5.3.4
textblob==0.17.1
vaderSentiment==3.3.2
nltk==3.8.1
streamlit==1.28.1
plotly==5.18.0
python-dotenv==1.0.0
```

### Basic Reddit Scraper
```python
# scrapers/reddit_scraper.py
import praw
from datetime import datetime
from app.models.post import SocialPost

class RedditScraper:
    def __init__(self):
        self.reddit = praw.Reddit(
            client_id=os.getenv('REDDIT_CLIENT_ID'),
            client_secret=os.getenv('REDDIT_CLIENT_SECRET'),
            user_agent='MusicShadowMarketing/1.0'
        )
    
    def scrape_subreddit(self, subreddit_name, limit=100):
        subreddit = self.reddit.subreddit(subreddit_name)
        posts = []
        
        for submission in subreddit.hot(limit=limit):
            post = SocialPost(
                platform='reddit',
                post_id=submission.id,
                author=str(submission.author),
                title=submission.title,
                content=submission.selftext,
                url=f"https://reddit.com{submission.permalink}",
                score=submission.score,
                comment_count=submission.num_comments,
                created_at=datetime.fromtimestamp(submission.created_utc),
                subreddit=subreddit_name
            )
            posts.append(post)
        
        return posts
```

### Basic Twitter Scraper
```python
# scrapers/twitter_scraper.py
import tweepy
from datetime import datetime
from app.models.post import SocialPost

class TwitterScraper:
    def __init__(self):
        self.client = tweepy.Client(
            bearer_token=os.getenv('TWITTER_BEARER_TOKEN'),
            consumer_key=os.getenv('TWITTER_API_KEY'),
            consumer_secret=os.getenv('TWITTER_API_SECRET'),
            access_token=os.getenv('TWITTER_ACCESS_TOKEN'),
            access_token_secret=os.getenv('TWITTER_ACCESS_SECRET')
        )
    
    def search_tweets(self, query, max_results=100):
        tweets = self.client.search_recent_tweets(
            query=query,
            max_results=max_results,
            tweet_fields=['created_at', 'public_metrics', 'author_id']
        )
        
        posts = []
        for tweet in tweets.data:
            post = SocialPost(
                platform='twitter',
                post_id=tweet.id,
                author_id=tweet.author_id,
                content=tweet.text,
                url=f"https://twitter.com/i/web/status/{tweet.id}",
                score=tweet.public_metrics['like_count'],
                comment_count=tweet.public_metrics['reply_count'],
                created_at=tweet.created_at
            )
            posts.append(post)
        
        return posts
```

---

## 📊 **Dashboard Example (Streamlit)**

```python
# dashboard.py
import streamlit as st
import pandas as pd
import plotly.express as px
from app.models.post import get_recent_posts, get_trends

st.set_page_config(page_title="Music Shadow Marketing Dashboard", layout="wide")

st.title("🎵 Music Shadow Marketing Dashboard")

# Key Metrics
col1, col2, col3, col4 = st.columns(4)

with col1:
    st.metric("Total Mentions", "1,234", "+12%")
with col2:
    st.metric("Avg Sentiment", "+0.65", "+0.08")
with col3:
    st.metric("Engagement Rate", "8.2%", "+1.5%")
with col4:
    st.metric("Content Ideas", "23", "5 new")

# Trends Chart
st.subheader("📈 Trending Topics (Last 7 Days)")
trends_df = get_trends(days=7)
fig = px.line(trends_df, x='date', y='mention_count', 
              color='keyword', title='Keyword Mentions Over Time')
st.plotly_chart(fig, use_container_width=True)

# Top Posts
st.subheader("🔥 Top Performing Content")
posts = get_recent_posts(limit=10, min_score=50)
for post in posts:
    st.write(f"**[{post.platform.upper()}]** {post.title}")
    st.write(f"Score: {post.score} | Comments: {post.comment_count}")
    st.write(f"[View Post]({post.url})")
    st.divider()

# Content Ideas
st.subheader("💡 Auto-Generated Content Ideas")
ideas = get_content_ideas(limit=10)
for idea in ideas:
    st.write(f"• {idea.text}")
    st.caption(f"Priority: {idea.priority} | Source: {idea.source}")
```

---

## 🔐 **Security & Best Practices**

1. **API Keys**: Store in environment variables, never commit
2. **Rate Limiting**: Respect API rate limits
3. **Data Privacy**: Don't store personal information
4. **Error Handling**: Robust error handling and logging
5. **Monitoring**: Set up alerts for failures
6. **Backup**: Regular database backups

---

## 📈 **Metrics to Track**

1. **Engagement Metrics**
   - Mentions per day
   - Engagement rate
   - Sentiment score
   - Top keywords

2. **Content Performance**
   - Top posts by platform
   - Content categories performing best
   - Best posting times

3. **Influencer Metrics**
   - Influencers identified
   - Engagement rates
   - Collaboration opportunities

4. **Trend Metrics**
   - Keyword growth rates
   - Emerging topics
   - Declining topics

---

## 🚀 **Deployment Options**

### Option 1: Railway / Render (Easiest)
- Simple deployment
- Free tier available
- Auto-deploy from GitHub

### Option 2: AWS / GCP
- More control
- Better for scaling
- More complex setup

### Option 3: Local + Cloud
- Run scrapers on cloud
- Dashboard locally
- Cost-effective

---

## 📝 **Next Steps**

1. **This Week:**
   - Set up development environment
   - Get API keys (Reddit, Twitter)
   - Create basic scraper for one platform
   - Set up database

2. **Next Week:**
   - Complete all scrapers
   - Add sentiment analysis
   - Create basic dashboard
   - Set up scheduled tasks

3. **Week 3:**
   - Add visualizations
   - Implement content idea generation
   - Add alerts
   - Deploy to production

---

**Status:** Ready to start implementation  
**Estimated Time:** 4-6 weeks for full implementation  
**Priority:** High - Will inform all marketing decisions
