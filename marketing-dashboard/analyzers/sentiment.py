"""
Sentiment Analysis for Social Media Posts
Uses VADER (better for social media) and TextBlob
"""
from vaderSentiment.vaderSentiment import SentimentIntensityAnalyzer
from textblob import TextBlob
from typing import Dict
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


class SentimentAnalyzer:
    def __init__(self):
        """Initialize sentiment analyzers"""
        self.vader = SentimentIntensityAnalyzer()
    
    def analyze(self, text: str) -> Dict:
        """
        Analyze sentiment of text
        
        Args:
            text: Text to analyze
        
        Returns:
            Dictionary with sentiment scores and label
        """
        if not text or len(text.strip()) == 0:
            return {
                'compound': 0.0,
                'positive': 0.0,
                'negative': 0.0,
                'neutral': 1.0,
                'label': 'neutral'
            }
        
        # VADER analysis (better for social media)
        vader_scores = self.vader.polarity_scores(text)
        
        # TextBlob analysis (for comparison)
        blob = TextBlob(text)
        textblob_polarity = blob.sentiment.polarity
        
        # Determine label
        compound = vader_scores['compound']
        if compound >= 0.05:
            label = 'positive'
        elif compound <= -0.05:
            label = 'negative'
        else:
            label = 'neutral'
        
        return {
            'compound': compound,
            'positive': vader_scores['pos'],
            'negative': vader_scores['neg'],
            'neutral': vader_scores['neu'],
            'label': label,
            'textblob_polarity': textblob_polarity,
            'confidence': abs(compound)  # Higher absolute value = more confident
        }
    
    def analyze_batch(self, texts: list) -> list:
        """Analyze multiple texts"""
        return [self.analyze(text) for text in texts]
    
    def get_sentiment_summary(self, posts: list) -> Dict:
        """
        Get sentiment summary for a list of posts
        
        Args:
            posts: List of post dictionaries with 'content' or 'title' fields
        
        Returns:
            Summary statistics
        """
        sentiments = []
        for post in posts:
            text = post.get('content', '') or post.get('title', '')
            sentiment = self.analyze(text)
            sentiments.append(sentiment)
        
        if not sentiments:
            return {
            'total': 0,
            'positive': 0,
            'negative': 0,
            'neutral': 0,
            'avg_compound': 0.0
        }
        
        labels = [s['label'] for s in sentiments]
        compounds = [s['compound'] for s in sentiments]
        
        return {
            'total': len(sentiments),
            'positive': labels.count('positive'),
            'negative': labels.count('negative'),
            'neutral': labels.count('neutral'),
            'avg_compound': sum(compounds) / len(compounds),
            'positive_pct': labels.count('positive') / len(labels) * 100,
            'negative_pct': labels.count('negative') / len(labels) * 100,
            'neutral_pct': labels.count('neutral') / len(labels) * 100
        }


if __name__ == '__main__':
    analyzer = SentimentAnalyzer()
    
    # Test
    test_texts = [
        "I love shadow work! It's been so helpful for my healing journey.",
        "Music therapy is amazing and really helps with trauma.",
        "I'm struggling with emotional activation today.",
        "This app looks interesting, might try it.",
        "Shadow work is too difficult, I don't think it works."
    ]
    
    for text in test_texts:
        result = analyzer.analyze(text)
        print(f"\nText: {text[:50]}...")
        print(f"Sentiment: {result['label']} (compound: {result['compound']:.2f})")
