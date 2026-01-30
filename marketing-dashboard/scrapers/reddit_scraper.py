"""
Reddit Scraper for Music Shadow Marketing Dashboard
Tracks posts in relevant subreddits and extracts trends
"""
import os
import praw
from datetime import datetime
from typing import List, Dict
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


class RedditScraper:
    def __init__(self):
        """Initialize Reddit API client"""
        self.reddit = praw.Reddit(
            client_id=os.getenv('REDDIT_CLIENT_ID'),
            client_secret=os.getenv('REDDIT_CLIENT_SECRET'),
            user_agent=os.getenv('REDDIT_USER_AGENT', 'MusicShadowMarketing/1.0')
        )
        
        # Keywords to track
        self.keywords = [
            'shadow work', 'music therapy', 'IFS therapy', 'emotional activation',
            'trigger', 'nervous system', 'inner child', 'music journal',
            'pattern recognition', 'emotional intelligence', 'shadow journal',
            'music activation', 'somatic', 'body activation'
        ]
    
    def scrape_subreddit(self, subreddit_name: str, limit: int = 100, sort: str = 'hot') -> List[Dict]:
        """
        Scrape posts from a subreddit
        
        Args:
            subreddit_name: Name of subreddit (without 'r/')
            limit: Number of posts to fetch
            sort: Sort method ('hot', 'new', 'top', 'rising')
        
        Returns:
            List of post dictionaries
        """
        try:
            subreddit = self.reddit.subreddit(subreddit_name)
            posts = []
            
            # Get posts based on sort method
            if sort == 'hot':
                submissions = subreddit.hot(limit=limit)
            elif sort == 'new':
                submissions = subreddit.new(limit=limit)
            elif sort == 'top':
                submissions = subreddit.top(limit=limit, time_filter='week')
            elif sort == 'rising':
                submissions = subreddit.rising(limit=limit)
            else:
                submissions = subreddit.hot(limit=limit)
            
            for submission in submissions:
                # Check if post contains relevant keywords
                text = f"{submission.title} {submission.selftext}".lower()
                matched_keywords = [kw for kw in self.keywords if kw.lower() in text]
                
                if matched_keywords or submission.score > 10:  # Include high-scoring posts
                    post = {
                        'platform': 'reddit',
                        'post_id': submission.id,
                        'author': str(submission.author) if submission.author else 'deleted',
                        'title': submission.title,
                        'content': submission.selftext[:1000],  # Limit content length
                        'url': f"https://reddit.com{submission.permalink}",
                        'score': submission.score,
                        'comment_count': submission.num_comments,
                        'created_at': datetime.fromtimestamp(submission.created_utc),
                        'scraped_at': datetime.now(),
                        'subreddit': subreddit_name,
                        'keywords': matched_keywords,
                        'upvote_ratio': submission.upvote_ratio
                    }
                    posts.append(post)
            
            logger.info(f"Scraped {len(posts)} posts from r/{subreddit_name}")
            return posts
            
        except Exception as e:
            logger.error(f"Error scraping r/{subreddit_name}: {str(e)}")
            return []
    
    def scrape_multiple_subreddits(self, subreddit_names: List[str], limit: int = 50) -> List[Dict]:
        """Scrape multiple subreddits"""
        all_posts = []
        for subreddit in subreddit_names:
            posts = self.scrape_subreddit(subreddit, limit=limit)
            all_posts.extend(posts)
        return all_posts
    
    def search_keywords(self, query: str, limit: int = 100) -> List[Dict]:
        """Search Reddit for specific keywords"""
        posts = []
        try:
            for submission in self.reddit.subreddit('all').search(query, limit=limit, sort='relevance'):
                post = {
                    'platform': 'reddit',
                    'post_id': submission.id,
                    'author': str(submission.author) if submission.author else 'deleted',
                    'title': submission.title,
                    'content': submission.selftext[:1000],
                    'url': f"https://reddit.com{submission.permalink}",
                    'score': submission.score,
                    'comment_count': submission.num_comments,
                    'created_at': datetime.fromtimestamp(submission.created_utc),
                    'scraped_at': datetime.now(),
                    'subreddit': submission.subreddit.display_name,
                    'keywords': [query],
                    'upvote_ratio': submission.upvote_ratio
                }
                posts.append(post)
        except Exception as e:
            logger.error(f"Error searching Reddit: {str(e)}")
        
        return posts


if __name__ == '__main__':
    from dotenv import load_dotenv
    load_dotenv()
    
    scraper = RedditScraper()
    
    # Test scraping
    subreddits = ['shadowwork', 'InternalFamilySystems', 'therapy', 'Music']
    posts = scraper.scrape_multiple_subreddits(subreddits, limit=20)
    
    print(f"Found {len(posts)} relevant posts")
    for post in posts[:5]:
        print(f"\n[{post['subreddit']}] {post['title']}")
        print(f"Score: {post['score']} | Comments: {post['comment_count']}")
        print(f"Keywords: {post['keywords']}")
