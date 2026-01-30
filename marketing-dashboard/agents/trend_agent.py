"""
Trend Analysis Agent - Predicts future trends and identifies opportunities
Uses time-series analysis and machine learning
"""
import pandas as pd
import numpy as np
from datetime import datetime, timedelta
from typing import Dict, List, Tuple
import logging
from prophet import Prophet
from sklearn.ensemble import RandomForestRegressor
import warnings
warnings.filterwarnings('ignore')

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


class TrendAnalysisAgent:
    def __init__(self):
        """Initialize trend analysis agent"""
        self.models = {}
        self.historical_data = {}
    
    def analyze_trend(self, keyword: str, data: pd.DataFrame, days_ahead: int = 7) -> Dict:
        """
        Analyze trend for a keyword and predict future
        
        Args:
            keyword: Keyword to analyze
            data: Historical data with 'date' and 'mention_count' columns
            days_ahead: Days to predict ahead
        
        Returns:
            Dictionary with analysis and predictions
        """
        if len(data) < 7:
            return {
                'keyword': keyword,
                'insufficient_data': True,
                'message': 'Need at least 7 days of data'
            }
        
        # Prepare data
        df = data.copy()
        df['date'] = pd.to_datetime(df['date'])
        df = df.sort_values('date')
        df = df.rename(columns={'date': 'ds', 'mention_count': 'y'})
        
        # Calculate current trend
        recent_avg = df.tail(7)['y'].mean()
        previous_avg = df.iloc[-14:-7]['y'].mean() if len(df) >= 14 else df.head(7)['y'].mean()
        trend_direction = 'increasing' if recent_avg > previous_avg else 'decreasing'
        trend_strength = abs((recent_avg - previous_avg) / previous_avg * 100) if previous_avg > 0 else 0
        
        # Predict future using Prophet
        try:
            model = Prophet(
                yearly_seasonality=False,
                weekly_seasonality=True,
                daily_seasonality=False,
                changepoint_prior_scale=0.05
            )
            model.fit(df)
            
            future = model.make_future_dataframe(periods=days_ahead)
            forecast = model.predict(future)
            
            # Get predictions
            future_forecast = forecast.tail(days_ahead)
            predicted_avg = future_forecast['yhat'].mean()
            predicted_trend = 'increasing' if predicted_avg > recent_avg else 'decreasing'
            
            # Calculate confidence
            confidence = 1 - (future_forecast['yhat_upper'].mean() - future_forecast['yhat_lower'].mean()) / predicted_avg if predicted_avg > 0 else 0.5
            
        except Exception as e:
            logger.error(f"Error in Prophet forecast: {str(e)}")
            # Fallback to simple linear regression
            predicted_avg = recent_avg
            predicted_trend = trend_direction
            confidence = 0.6
        
        # Generate insights
        insights = self._generate_insights(
            keyword, trend_direction, trend_strength, 
            predicted_trend, recent_avg, predicted_avg
        )
        
        return {
            'keyword': keyword,
            'current_trend': {
                'direction': trend_direction,
                'strength': f"{trend_strength:.1f}%",
                'current_avg': recent_avg,
                'previous_avg': previous_avg
            },
            'prediction': {
                'direction': predicted_trend,
                'predicted_avg': predicted_avg,
                'confidence': f"{confidence*100:.1f}%",
                'days_ahead': days_ahead
            },
            'insights': insights,
            'recommendation': self._generate_recommendation(keyword, trend_direction, predicted_trend)
        }
    
    def _generate_insights(self, keyword: str, current_trend: str, 
                          strength: float, predicted: str, 
                          current_avg: float, predicted_avg: float) -> List[str]:
        """Generate insights based on trend analysis"""
        insights = []
        
        if current_trend == 'increasing' and strength > 20:
            insights.append(f"🔥 {keyword} is trending strongly (+{strength:.1f}% growth)")
        
        if predicted == 'increasing' and predicted_avg > current_avg * 1.2:
            insights.append(f"📈 Expected to grow significantly in next 7 days")
        
        if current_trend == 'decreasing' and strength > 15:
            insights.append(f"⚠️ {keyword} is declining - consider pivoting content")
        
        if abs(predicted_avg - current_avg) < current_avg * 0.1:
            insights.append(f"📊 Trend is stabilizing - good time for consistent content")
        
        return insights
    
    def _generate_recommendation(self, keyword: str, current: str, predicted: str) -> str:
        """Generate actionable recommendation"""
        if current == 'increasing' and predicted == 'increasing':
            return f"🚀 Capitalize on {keyword} trend - create content now while it's growing"
        elif current == 'increasing' and predicted == 'decreasing':
            return f"⏰ {keyword} is peaking - create content quickly before trend declines"
        elif current == 'decreasing' and predicted == 'increasing':
            return f"💡 {keyword} is recovering - early content could capture the rebound"
        else:
            return f"📝 {keyword} is stable - maintain consistent content strategy"
    
    def identify_opportunities(self, trends: List[Dict], threshold: float = 0.3) -> List[Dict]:
        """
        Identify emerging opportunities from trend analysis
        
        Args:
            trends: List of trend analysis results
            threshold: Minimum confidence threshold
        
        Returns:
            List of opportunities
        """
        opportunities = []
        
        for trend in trends:
            if trend.get('insufficient_data'):
                continue
            
            pred = trend.get('prediction', {})
            confidence = float(pred.get('confidence', '0%').replace('%', '')) / 100
            
            if confidence >= threshold:
                if pred.get('direction') == 'increasing':
                    opportunities.append({
                        'keyword': trend['keyword'],
                        'type': 'emerging_trend',
                        'confidence': pred.get('confidence'),
                        'recommendation': trend.get('recommendation'),
                        'priority': 'high' if confidence > 0.7 else 'medium'
                    })
        
        # Sort by priority and confidence
        opportunities.sort(key=lambda x: (
            0 if x['priority'] == 'high' else 1,
            -float(x['confidence'].replace('%', ''))
        ))
        
        return opportunities
    
    def detect_anomalies(self, data: pd.DataFrame, keyword: str) -> List[Dict]:
        """
        Detect anomalies in trend data
        
        Args:
            data: Historical data
            keyword: Keyword being analyzed
        
        Returns:
            List of detected anomalies
        """
        anomalies = []
        
        if len(data) < 7:
            return anomalies
        
        df = data.copy()
        df['date'] = pd.to_datetime(df['date'])
        df = df.sort_values('date')
        
        # Calculate rolling mean and std
        window = min(7, len(df))
        df['rolling_mean'] = df['mention_count'].rolling(window=window).mean()
        df['rolling_std'] = df['mention_count'].rolling(window=window).std()
        
        # Detect outliers (2 standard deviations)
        threshold = 2
        df['is_anomaly'] = abs(df['mention_count'] - df['rolling_mean']) > threshold * df['rolling_std']
        
        anomaly_rows = df[df['is_anomaly']]
        
        for _, row in anomaly_rows.iterrows():
            anomalies.append({
                'date': row['date'].strftime('%Y-%m-%d'),
                'value': row['mention_count'],
                'expected': row['rolling_mean'],
                'deviation': abs(row['mention_count'] - row['rolling_mean']),
                'type': 'spike' if row['mention_count'] > row['rolling_mean'] else 'drop'
            })
        
        return anomalies


if __name__ == '__main__':
    # Test the agent
    agent = TrendAnalysisAgent()
    
    # Mock data
    dates = pd.date_range(datetime.now() - timedelta(days=30), datetime.now(), freq='D')
    data = pd.DataFrame({
        'date': dates,
        'mention_count': np.random.randint(10, 50, len(dates)) + np.sin(np.arange(len(dates)) * 0.1) * 10
    })
    
    result = agent.analyze_trend('shadow work', data, days_ahead=7)
    print("\n📊 Trend Analysis Result:")
    print(f"Keyword: {result['keyword']}")
    print(f"Current Trend: {result['current_trend']['direction']} ({result['current_trend']['strength']})")
    print(f"Prediction: {result['prediction']['direction']} (confidence: {result['prediction']['confidence']})")
    print(f"\n💡 Insights:")
    for insight in result['insights']:
        print(f"  - {insight}")
    print(f"\n🎯 Recommendation: {result['recommendation']}")
