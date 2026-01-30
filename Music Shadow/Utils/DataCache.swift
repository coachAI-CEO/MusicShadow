import Foundation
import Supabase

/// Lightweight in-memory cache for song_events and shadow_insights
/// Reduces repeated queries by caching data with TTL
final class DataCache {
    static let shared = DataCache()
    
    private var eventsCache: [SongEvent]?
    private var insightsCache: [ShadowInsight]?
    private var eventsCacheTimestamp: Date?
    private var insightsCacheTimestamp: Date?
    private var cachedUserId: UUID?
    
    /// Time-to-live for in-memory cached data.
    /// Phase 4 performance work: increase TTL so we hit Supabase less often
    /// while keeping data feeling fresh for users actively in the app.
    /// 
    /// 180 seconds (~3 minutes) strikes a balance between:
    /// - not refetching on every small navigation
    /// - still reflecting new logs reasonably quickly
    private let cacheTTL: TimeInterval = 180
    private let cacheLock = NSLock()
    
    private init() {}
    
    // MARK: - Events Cache
    
    /// Returns cached events only if they belong to the given user; otherwise nil.
    func getCachedEvents(userId: UUID) -> [SongEvent]? {
        cacheLock.lock()
        defer { cacheLock.unlock() }
        
        guard cachedUserId == userId,
              let events = eventsCache,
              let timestamp = eventsCacheTimestamp,
              Date().timeIntervalSince(timestamp) < cacheTTL else {
            return nil
        }
        return events
    }
    
    func setCachedEvents(_ events: [SongEvent], userId: UUID) {
        cacheLock.lock()
        defer { cacheLock.unlock() }
        
        eventsCache = events
        eventsCacheTimestamp = Date()
        cachedUserId = userId
    }
    
    func invalidateEventsCache() {
        cacheLock.lock()
        defer { cacheLock.unlock() }
        
        eventsCache = nil
        eventsCacheTimestamp = nil
    }
    
    // MARK: - Insights Cache
    
    /// Returns cached insights only if they belong to the given user; otherwise nil.
    func getCachedInsights(userId: UUID) -> [ShadowInsight]? {
        cacheLock.lock()
        defer { cacheLock.unlock() }
        
        guard cachedUserId == userId,
              let insights = insightsCache,
              let timestamp = insightsCacheTimestamp,
              Date().timeIntervalSince(timestamp) < cacheTTL else {
            return nil
        }
        return insights
    }
    
    func setCachedInsights(_ insights: [ShadowInsight], userId: UUID) {
        cacheLock.lock()
        defer { cacheLock.unlock() }
        
        insightsCache = insights
        insightsCacheTimestamp = Date()
        cachedUserId = userId
    }
    
    func invalidateInsightsCache() {
        cacheLock.lock()
        defer { cacheLock.unlock() }
        
        insightsCache = nil
        insightsCacheTimestamp = nil
        }
    
    // MARK: - Cache Management
    
    func invalidateAll() {
        cacheLock.lock()
        defer { cacheLock.unlock() }
        
        eventsCache = nil
        insightsCache = nil
        eventsCacheTimestamp = nil
        insightsCacheTimestamp = nil
        cachedUserId = nil
    }
    
    // MARK: - Last Refresh Time
    
    func getLastEventsRefreshTime() -> Date? {
        cacheLock.lock()
        defer { cacheLock.unlock() }
        return eventsCacheTimestamp
    }
    
    func getLastInsightsRefreshTime() -> Date? {
        cacheLock.lock()
        defer { cacheLock.unlock() }
        return insightsCacheTimestamp
    }
}
