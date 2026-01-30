"""
Instagram Scraper for Music Shadow Marketing Dashboard
Uses Instagram Basic Display API and Graph API
"""
import os
import requests
from typing import List, Dict
from datetime import datetime
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


class InstagramScraper:
    def __init__(self):
        """Initialize Instagram API client"""
        self.access_token = os.getenv('INSTAGRAM_ACCESS_TOKEN')
        self.app_id = os.getenv('INSTAGRAM_APP_ID')
        self.app_secret = os.getenv('INSTAGRAM_APP_SECRET')
        
        self.base_url = "https://graph.instagram.com"
        
        # Keywords and hashtags to track
        self.hashtags = [
            'shadowwork', 'musictherapy', 'ifstherapy', 'emotionalintelligence',
            'mentalhealth', 'selfawareness', 'musichealing', 'therapy',
            'shadowjournal', 'musicactivation', 'nervoussystem', 'innerchild'
        ]
    
    def search_hashtag(self, hashtag: str, limit: int = 25) -> List[Dict]:
        """
        Search Instagram posts by hashtag
        
        Args:
            hashtag: Hashtag to search (without #)
            limit: Number of results (max 25 per request)
        
        Returns:
            List of post dictionaries
        """
        if not self.access_token:
            logger.error("Instagram access token not configured")
            return []
        
        posts = []
        
        try:
            # Get hashtag ID
            hashtag_id_url = f"{self.base_url}/ig_hashtag_search"
            params = {
                'user_id': os.getenv('INSTAGRAM_USER_ID'),
                'q': hashtag,
                'access_token': self.access_token
            }
            
            response = requests.get(hashtag_id_url, params=params)
            if response.status_code != 200:
                logger.error(f"Error getting hashtag ID: {response.text}")
                return []
            
            hashtag_data = response.json()
            if 'data' not in hashtag_data or not hashtag_data['data']:
                return []
            
            hashtag_id = hashtag_data['data'][0]['id']
            
            # Get recent media for hashtag
            media_url = f"{self.base_url}/{hashtag_id}/recent_media"
            params = {
                'user_id': os.getenv('INSTAGRAM_USER_ID'),
                'fields': 'id,caption,media_type,media_url,permalink,timestamp,like_count,comments_count',
                'limit': min(limit, 25),
                'access_token': self.access_token
            }
            
            response = requests.get(media_url, params=params)
            if response.status_code != 200:
                logger.error(f"Error getting media: {response.text}")
                return []
            
            media_data = response.json()
            
            for item in media_data.get('data', []):
                post = {
                    'platform': 'instagram',
                    'post_id': item.get('id'),
                    'caption': item.get('caption', ''),
                    'media_type': item.get('media_type'),
                    'media_url': item.get('media_url'),
                    'url': item.get('permalink'),
                    'score': item.get('like_count', 0),
                    'comment_count': item.get('comments_count', 0),
                    'created_at': datetime.fromisoformat(item.get('timestamp', '').replace('Z', '+00:00')) if item.get('timestamp') else None,
                    'scraped_at': datetime.now(),
                    'hashtag': hashtag
                }
                posts.append(post)
            
            logger.info(f"Found {len(posts)} Instagram posts for #{hashtag}")
            
        except Exception as e:
            logger.error(f"Error scraping Instagram: {str(e)}")
        
        return posts
    
    def search_multiple_hashtags(self, hashtags: List[str], limit: int = 25) -> List[Dict]:
        """Search multiple hashtags"""
        all_posts = []
        seen_ids = set()
        
        for hashtag in hashtags:
            posts = self.search_hashtag(hashtag, limit=limit)
            for post in posts:
                if post['post_id'] not in seen_ids:
                    all_posts.append(post)
                    seen_ids.add(post['post_id'])
        
        return all_posts
    
    def get_user_posts(self, username: str, limit: int = 25) -> List[Dict]:
        """
        Get posts from a specific user
        
        Args:
            username: Instagram username
            limit: Number of posts
        
        Returns:
            List of post dictionaries
        """
        if not self.access_token:
            logger.error("Instagram access token not configured")
            return []
        
        # Implementation requires user ID lookup
        # This is a placeholder
        logger.warning("User posts require additional API setup")
        return []


if __name__ == '__main__':
    from dotenv import load_dotenv
    load_dotenv()
    
    scraper = InstagramScraper()
    
    # Test searching
    posts = scraper.search_hashtag('shadowwork', limit=10)
    
    print(f"Found {len(posts)} Instagram posts")
    for post in posts[:5]:
        print(f"\n{post['caption'][:100]}...")
        print(f"Likes: {post['score']} | Comments: {post['comment_count']}")
