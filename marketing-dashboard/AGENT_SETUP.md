# Agent Capabilities Setup Guide

## 🚀 Quick Start

### 1. Install Additional Dependencies

```bash
pip install -r requirements-agents.txt
```

### 2. Set Up API Keys

Add to `.env`:
```bash
# For Content Generation Agent (LLM)
OPENAI_API_KEY=your_openai_key
OPENAI_MODEL=gpt-4  # or gpt-3.5-turbo for cost savings

# For YouTube Scraper
YOUTUBE_API_KEY=your_youtube_api_key

# For Instagram Scraper
INSTAGRAM_APP_ID=your_app_id
INSTAGRAM_APP_SECRET=your_app_secret
INSTAGRAM_ACCESS_TOKEN=your_access_token
INSTAGRAM_USER_ID=your_user_id

# For TikTok (when Research API access is obtained)
TIKTOK_API_KEY=your_tiktok_key
```

### 3. Initialize Agents

```python
from agents.trend_agent import TrendAnalysisAgent
from agents.content_agent import ContentGenerationAgent
from agents.adaptive_agent import AdaptiveLearningAgent

# Initialize agents
trend_agent = TrendAnalysisAgent()
content_agent = ContentGenerationAgent(use_llm=True)  # Set to False for templates
adaptive_agent = AdaptiveLearningAgent()
```

## 🤖 Agent Workflows

### Automated Trend Analysis

```python
# Run daily trend analysis
trends = trend_agent.analyze_trend(keyword, historical_data, days_ahead=7)

# Identify opportunities
opportunities = trend_agent.identify_opportunities([trends])

# Detect anomalies
anomalies = trend_agent.detect_anomalies(data, keyword)
```

### Content Generation

```python
# Generate content from trends
content = content_agent.generate_content(
    trend_data=trend,
    content_type='educational',
    platform='instagram',
    context={'audience': 'shadow work practitioners'}
)

# Generate content calendar
calendar = content_agent.generate_content_calendar(trends, days=7)
```

### Adaptive Learning

```python
# Learn from performance
adaptive_agent.learn_from_performance(
    content_id='post_123',
    performance={
        'engagement_rate': 0.08,
        'platform': 'instagram',
        'content_type': 'educational',
        'posted_at': datetime.now()
    }
)

# Get optimal strategy
strategy = adaptive_agent.get_optimal_strategy('instagram')

# Predict performance
prediction = adaptive_agent.predict_performance(
    content_type='educational',
    platform='instagram',
    keyword='shadow work',
    posting_time=datetime.now()
)
```

## 📊 Integration with Dashboard

Add agent capabilities to dashboard:

```python
# In dashboard.py
from agents.trend_agent import TrendAnalysisAgent
from agents.content_agent import ContentGenerationAgent

# Add agent-powered sections
st.subheader("🤖 AI-Powered Insights")

# Trend predictions
trend_agent = TrendAnalysisAgent()
predictions = trend_agent.analyze_trend(keyword, data)

# Content suggestions
content_agent = ContentGenerationAgent()
suggestions = content_agent.generate_content_calendar(trends)
```

## 🔄 Automated Workflows

### Daily Automation (Cron Job)

```python
# scripts/daily_automation.py
from agents.trend_agent import TrendAnalysisAgent
from agents.content_agent import ContentGenerationAgent
from agents.adaptive_agent import AdaptiveLearningAgent

def daily_automation():
    # 1. Analyze trends
    trend_agent = TrendAnalysisAgent()
    trends = analyze_all_trends()
    
    # 2. Generate content ideas
    content_agent = ContentGenerationAgent()
    calendar = content_agent.generate_content_calendar(trends)
    
    # 3. Get optimal strategies
    adaptive_agent = AdaptiveLearningAgent()
    strategies = adaptive_agent.get_optimal_strategy('instagram')
    
    # 4. Save recommendations
    save_recommendations(calendar, strategies)
```

## 📈 Additional Social Media Platforms

### Priority Order:

1. **TikTok** - High engagement, music-focused
   - Requires Research API access
   - Placeholder scraper included

2. **Instagram** - Visual content, strong community
   - Uses Graph API
   - Scraper included

3. **YouTube** - Long-form content, tutorials
   - Uses Data API v3
   - Scraper included

4. **LinkedIn** - Professional network
   - API available but limited
   - Good for B2B opportunities

5. **Pinterest** - Visual discovery
   - API available
   - Good for infographics

## 🎯 Next Steps

1. **Get API Access:**
   - YouTube: https://console.cloud.google.com/
   - Instagram: https://developers.facebook.com/
   - TikTok: https://developers.tiktok.com/ (Research API)

2. **Set Up Automation:**
   - Configure cron jobs
   - Set up task queue (Celery)
   - Configure alerts

3. **Train Agents:**
   - Collect performance data
   - Let agents learn from results
   - Refine strategies

4. **Monitor & Optimize:**
   - Track agent performance
   - Adjust learning parameters
   - Expand to more platforms
