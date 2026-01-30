# MusicKit Setup Instructions

## Issue
The error "Framework did not contain an Info" occurs because MusicKit is being embedded when it should only be linked as a system framework.

## Solution

### Step 1: Remove MusicKit from Embedded Frameworks
1. Open Xcode
2. Select your project in the navigator
3. Select the "Music Shadow" target
4. Go to **General** tab
5. Scroll down to **Frameworks, Libraries, and Embedded Content**
6. If you see `MusicKit.framework` listed:
   - Select it
   - Change the dropdown from "Embed & Sign" or "Embed Without Signing" to **"Do Not Embed"**
   - OR remove it entirely (MusicKit doesn't need to be added here)

### Step 2: Verify MusicKit is Available
MusicKit is a system framework available in iOS 15.0+. You don't need to add it manually - just `import MusicKit` in your code (which is already done).

### Step 3: Check Deployment Target
Ensure your iOS deployment target is at least iOS 15.0 (currently set to 26.1 which seems incorrect - should be something like 17.0 or 18.0).

### Step 4: Request Authorization (Optional but Recommended)
MusicKit requires authorization to search the catalog. Add this to your app startup or before first search:

```swift
// In Music_ShadowApp.swift or before first search
Task {
    let status = await MusicAuthorization.request()
    // Handle authorization status if needed
}
```

## Notes
- MusicKit is a system framework - it's already on the device
- You only need to `import MusicKit` - no manual framework linking required
- The framework should NOT be embedded in your app bundle
- Authorization is required for catalog searches (but may work without it in some cases)

