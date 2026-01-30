#!/usr/bin/env python3
"""
Script to run scrapers and store data
Usage: python scripts/run_scraper.py [reddit|twitter|all]
"""
import sys
import os
from pathlib import Path

# Add parent directory to path
sys.path.insert(0, str(Path(__file__).parent.parent))

from dotenv import load_dotenv
load_dotenv()

from scrapers.reddit_scraper import RedditScraper
from scrapers.twitter_scraper import TwitterScraper
from analyzers.sentiment import SentimentAnalyzer
import json
from datetime import datetime

def save_to_json(data, filename):
    """Save data to JSON file"""
    output_dir = Path(__file__).parent.parent / 'data'
    output_dir.mkdir(exist_ok=True)
    
    filepath = output_dir / f"{filename}_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
    with open(filepath, 'w') as f:
        json.dump(data, f, indent=2, default=str)
    print(f"Saved {len(data)} items to {filepath}")

def scrape_reddit():
    """Scrape Reddit"""
    print("🔴 Scraping Reddit...")
    scraper = RedditScraper()
    
    subreddits = os.getenv('SUBREDDITS', 'shadowwork,InternalFamilySystems,therapy,Music').split(',')
    subreddits = [s.strip() for s in subreddits]
    
    all_posts = scraper.scrape_multiple_subreddits(subreddits, limit=50)
    
    # Analyze sentiment
    analyzer = SentimentAnalyzer()
    for post in all_posts:
        text = f"{post['title']} {post.get('content', '')}"
        sentiment = analyzer.analyze(text)
        post['sentiment'] = sentiment['label']
        post['sentiment_score'] = sentiment['compound']
    
    save_to_json(all_posts, 'reddit_posts')
    print(f"✅ Scraped {len(all_posts)} Reddit posts")
    return all_posts

def scrape_twitter():
    """Scrape Twitter"""
    print("🐦 Scraping Twitter...")
    scraper = TwitterScraper()
    
    keywords = os.getenv('KEYWORDS', 'shadow work,music therapy').split(',')
    keywords = [k.strip() for k in keywords]
    
    all_tweets = scraper.search_keywords(keywords[:3], max_results=50)  # Limit to avoid rate limits
    
    # Analyze sentiment
    analyzer = SentimentAnalyzer()
    for tweet in all_tweets:
        sentiment = analyzer.analyze(tweet['content'])
        tweet['sentiment'] = sentiment['label']
        tweet['sentiment_score'] = sentiment['compound']
    
    save_to_json(all_tweets, 'twitter_posts')
    print(f"✅ Scraped {len(all_tweets)} Twitter posts")
    return all_tweets

def main():
    if len(sys.argv) < 2:
        print("Usage: python run_scraper.py [reddit|twitter|all]")
        sys.exit(1)
    
    command = sys.argv[1].lower()
    
    if command == 'reddit':
        scrape_reddit()
    elif command == 'twitter':
        scrape_twitter()
    elif command == 'all':
        scrape_reddit()
        scrape_twitter()
    else:
        print(f"Unknown command: {command}")
        print("Usage: python run_scraper.py [reddit|twitter|all]")
        sys.exit(1)

if __name__ == '__main__':
    main()
