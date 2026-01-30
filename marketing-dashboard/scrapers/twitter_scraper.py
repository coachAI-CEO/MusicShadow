"""
Twitter/X Scraper for Music Shadow Marketing Dashboard
Tracks tweets, hashtags, and trending topics
"""
import os
import tweepy
from datetime import datetime, timedelta
from typing import List, Dict
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


class TwitterScraper:
    def __init__(self):
        """Initialize Twitter API client"""
        self.client = tweepy.Client(
            bearer_token=os.getenv('TWITTER_BEARER_TOKEN'),
            consumer_key=os.getenv('TWITTER_API_KEY'),
            consumer_secret=os.getenv('TWITTER_API_SECRET'),
            access_token=os.getenv('TWITTER_ACCESS_TOKEN'),
            access_token_secret=os.getenv('TWITTER_ACCESS_SECRET'),
            wait_on_rate_limit=True
        )
        
        # Keywords and hashtags to track
        self.keywords = [
            'shadow work', 'music therapy', 'IFS therapy', 'emotional activation',
            'nervous system activation', 'music journal', 'pattern recognition',
            'emotional intelligence', 'inner child work'
        ]
        
        self.hashtags = [
            '#ShadowWork', '#MusicTherapy', '#IFSTherapy', '#EmotionalIntelligence',
            '#MentalHealth', '#SelfAwareness', '#MusicHealing', '#TherapyTools',
            '#ShadowJournal', '#MusicActivation'
        ]
    
    def search_tweets(self, query: str, max_results: int = 100, days_back: int = 7) -> List[Dict]:
        """
        Search for tweets matching query
        
        Args:
            query: Search query (can include keywords, hashtags, operators)
            max_results: Maximum number of results (max 100 per request)
            days_back: How many days back to search
        
        Returns:
            List of tweet dictionaries
        """
        tweets = []
        start_time = datetime.utcnow() - timedelta(days=days_back)
        
        try:
            # Search recent tweets
            response = self.client.search_recent_tweets(
                query=query,
                max_results=min(max_results, 100),
                start_time=start_time,
                tweet_fields=['created_at', 'public_metrics', 'author_id', 'lang'],
                expansions=['author_id']
            )
            
            if not response.data:
                return []
            
            # Get user information
            users = {user.id: user for user in response.includes.get('users', [])}
            
            for tweet in response.data:
                author = users.get(tweet.author_id)
                post = {
                    'platform': 'twitter',
                    'post_id': str(tweet.id),
                    'author': author.username if author else 'unknown',
                    'author_id': str(tweet.author_id) if tweet.author_id else None,
                    'content': tweet.text,
                    'url': f"https://twitter.com/i/web/status/{tweet.id}",
                    'score': tweet.public_metrics.get('like_count', 0),
                    'comment_count': tweet.public_metrics.get('reply_count', 0),
                    'retweet_count': tweet.public_metrics.get('retweet_count', 0),
                    'created_at': tweet.created_at,
                    'scraped_at': datetime.utcnow(),
                    'lang': tweet.lang,
                    'hashtags': self._extract_hashtags(tweet.text),
                    'keywords': self._extract_keywords(tweet.text)
                }
                tweets.append(post)
            
            logger.info(f"Found {len(tweets)} tweets for query: {query}")
            
        except tweepy.TooManyRequests:
            logger.warning("Rate limit exceeded. Waiting...")
        except Exception as e:
            logger.error(f"Error searching Twitter: {str(e)}")
        
        return tweets
    
    def search_hashtag(self, hashtag: str, max_results: int = 100) -> List[Dict]:
        """Search for tweets with specific hashtag"""
        return self.search_tweets(f"#{hashtag}", max_results=max_results)
    
    def search_keywords(self, keywords: List[str], max_results: int = 100) -> List[Dict]:
        """Search for tweets containing any of the keywords"""
        all_tweets = []
        seen_ids = set()
        
        for keyword in keywords:
            tweets = self.search_tweets(keyword, max_results=max_results)
            for tweet in tweets:
                if tweet['post_id'] not in seen_ids:
                    all_tweets.append(tweet)
                    seen_ids.add(tweet['post_id'])
        
        return all_tweets
    
    def get_trending_topics(self, woeid: int = 1) -> List[Dict]:
        """
        Get trending topics (requires different API endpoint)
        woeid: Where On Earth ID (1 = worldwide)
        """
        # Note: This requires Twitter API v1.1 which may need different auth
        # For now, return empty list
        logger.warning("Trending topics requires API v1.1 - not implemented")
        return []
    
    def _extract_hashtags(self, text: str) -> List[str]:
        """Extract hashtags from tweet text"""
        import re
        hashtags = re.findall(r'#\w+', text)
        return [h.lower() for h in hashtags]
    
    def _extract_keywords(self, text: str) -> List[str]:
        """Extract matched keywords from tweet text"""
        text_lower = text.lower()
        matched = [kw for kw in self.keywords if kw.lower() in text_lower]
        return matched


if __name__ == '__main__':
    from dotenv import load_dotenv
    load_dotenv()
    
    scraper = TwitterScraper()
    
    # Test searching
    tweets = scraper.search_keywords(['shadow work', 'music therapy'], max_results=20)
    
    print(f"Found {len(tweets)} relevant tweets")
    for tweet in tweets[:5]:
        print(f"\n@{tweet['author']}: {tweet['content'][:100]}...")
        print(f"Likes: {tweet['score']} | Retweets: {tweet['retweet_count']}")
