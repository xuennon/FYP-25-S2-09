// Sample Event Document Structure for Firebase Firestore
// Business users will create events in the 'events' collection with this structure:

/*
Collection: events
Document ID: auto-generated

Sample Event Document:
{
  "name": "Monthly 5K Fun Run",
  "description": "Join us for our monthly community 5K run! All fitness levels welcome. Free registration and refreshments provided.",
  "businessId": "business_user_uid_123",
  "businessName": "Downtown Fitness Center",
  "sportType": "Run",
  "startDate": Timestamp(2025-08-01 07:00:00),
  "endDate": Timestamp(2025-08-01 09:00:00),
  "participants": [],
  "maxParticipants": 50,
  "createdAt": Timestamp(2025-07-29 10:30:00)
}

Sport Type Options:
- "All" (general events)
- "Run" 
- "Ride" (cycling)
- "Swim"
- "Walk"
- "Hike"

Business Integration:
1. Business users create events through the business landing page
2. Events are stored in Firestore 'events' collection
3. Mobile app automatically syncs and displays events
4. Users can join/leave events
5. Default event icons are displayed based on sportType

Event Lifecycle:
1. Business creates event → Document created in Firestore
2. Mobile app loads events → FirebaseEventsService.loadEvents()
3. User joins event → participants array updated
4. User leaves event → participants array updated
5. Business can edit/delete their events

Firebase Security:
- All authenticated users can read events
- Only business users can create events
- Business users can only edit/delete their own events  
- All users can join/leave events (update participants)
*/
