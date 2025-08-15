# Team Invite Deep Linking Implementation

## Overview
This implementation enables users to share teams via invite links that can be opened by other users to join teams directly.

## How It Works

### 1. Team Link Generation
When a user clicks the "Share" button in team details:

1. **Copy to Clipboard Option**: 
   - Calls `FirebaseTeamsService.generateTeamLink(teamId)`
   - Generates unique token: `timestamp + teamId_prefix`
   - Stores invite data in Firebase `team_links` collection
   - Returns shareable URL: `https://wiseworkout.com/team/{token}`
   - Copies link to clipboard

2. **Share to Social Media Option**:
   - Same link generation process
   - Shows dialog with share options for different platforms
   - Provides pre-formatted share message

### 2. Firebase Team Links Collection Structure
```javascript
team_links/{invite_token}: {
  teamId: "actual_team_id",
  createdBy: "user_id_who_created_link",
  createdAt: timestamp,
  expiresAt: timestamp (30 days from creation),
  isActive: true,
  clickCount: 0,
  lastAccessed: timestamp
}
```

### 3. Deep Link Handling Flow

#### When User Opens Team Link:
1. **Link Format**: `https://wiseworkout.com/team/{token}`
2. **Parse Token**: Extract token from URL path
3. **Authentication Check**:
   - If user is logged in: Process immediately
   - If not logged in: Store token and redirect to login

#### Link Processing:
1. **Validate Link**: Call `getTeamFromLink(token)`
   - Check if link exists and is active
   - Verify expiration date
   - Increment click counter
2. **Get Team Data**: Fetch team information
3. **Navigation**: Navigate to TeamDetailsPage
4. **Join Prompt**: If not already a member, show join dialog

#### Join Process:
1. **User Confirmation**: Show team info and join button
2. **Join Team**: Call `joinTeamThroughLink(token)`
3. **Member Limits**: Check free (4) vs premium (unlimited) limits
4. **Success**: Add user to team and update UI

### 4. Code Components

#### Main App (main.dart)
- Global navigation key for deep linking
- `handleIncomingLink()` method to process external links
- Authentication state listening for pending links
- Team details navigation with proper Team objects

#### Firebase Teams Service
- `generateTeamLink()`: Creates shareable links with tokens
- `getTeamFromLink()`: Validates and retrieves team from token
- `joinTeamThroughLink()`: Handles team joining through invite links
- Token-based security with expiration and tracking

#### Team Details Page
- Updated share functionality with real Firebase links
- Loading states for link generation
- Social media sharing options with pre-formatted messages
- Copy to clipboard functionality

### 5. User Experience Flow

#### Sharing a Team:
1. User opens team details
2. Clicks "Share" button
3. Chooses "Copy to Clipboard" or "Share To"
4. Link is generated and ready to share
5. Success feedback with option to view generated link

#### Joining via Link:
1. User receives team invite link
2. Clicks link (opens app or web)
3. If not logged in: Redirected to login first
4. After authentication: Shown team details
5. Join dialog appears with team information
6. User confirms and joins team
7. Success message and team access granted

### 6. Security Features
- **Expiration**: Links expire after 30 days
- **Activity Tracking**: Click counts and last access times
- **Validation**: Multiple checks for link validity
- **Member Limits**: Enforced based on subscription tier
- **Authentication**: Required before processing any link

### 7. Error Handling
- Invalid/expired links show appropriate error messages
- Network errors handled with user feedback
- Loading states for all async operations
- Fallback navigation if link processing fails

## Usage Instructions

### For Team Owners:
1. Open your team details
2. Click the "Share" button
3. Choose sharing method:
   - "Copy to Clipboard": Gets link immediately
   - "Share To": Shows social media options
4. Share the generated link with potential members

### For New Members:
1. Click on a team invite link
2. Log in if prompted
3. Review team information
4. Click "Join Team" to become a member
5. Access team features immediately

## Benefits
- **Seamless Onboarding**: New users can join teams with one click
- **Viral Growth**: Easy sharing increases team participation
- **Security**: Token-based system with proper validation
- **Analytics**: Track link usage and effectiveness
- **User Friendly**: Clear UI and helpful feedback messages
