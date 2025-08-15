# Team Member Limits Implementation

## Overview
This implementation adds subscription-based team member limits to the Wise Workout App. Free users can create teams with up to 4 members, while premium users can create teams with unlimited members.

## Features Implemented

### 1. Subscription-Based Team Limits
- **Free Users**: Maximum 4 members per team
- **Premium Users**: Unlimited team members
- Team member limits are enforced based on the team creator's subscription type

### 2. Team Creation Restrictions
- Team member limit information is displayed during team creation
- Visual indicators show current subscription limits
- Upgrade link for free users to access premium features

### 3. Team Joining Restrictions
- Users cannot join teams that have reached their member limit
- Clear error messages when team capacity is reached
- Detailed feedback explaining why joining failed

### 4. UI Enhancements

#### Create Team Page (`create_team_page.dart`)
- Added subscription info panel showing current limits
- Premium/Free status indicator with visual styling
- Direct upgrade link for free users

#### Discovered Team Details Page (`discovered_team_details_page.dart`)
- Enhanced member count display with limit information
- "Team is full" indicator for teams at capacity
- "Unlimited members (Premium)" indicator for premium teams
- Better error messages for join failures

#### All Teams Page (`all_teams_page.dart`)
- Added member count display on team cards
- Shows current member count for each team

## Technical Implementation

### Service Layer Changes

#### FirebaseTeamsService (`services/firebase_teams_service.dart`)
- Added member limit constants:
  - `FREE_USER_TEAM_MEMBER_LIMIT = 4`
  - `PREMIUM_USER_TEAM_MEMBER_LIMIT = -1` (unlimited)
- New methods:
  - `getTeamMemberLimit()`: Gets current user's team member limit
  - `canTeamAcceptNewMembers(teamId)`: Checks if team can accept new members
  - `getTeamMemberLimitForTeam(teamId)`: Gets limit for specific team
  - `joinTeamWithResult(teamId)`: Enhanced join with detailed error messages
- Enhanced `joinTeam()` method with subscription checking

#### Subscription Integration
- Integrated with existing `FirebaseSubscriptionService`
- Checks user subscription type before allowing team operations
- Fallback to free tier limits on errors

### Database Structure
- No changes to existing database structure required
- Uses existing user subscription data in Firestore
- Team member limits determined dynamically based on creator's subscription

## Usage Examples

### Free User Experience
1. User sees "Free plan: Teams limited to 4 members" during team creation
2. Can create teams with up to 4 members
3. Cannot join teams that already have 4 members
4. Gets clear error message: "This team has reached its member limit of 4 members. The team creator needs to upgrade to Premium for unlimited members."

### Premium User Experience
1. User sees "Premium: Create teams with unlimited members" during team creation
2. Can create teams with unlimited members
3. Their teams display "Unlimited members (Premium)" status
4. No restrictions on team member count

### Team Joining
- Users attempting to join full teams receive informative error messages
- Success messages confirm team joining
- UI updates immediately to reflect membership changes

## Error Handling
- Graceful fallback to free tier limits if subscription check fails
- Clear error messages for all failure scenarios
- Proper async/await error handling throughout

## UI/UX Improvements
- Color-coded subscription status (Green for Premium, Orange for Free)
- Consistent visual language across all team-related pages
- Accessible icons and clear typography
- Responsive design maintains layout on different screen sizes

## Future Enhancements
- Push notifications for team membership changes
- Team activity logs showing member joins/leaves
- Bulk member management for premium teams
- Team member role management (admin, member, etc.)

## Testing Considerations
- Test team creation with both free and premium users
- Verify member limit enforcement during team joining
- Test UI updates when subscription status changes
- Verify error handling for edge cases (network issues, invalid data)

## Files Modified
1. `lib/services/firebase_teams_service.dart` - Core team logic with subscription checks
2. `lib/create_team_page.dart` - Team creation UI with limit display
3. `lib/discovered_team_details_page.dart` - Team details with enhanced member info
4. `lib/all_teams_page.dart` - Team list with member counts
