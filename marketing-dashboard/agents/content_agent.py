"""
Content Generation Agent - Auto-generates marketing content based on trends
Uses LLM for content generation with context from trends
"""
import os
from typing import Dict, List, Optional
import logging
from datetime import datetime
import json

# Try to import OpenAI, fallback to template-based if not available
try:
    import openai
    OPENAI_AVAILABLE = True
except ImportError:
    OPENAI_AVAILABLE = False
    logging.warning("OpenAI not available, using template-based generation")

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


class ContentGenerationAgent:
    def __init__(self, use_llm: bool = True):
        """
        Initialize content generation agent
        
        Args:
            use_llm: Whether to use LLM (OpenAI) or template-based generation
        """
        self.use_llm = use_llm and OPENAI_AVAILABLE
        
        if self.use_llm:
            openai.api_key = os.getenv('OPENAI_API_KEY')
            self.model = os.getenv('OPENAI_MODEL', 'gpt-4')
        
        # Content templates
        self.templates = {
            'educational': {
                'instagram': "💡 {topic}\n\n{content}\n\n#ShadowWork #MusicTherapy #SelfAwareness",
                'twitter': "{topic}\n\n{content}\n\n#ShadowWork #MusicTherapy",
                'reddit': "**{topic}**\n\n{content}\n\nWhat are your thoughts?",
                'blog': "# {topic}\n\n{content}\n\n## Key Takeaways\n\n{key_points}"
            },
            'story': {
                'instagram': "✨ {story}\n\n{insight}\n\n#ShadowWork #HealingJourney",
                'twitter': "{story}\n\n{insight}\n\n#ShadowWork",
                'reddit': "**My Experience:** {story}\n\n{insight}",
                'blog': "# {title}\n\n{story}\n\n## What I Learned\n\n{insight}"
            },
            'tip': {
                'instagram': "💡 Tip: {tip}\n\n{explanation}\n\n#ShadowWorkTips",
                'twitter': "💡 {tip}\n\n{explanation}",
                'reddit': "**Tip:** {tip}\n\n{explanation}",
                'blog': "## {tip}\n\n{explanation}"
            },
            'question': {
                'instagram': "❓ {question}\n\nShare your thoughts below 👇\n\n#ShadowWork #Discussion",
                'twitter': "{question}\n\nWhat do you think?",
                'reddit': "**Question:** {question}\n\nWhat are your experiences?",
                'blog': "## {question}\n\n{content}"
            }
        }
    
    def generate_content(self, trend_data: Dict, content_type: str, 
                        platform: str, context: Optional[Dict] = None) -> Dict:
        """
        Generate content based on trend data
        
        Args:
            trend_data: Trend analysis result
            content_type: Type of content ('educational', 'story', 'tip', 'question')
            platform: Target platform ('instagram', 'twitter', 'reddit', 'blog')
            context: Additional context for generation
        
        Returns:
            Generated content dictionary
        """
        keyword = trend_data.get('keyword', 'shadow work')
        insights = trend_data.get('insights', [])
        recommendation = trend_data.get('recommendation', '')
        
        if self.use_llm:
            content = self._generate_with_llm(keyword, content_type, platform, insights, context)
        else:
            content = self._generate_with_template(keyword, content_type, platform, insights, context)
        
        return {
            'content': content,
            'platform': platform,
            'content_type': content_type,
            'keyword': keyword,
            'generated_at': datetime.now().isoformat(),
            'trend_context': {
                'direction': trend_data.get('current_trend', {}).get('direction'),
                'strength': trend_data.get('current_trend', {}).get('strength')
            }
        }
    
    def _generate_with_llm(self, keyword: str, content_type: str, 
                          platform: str, insights: List[str], context: Dict) -> str:
        """Generate content using LLM"""
        prompt = self._build_prompt(keyword, content_type, platform, insights, context)
        
        try:
            response = openai.ChatCompletion.create(
                model=self.model,
                messages=[
                    {"role": "system", "content": "You are a marketing content creator for Music Shadow, a shadow work journal app. Create engaging, authentic content that educates and inspires."},
                    {"role": "user", "content": prompt}
                ],
                temperature=0.7,
                max_tokens=500
            )
            return response.choices[0].message.content.strip()
        except Exception as e:
            logger.error(f"Error generating with LLM: {str(e)}")
            return self._generate_with_template(keyword, content_type, platform, insights, context)
    
    def _generate_with_template(self, keyword: str, content_type: str, 
                               platform: str, insights: List[str], context: Dict) -> str:
        """Generate content using templates"""
        template = self.templates.get(content_type, {}).get(platform, "{content}")
        
        # Generate content based on type
        if content_type == 'educational':
            topic = f"Understanding {keyword.title()}"
            content = f"Have you noticed how {keyword} affects your emotional state? Research shows that tracking these patterns can reveal deep insights about your inner landscape. Start noticing when music activates your nervous system - that's valuable data about your shadow."
            key_points = f"• {keyword} is a powerful tool for self-awareness\n• Patterns emerge when you track consistently\n• Music reveals what words can't express"
            return template.format(topic=topic, content=content, key_points=key_points)
        
        elif content_type == 'tip':
            tip = f"Track {keyword} patterns"
            explanation = f"When you notice {keyword} in your daily life, log it in Music Shadow. Over time, you'll see patterns that reveal deeper truths about your emotional landscape."
            return template.format(tip=tip, explanation=explanation)
        
        elif content_type == 'question':
            question = f"How does {keyword} show up in your life?"
            return template.format(question=question)
        
        else:  # story
            story = f"I've been tracking {keyword} for the past month, and the patterns I've discovered are incredible."
            insight = "Every song that activates you is a map to your shadow. Music Shadow helps you read the map."
            return template.format(story=story, insight=insight, title=f"My {keyword.title()} Journey")
    
    def _build_prompt(self, keyword: str, content_type: str, platform: str, 
                     insights: List[str], context: Dict) -> str:
        """Build prompt for LLM"""
        platform_guidelines = {
            'instagram': "Create engaging, visual-first content with emojis. Keep it concise but meaningful.",
            'twitter': "Create concise, engaging tweets. Use hashtags strategically. Max 280 characters.",
            'reddit': "Create thoughtful, discussion-starting content. Be authentic and helpful.",
            'blog': "Create comprehensive, well-structured blog post content with clear sections."
        }
        
        prompt = f"""
Generate {content_type} content about {keyword} for {platform}.

Platform guidelines: {platform_guidelines.get(platform, '')}

Trend insights: {', '.join(insights) if insights else 'No specific insights'}

Context: {json.dumps(context) if context else 'None'}

Create engaging, authentic content that:
- Educates about shadow work and music therapy
- Encourages self-awareness
- Promotes Music Shadow app naturally (not salesy)
- Matches the {platform} platform style

Generate the content now:
"""
        return prompt
    
    def generate_content_calendar(self, trends: List[Dict], days: int = 7) -> List[Dict]:
        """
        Generate content calendar based on trends
        
        Args:
            trends: List of trend analysis results
            days: Number of days to plan
        
        Returns:
            List of scheduled content items
        """
        calendar = []
        platforms = ['instagram', 'twitter', 'reddit']
        content_types = ['educational', 'tip', 'question', 'story']
        
        # Prioritize trending keywords
        sorted_trends = sorted(
            trends,
            key=lambda x: float(x.get('current_trend', {}).get('strength', '0%').replace('%', '')) or 0,
            reverse=True
        )
        
        for day in range(days):
            for platform in platforms:
                # Select trend and content type
                trend = sorted_trends[day % len(sorted_trends)] if sorted_trends else trends[0]
                content_type = content_types[(day + platforms.index(platform)) % len(content_types)]
                
                content = self.generate_content(trend, content_type, platform)
                content['scheduled_date'] = (datetime.now() + timedelta(days=day)).isoformat()
                calendar.append(content)
        
        return calendar
    
    def optimize_content(self, content: str, platform: str, 
                        performance_data: Optional[Dict] = None) -> str:
        """
        Optimize content based on performance data
        
        Args:
            content: Original content
            platform: Target platform
            performance_data: Historical performance data
        
        Returns:
            Optimized content
        """
        # Simple optimization rules (can be enhanced with ML)
        optimizations = []
        
        if platform == 'twitter' and len(content) > 250:
            optimizations.append("Content too long for Twitter, consider shortening")
        
        if platform == 'instagram' and content.count('#') < 3:
            optimizations.append("Consider adding more relevant hashtags")
        
        if performance_data:
            # Learn from performance
            if performance_data.get('engagement_rate', 0) < 0.05:
                optimizations.append("Low engagement - try more engaging hook")
        
        return content  # Return optimized version


if __name__ == '__main__':
    agent = ContentGenerationAgent(use_llm=False)  # Use templates for testing
    
    # Mock trend data
    trend_data = {
        'keyword': 'shadow work',
        'current_trend': {'direction': 'increasing', 'strength': '25%'},
        'insights': ['Shadow work is trending strongly', 'Expected to grow significantly'],
        'recommendation': 'Capitalize on trend - create content now'
    }
    
    # Generate content for different platforms
    print("📝 Generated Content:\n")
    
    for platform in ['instagram', 'twitter', 'reddit']:
        content = agent.generate_content(trend_data, 'educational', platform)
        print(f"\n[{platform.upper()}]")
        print(content['content'])
        print("-" * 50)
