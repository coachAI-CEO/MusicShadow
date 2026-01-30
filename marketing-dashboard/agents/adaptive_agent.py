"""
Adaptive Learning Agent - Learns from data and adapts strategies
Uses reinforcement learning and feedback loops
"""
import pandas as pd
import numpy as np
from datetime import datetime, timedelta
from typing import Dict, List, Optional
import logging
import json
import os

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


class AdaptiveLearningAgent:
    def __init__(self, learning_file: str = 'data/learning_data.json'):
        """
        Initialize adaptive learning agent
        
        Args:
            learning_file: Path to store learning data
        """
        self.learning_file = learning_file
        self.learning_data = self._load_learning_data()
        
        # Learning parameters
        self.performance_history = []
        self.strategy_weights = {
            'educational': 1.0,
            'story': 1.0,
            'tip': 1.0,
            'question': 1.0
        }
        self.platform_performance = {
            'instagram': {'avg_engagement': 0.05, 'count': 0},
            'twitter': {'avg_engagement': 0.03, 'count': 0},
            'reddit': {'avg_engagement': 0.08, 'count': 0},
            'youtube': {'avg_engagement': 0.10, 'count': 0}
        }
        self.optimal_posting_times = {
            'instagram': {'hour': 18, 'day': 'wednesday'},
            'twitter': {'hour': 9, 'day': 'tuesday'},
            'reddit': {'hour': 14, 'day': 'thursday'}
        }
    
    def _load_learning_data(self) -> Dict:
        """Load learning data from file"""
        if os.path.exists(self.learning_file):
            try:
                with open(self.learning_file, 'r') as f:
                    return json.load(f)
            except Exception as e:
                logger.error(f"Error loading learning data: {str(e)}")
        return {}
    
    def _save_learning_data(self):
        """Save learning data to file"""
        os.makedirs(os.path.dirname(self.learning_file), exist_ok=True)
        try:
            with open(self.learning_file, 'w') as f:
                json.dump(self.learning_data, f, indent=2, default=str)
        except Exception as e:
            logger.error(f"Error saving learning data: {str(e)}")
    
    def learn_from_performance(self, content_id: str, performance: Dict):
        """
        Learn from content performance
        
        Args:
            content_id: Unique content identifier
            performance: Performance metrics
                - engagement_rate: float
                - views: int
                - likes: int
                - comments: int
                - platform: str
                - content_type: str
                - posted_at: datetime
        """
        engagement_rate = performance.get('engagement_rate', 0)
        platform = performance.get('platform', 'unknown')
        content_type = performance.get('content_type', 'unknown')
        posted_at = performance.get('posted_at', datetime.now())
        
        # Update platform performance
        if platform in self.platform_performance:
            current = self.platform_performance[platform]
            count = current['count']
            avg = current['avg_engagement']
            new_avg = (avg * count + engagement_rate) / (count + 1)
            self.platform_performance[platform] = {
                'avg_engagement': new_avg,
                'count': count + 1
            }
        
        # Update content type weights (reinforcement learning)
        if content_type in self.strategy_weights:
            # Reward successful content types
            if engagement_rate > 0.05:  # Above average
                self.strategy_weights[content_type] *= 1.1
            elif engagement_rate < 0.02:  # Below average
                self.strategy_weights[content_type] *= 0.95
        
        # Learn optimal posting times
        hour = posted_at.hour
        day = posted_at.strftime('%A').lower()
        
        if platform in self.optimal_posting_times:
            # Simple learning: track performance by time
            time_key = f"{platform}_{day}_{hour}"
            if time_key not in self.learning_data:
                self.learning_data[time_key] = {'total_engagement': 0, 'count': 0}
            
            self.learning_data[time_key]['total_engagement'] += engagement_rate
            self.learning_data[time_key]['count'] += 1
            
            # Update optimal time if this performs better
            current_avg = self.learning_data[time_key]['total_engagement'] / self.learning_data[time_key]['count']
            optimal = self.optimal_posting_times[platform]
            optimal_key = f"{platform}_{optimal['day']}_{optimal['hour']}"
            
            if optimal_key in self.learning_data:
                optimal_avg = self.learning_data[optimal_key]['total_engagement'] / self.learning_data[optimal_key]['count']
                if current_avg > optimal_avg:
                    self.optimal_posting_times[platform] = {'hour': hour, 'day': day}
        
        # Store performance
        self.performance_history.append({
            'content_id': content_id,
            'engagement_rate': engagement_rate,
            'platform': platform,
            'content_type': content_type,
            'timestamp': datetime.now().isoformat()
        })
        
        # Save learning data
        self._save_learning_data()
        
        logger.info(f"Learned from content {content_id}: engagement={engagement_rate:.2%}")
    
    def get_optimal_strategy(self, platform: str) -> Dict:
        """
        Get optimal content strategy for platform
        
        Args:
            platform: Target platform
        
        Returns:
            Strategy recommendations
        """
        # Get best content type for platform
        content_types = list(self.strategy_weights.keys())
        best_type = max(content_types, key=lambda x: self.strategy_weights[x])
        
        # Get optimal posting time
        optimal_time = self.optimal_posting_times.get(platform, {'hour': 12, 'day': 'monday'})
        
        # Get platform performance
        platform_perf = self.platform_performance.get(platform, {'avg_engagement': 0.05})
        
        return {
            'platform': platform,
            'recommended_content_type': best_type,
            'optimal_posting_time': optimal_time,
            'expected_engagement': platform_perf['avg_engagement'],
            'content_type_weights': self.strategy_weights.copy(),
            'confidence': min(platform_perf['count'] / 10, 1.0)  # Confidence based on data points
        }
    
    def adapt_to_trends(self, current_trends: List[Dict], historical_performance: List[Dict]) -> Dict:
        """
        Adapt strategy based on current trends and historical performance
        
        Args:
            current_trends: Current trend analysis
            historical_performance: Historical content performance
        
        Returns:
            Adapted strategy recommendations
        """
        # Analyze what worked in the past
        successful_content = [p for p in historical_performance if p.get('engagement_rate', 0) > 0.05]
        
        # Find patterns in successful content
        successful_keywords = {}
        for content in successful_content:
            keywords = content.get('keywords', [])
            for keyword in keywords:
                successful_keywords[keyword] = successful_keywords.get(keyword, 0) + 1
        
        # Match current trends with successful patterns
        recommendations = []
        for trend in current_trends:
            keyword = trend.get('keyword', '')
            if keyword in successful_keywords:
                recommendations.append({
                    'keyword': keyword,
                    'priority': 'high',
                    'reason': f'Previously successful ({successful_keywords[keyword]} times)',
                    'recommended_action': 'Create content now'
                })
        
        return {
            'recommendations': recommendations,
            'successful_keywords': dict(sorted(successful_keywords.items(), key=lambda x: x[1], reverse=True)[:10]),
            'adaptation_confidence': len(successful_content) / max(len(historical_performance), 1)
        }
    
    def predict_performance(self, content_type: str, platform: str, 
                           keyword: str, posting_time: Optional[datetime] = None) -> Dict:
        """
        Predict content performance before posting
        
        Args:
            content_type: Type of content
            platform: Target platform
            keyword: Main keyword
            posting_time: When content will be posted
        
        Returns:
            Performance prediction
        """
        # Base prediction from historical data
        base_engagement = self.platform_performance.get(platform, {}).get('avg_engagement', 0.05)
        
        # Adjust for content type
        content_weight = self.strategy_weights.get(content_type, 1.0)
        predicted_engagement = base_engagement * content_weight
        
        # Adjust for posting time
        if posting_time:
            hour = posting_time.hour
            day = posting_time.strftime('%A').lower()
            time_key = f"{platform}_{day}_{hour}"
            
            if time_key in self.learning_data:
                time_avg = (self.learning_data[time_key]['total_engagement'] / 
                           max(self.learning_data[time_key]['count'], 1))
                predicted_engagement = (predicted_engagement + time_avg) / 2
        
        # Confidence based on data availability
        platform_data = self.platform_performance.get(platform, {})
        confidence = min(platform_data.get('count', 0) / 20, 1.0)
        
        return {
            'predicted_engagement': predicted_engagement,
            'confidence': confidence,
            'factors': {
                'platform_base': base_engagement,
                'content_type_multiplier': content_weight,
                'time_optimization': posting_time is not None
            }
        }


if __name__ == '__main__':
    agent = AdaptiveLearningAgent()
    
    # Simulate learning
    print("🧠 Adaptive Learning Agent Test\n")
    
    # Learn from some performance data
    for i in range(10):
        agent.learn_from_performance(
            f"content_{i}",
            {
                'engagement_rate': np.random.uniform(0.02, 0.10),
                'platform': np.random.choice(['instagram', 'twitter', 'reddit']),
                'content_type': np.random.choice(['educational', 'story', 'tip']),
                'posted_at': datetime.now() - timedelta(days=np.random.randint(0, 7))
            }
        )
    
    # Get optimal strategy
    strategy = agent.get_optimal_strategy('instagram')
    print("📊 Optimal Strategy for Instagram:")
    print(f"  Best content type: {strategy['recommended_content_type']}")
    print(f"  Optimal time: {strategy['optimal_posting_time']}")
    print(f"  Expected engagement: {strategy['expected_engagement']:.2%}")
    print(f"  Confidence: {strategy['confidence']:.2%}")
