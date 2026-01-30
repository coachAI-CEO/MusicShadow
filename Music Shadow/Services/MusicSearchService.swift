import Foundation
import Combine

#if canImport(MusicKit)
import MusicKit
#endif

/// Service for searching Apple Music catalog to validate song and artist names
@MainActor
class MusicSearchService: ObservableObject {
    @Published var searchResults: [MusicSearchResult] = []
    @Published var isSearching: Bool = false
    
    private var searchTask: Task<Void, Never>?
    private var debounceTask: Task<Void, Never>?
    
    // Feature flag: Set to false to disable MusicKit search (for debugging crashes)
    private let isMusicKitEnabled = false // Temporarily disabled due to crashes
    
    /// Search for songs matching the given query (with debouncing)
    func searchSongs(query: String) async {
        // If MusicKit is disabled, return early
        guard isMusicKitEnabled else {
            searchResults = []
            return
        }
        // Cancel previous debounce
        debounceTask?.cancel()
        
        // Clear results if query is too short
        guard query.count >= 2 else {
            searchResults = []
            return
        }
        
        // Debounce: wait 300ms before searching to avoid too many requests
        debounceTask = Task {
            try? await Task.sleep(nanoseconds: 300_000_000) // 300ms delay
            
            guard !Task.isCancelled else { return }
            
            // Cancel previous search
            searchTask?.cancel()
            
            isSearching = true
            searchTask = Task { @MainActor in
                #if canImport(MusicKit)
                // Wrap everything in a do-catch to prevent any crashes
                do {
                    // Small delay to ensure app is fully initialized
                    try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
                    
                    guard !Task.isCancelled else { return }
                    
                    // Check authorization status - use current status first to avoid unnecessary prompts
                    let currentStatus = MusicAuthorization.currentStatus
                    
                    // If not determined, request authorization
                    let authStatus: MusicAuthorization.Status
                    if currentStatus == .notDetermined {
                        authStatus = await MusicAuthorization.request()
                    } else {
                        authStatus = currentStatus
                    }
                    
                    guard !Task.isCancelled else { return }
                    
                    // Only proceed if authorized
                    // If denied or restricted, just return empty results (user can still type manually)
                    if authStatus != .authorized {
                        searchResults = []
                        isSearching = false
                        return
                    }
                    
                    guard !Task.isCancelled else { return }
                    
                    // Perform search with error handling
                    var request = MusicCatalogSearchRequest(term: query, types: [Song.self])
                    request.limit = 10
                    
                    let response = try await request.response()
                    
                    guard !Task.isCancelled else { return }
                    
                    // Safely extract results
                    let results = response.songs.compactMap { song -> MusicSearchResult? in
                        // Access properties safely
                        let title = song.title
                        let artistName = song.artistName
                        
                        // Skip if empty
                        guard !title.isEmpty, !artistName.isEmpty else {
                            return nil
                        }
                        
                        // Safely get ID
                        let songId = String(describing: song.id.rawValue)
                        
                        return MusicSearchResult(
                            id: songId,
                            title: title,
                            artist: artistName,
                            album: song.albumTitle
                        )
                    }
                    
                    guard !Task.isCancelled else { return }
                    
                    searchResults = results
                    isSearching = false
                } catch {
                    guard !Task.isCancelled else { return }
                    // Silently fail - user can still enter manually
                    // Don't crash the app if MusicKit fails
                    searchResults = []
                    isSearching = false
                }
                #else
                // MusicKit not available - gracefully degrade
                searchResults = []
                isSearching = false
                #endif
            }
        }
    }
    
    func cancelSearch() {
        debounceTask?.cancel()
        debounceTask = nil
        searchTask?.cancel()
        searchTask = nil
        searchResults = []
        isSearching = false
    }
}

/// Result from Apple Music search
struct MusicSearchResult: Identifiable {
    let id: String
    let title: String
    let artist: String
    let album: String?
}

