"""
YouTube Scraper for Music Shadow Marketing Dashboard
Uses YouTube Data API v3
"""
import os
from googleapiclient.discovery import build
from googleapiclient.errors import HttpError
from typing import List, Dict
from datetime import datetime, timedelta
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


class YouTubeScraper:
    def __init__(self):
        """Initialize YouTube API client"""
        api_key = os.getenv('YOUTUBE_API_KEY')
        if not api_key:
            logger.error("YouTube API key not configured")
            self.youtube = None
        else:
            self.youtube = build('youtube', 'v3', developerKey=api_key)
        
        # Keywords to search
        self.keywords = [
            'shadow work', 'music therapy', 'IFS therapy', 'emotional activation',
            'music journal', 'pattern recognition', 'emotional intelligence',
            'inner child work', 'nervous system activation'
        ]
    
    def search_videos(self, query: str, max_results: int = 50, 
                     days_back: int = 30) -> List[Dict]:
        """
        Search YouTube videos
        
        Args:
            query: Search query
            max_results: Maximum results (max 50 per request)
            days_back: How many days back to search
        
        Returns:
            List of video dictionaries
        """
        if not self.youtube:
            logger.error("YouTube API not initialized")
            return []
        
        videos = []
        published_after = (datetime.now() - timedelta(days=days_back)).isoformat() + 'Z'
        
        try:
            request = self.youtube.search().list(
                part='snippet',
                q=query,
                type='video',
                maxResults=min(max_results, 50),
                order='relevance',
                publishedAfter=published_after
            )
            
            response = request.execute()
            
            video_ids = [item['id']['videoId'] for item in response.get('items', [])]
            
            # Get detailed video statistics
            if video_ids:
                stats_request = self.youtube.videos().list(
                    part='statistics,snippet,contentDetails',
                    id=','.join(video_ids)
                )
                stats_response = stats_request.execute()
                
                for item in stats_response.get('items', []):
                    snippet = item['snippet']
                    stats = item['statistics']
                    
                    video = {
                        'platform': 'youtube',
                        'video_id': item['id'],
                        'title': snippet.get('title', ''),
                        'description': snippet.get('description', '')[:1000],  # Limit length
                        'channel': snippet.get('channelTitle', ''),
                        'channel_id': snippet.get('channelId', ''),
                        'url': f"https://www.youtube.com/watch?v={item['id']}",
                        'thumbnail': snippet.get('thumbnails', {}).get('high', {}).get('url', ''),
                        'score': int(stats.get('likeCount', 0)),
                        'view_count': int(stats.get('viewCount', 0)),
                        'comment_count': int(stats.get('commentCount', 0)),
                        'created_at': datetime.fromisoformat(snippet.get('publishedAt', '').replace('Z', '+00:00')),
                        'scraped_at': datetime.now(),
                        'duration': item.get('contentDetails', {}).get('duration', ''),
                        'keywords': [query]
                    }
                    videos.append(video)
            
            logger.info(f"Found {len(videos)} YouTube videos for query: {query}")
            
        except HttpError as e:
            logger.error(f"YouTube API error: {str(e)}")
        except Exception as e:
            logger.error(f"Error searching YouTube: {str(e)}")
        
        return videos
    
    def search_keywords(self, keywords: List[str], max_results: int = 50) -> List[Dict]:
        """Search for multiple keywords"""
        all_videos = []
        seen_ids = set()
        
        for keyword in keywords:
            videos = self.search_videos(keyword, max_results=max_results)
            for video in videos:
                if video['video_id'] not in seen_ids:
                    all_videos.append(video)
                    seen_ids.add(video['video_id'])
        
        return all_videos
    
    def get_channel_videos(self, channel_id: str, max_results: int = 50) -> List[Dict]:
        """
        Get videos from a specific channel
        
        Args:
            channel_id: YouTube channel ID
            max_results: Maximum results
        
        Returns:
            List of video dictionaries
        """
        if not self.youtube:
            return []
        
        videos = []
        
        try:
            # Get uploads playlist ID
            channel_request = self.youtube.channels().list(
                part='contentDetails',
                id=channel_id
            )
            channel_response = channel_request.execute()
            
            if not channel_response.get('items'):
                return []
            
            uploads_playlist_id = channel_response['items'][0]['contentDetails']['relatedPlaylists']['uploads']
            
            # Get videos from playlist
            playlist_request = self.youtube.playlistItems().list(
                part='snippet',
                playlistId=uploads_playlist_id,
                maxResults=min(max_results, 50)
            )
            playlist_response = playlist_request.execute()
            
            video_ids = [item['snippet']['resourceId']['videoId'] 
                        for item in playlist_response.get('items', [])]
            
            # Get video details
            if video_ids:
                stats_request = self.youtube.videos().list(
                    part='statistics,snippet',
                    id=','.join(video_ids)
                )
                stats_response = stats_request.execute()
                
                for item in stats_response.get('items', []):
                    snippet = item['snippet']
                    stats = item['statistics']
                    
                    video = {
                        'platform': 'youtube',
                        'video_id': item['id'],
                        'title': snippet.get('title', ''),
                        'description': snippet.get('description', '')[:1000],
                        'channel': snippet.get('channelTitle', ''),
                        'url': f"https://www.youtube.com/watch?v={item['id']}",
                        'score': int(stats.get('likeCount', 0)),
                        'view_count': int(stats.get('viewCount', 0)),
                        'comment_count': int(stats.get('commentCount', 0)),
                        'created_at': datetime.fromisoformat(snippet.get('publishedAt', '').replace('Z', '+00:00')),
                        'scraped_at': datetime.now()
                    }
                    videos.append(video)
            
        except Exception as e:
            logger.error(f"Error getting channel videos: {str(e)}")
        
        return videos


if __name__ == '__main__':
    from dotenv import load_dotenv
    load_dotenv()
    
    scraper = YouTubeScraper()
    
    # Test searching
    videos = scraper.search_keywords(['shadow work', 'music therapy'], max_results=10)
    
    print(f"Found {len(videos)} YouTube videos")
    for video in videos[:5]:
        print(f"\n{video['title']}")
        print(f"Channel: {video['channel']}")
        print(f"Views: {video['view_count']} | Likes: {video['score']}")
