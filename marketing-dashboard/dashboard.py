"""
Streamlit Dashboard for Music Shadow Marketing Intelligence
Run with: streamlit run dashboard.py
"""
import streamlit as st
import pandas as pd
import plotly.express as px
import plotly.graph_objects as go
from datetime import datetime, timedelta
import os
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Page config
st.set_page_config(
    page_title="Music Shadow Marketing Dashboard",
    page_icon="🎵",
    layout="wide",
    initial_sidebar_state="expanded"
)

# Custom CSS
st.markdown("""
<style>
    .main-header {
        font-size: 2.5rem;
        font-weight: 700;
        color: #6366f1;
        margin-bottom: 0.5rem;
    }
    .metric-card {
        background-color: #1e1e2e;
        padding: 1rem;
        border-radius: 0.5rem;
        border: 1px solid #3a3a5c;
    }
</style>
""", unsafe_allow_html=True)


# Mock data functions (replace with actual database queries)
@st.cache_data(ttl=3600)
def get_mock_posts():
    """Mock data - replace with actual database query"""
    return pd.DataFrame({
        'platform': ['reddit', 'reddit', 'twitter', 'twitter', 'reddit'],
        'title': [
            'How music helps with shadow work',
            'IFS therapy and music activation',
            'Just discovered shadow work through music',
            'Music therapy changed my life',
            'Pattern recognition in emotional responses'
        ],
        'score': [234, 156, 45, 89, 67],
        'comment_count': [23, 12, 8, 15, 9],
        'created_at': pd.date_range('2024-01-01', periods=5, freq='D'),
        'sentiment': ['positive', 'positive', 'positive', 'positive', 'neutral']
    })


@st.cache_data(ttl=3600)
def get_mock_trends():
    """Mock trends data"""
    dates = pd.date_range(datetime.now() - timedelta(days=7), datetime.now(), freq='D')
    return pd.DataFrame({
        'date': dates,
        'keyword': ['shadow work'] * len(dates),
        'mention_count': [10, 15, 12, 18, 22, 25, 20],
        'sentiment_avg': [0.6, 0.65, 0.7, 0.68, 0.72, 0.75, 0.73]
    })


def main():
    # Header
    st.markdown('<h1 class="main-header">🎵 Music Shadow Marketing Dashboard</h1>', unsafe_allow_html=True)
    st.markdown("Track trends, conversations, and opportunities in the shadow work niche")
    
    # Sidebar
    with st.sidebar:
        st.header("⚙️ Settings")
        days_back = st.slider("Days to analyze", 1, 30, 7)
        platform_filter = st.multiselect(
            "Platforms",
            ['reddit', 'twitter', 'facebook'],
            default=['reddit', 'twitter']
        )
        min_score = st.slider("Minimum engagement score", 0, 1000, 10)
        
        st.divider()
        st.header("🔄 Actions")
        if st.button("Refresh Data"):
            st.cache_data.clear()
            st.rerun()
    
    # Key Metrics
    st.subheader("📊 Key Metrics (Last 7 Days)")
    col1, col2, col3, col4 = st.columns(4)
    
    with col1:
        st.metric(
            "Total Mentions",
            "1,234",
            "+12%",
            delta_color="normal"
        )
    
    with col2:
        st.metric(
            "Avg Sentiment",
            "+0.65",
            "+0.08",
            delta_color="normal"
        )
    
    with col3:
        st.metric(
            "Engagement Rate",
            "8.2%",
            "+1.5%",
            delta_color="normal"
        )
    
    with col4:
        st.metric(
            "Content Ideas",
            "23",
            "5 new",
            delta_color="normal"
        )
    
    st.divider()
    
    # Trends Chart
    st.subheader("📈 Trending Topics")
    
    col1, col2 = st.columns([2, 1])
    
    with col1:
        trends_df = get_mock_trends()
        fig = px.line(
            trends_df,
            x='date',
            y='mention_count',
            color='keyword',
            title='Keyword Mentions Over Time',
            labels={'mention_count': 'Mentions', 'date': 'Date'}
        )
        fig.update_layout(height=400)
        st.plotly_chart(fig, use_container_width=True)
    
    with col2:
        st.markdown("### Top Keywords")
        keywords = [
            ("Shadow Work", "+45%", "🔺"),
            ("Music Therapy", "+32%", "🔺"),
            ("IFS Therapy", "+28%", "🔺"),
            ("Emotional Activation", "+15%", "🔺"),
        ]
        for keyword, change, icon in keywords:
            st.markdown(f"{icon} **{keyword}**  \n{change} this week")
    
    st.divider()
    
    # Top Posts
    st.subheader("🔥 Top Performing Content")
    
    posts_df = get_mock_posts()
    posts_df = posts_df[posts_df['score'] >= min_score].sort_values('score', ascending=False)
    
    for idx, row in posts_df.head(10).iterrows():
        with st.container():
            col1, col2, col3 = st.columns([3, 1, 1])
            
            with col1:
                platform_emoji = "🔴" if row['platform'] == 'reddit' else "🐦"
                st.markdown(f"{platform_emoji} **[{row['platform'].upper()}]** {row['title']}")
            
            with col2:
                st.metric("Score", f"{int(row['score'])}")
            
            with col3:
                st.metric("Comments", f"{int(row['comment_count'])}")
            
            st.caption(f"Sentiment: {row['sentiment']} | Created: {row['created_at'].strftime('%Y-%m-%d')}")
            st.divider()
    
    # Content Ideas
    st.subheader("💡 Auto-Generated Content Ideas")
    
    content_ideas = [
        {
            'idea': "5 Songs That Activate Your Shadow",
            'priority': 'High',
            'category': 'Educational',
            'source': 'Trending Reddit post'
        },
        {
            'idea': "Shadow Work for Beginners Guide",
            'priority': 'High',
            'category': 'Educational',
            'source': 'Frequent question'
        },
        {
            'idea': "Music Therapy vs. Shadow Work",
            'priority': 'Medium',
            'category': 'Comparison',
            'source': 'Twitter discussion'
        },
        {
            'idea': "How to Start a Music Shadow Journal",
            'priority': 'High',
            'category': 'Tutorial',
            'source': 'User request'
        }
    ]
    
    for idea in content_ideas:
        priority_color = "🔴" if idea['priority'] == 'High' else "🟡"
        st.markdown(f"{priority_color} **{idea['idea']}**")
        st.caption(f"Category: {idea['category']} | Source: {idea['source']}")
        st.divider()
    
    # Sentiment Distribution
    st.subheader("😊 Sentiment Analysis")
    
    col1, col2 = st.columns(2)
    
    with col1:
        sentiment_counts = posts_df['sentiment'].value_counts()
        fig = px.pie(
            values=sentiment_counts.values,
            names=sentiment_counts.index,
            title='Sentiment Distribution'
        )
        st.plotly_chart(fig, use_container_width=True)
    
    with col2:
        st.markdown("### Sentiment Trends")
        st.markdown("""
        - **Positive**: 65% (+5% from last week)
        - **Neutral**: 25% (-3%)
        - **Negative**: 10% (-2%)
        
        Overall sentiment is improving! 🎉
        """)


if __name__ == '__main__':
    main()
