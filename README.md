# 💪 FitServe Web Application

A modular, Firebase-powered web app allowing **business users to create and publish fitness plans** as services. These plans can be subscribed to by end users through a mobile Flutter app.

---

## 📁 Folder Structure

/project-root
├── views/ # HTML pages (landing, business, admin)
├── css/
│ ├── style.css # Global styling
│ ├── business.css # Business-only UI
│ └── admin.css
├── js/
│ ├── firebase.js # Firebase init (from .env)
│ ├── script.js # Shared JS logic
│ ├── controllers/
│ │ ├── businessController.js
│ │ └── adminController.js
│ ├── models/
│ │ └── db.js # Firestore logic
│ └── utils/
│ ├── helpers.js
│ └── errorHandler.js
├── assets/
│ └── images/, gifs/, icons/
├── .env # Firebase credentials (excluded)
├── README.md

yaml
Copy
Edit

---

## 🧠 Business Features

### 👤 Business User – Create Fitness Plan as a Service

- Step-by-step plan builder
- Plan includes:
  - Title, summary
  - Visual media (image/video/gif)
  - Workout steps with reps/sets or time
  - Toggle stopwatch/timer use
  - Tags (e.g. HIIT, Yoga, Strength)
  - Save as draft or publish

---

## 🔐 Firebase Firestore Schema

Each fitness plan is stored in the Firestore `fitness_plans` collection:

/fitness_plans (Collection)
└── planId (Document)
├── creatorId: string
├── title: string
├── summary: string
├── tags: [ 'HIIT', 'Beginner', 'Yoga' ]
├── media: [
{ type: 'image', url: '...' },
{ type: 'video', url: '...' }
]
├── steps: [
{ step: 1, type: 'reps', value: 12, description: 'Push-ups' },
{ step: 2, type: 'timer', value: 30, description: 'Plank' }
]
├── createdAt: timestamp
├── published: true

yaml
Copy
Edit

---

## ⚙️ Firebase Coding Guidelines

- All Firestore logic in `models/db.js`
- Use `async/await`
- Wrap all DB calls in `try/catch`
- Log and manage errors via `utils/errorHandler.js`

---

## 📲 Flutter App Integration

- Structure is compatible with Flutter/Dart Firebase packages
- Users can:
  - Discover and subscribe to published plans
  - Query by category/tag/creator
  - Consume workout plans with real-time data

---

## 🚀 Setup Instructions

```bash
npm install -g live-server
live-server
Set up Firebase project & copy your config into .env.

📌 Roadmap
✅ Business user content creation

✅ Firebase Firestore backend

✅ Modular MVC refactor

🔜 Firebase Storage support (uploads)

🔜 Admin analytics panel

🔜 Premium tier integrations (payments, subscriptions)

📜 License
MIT – use freely for personal or commercial fitness platforms.

yaml
Copy
Edit

---

You can now:
- Paste the **first** into **Copilot** to refactor your app.
- Paste the **second** into your GitHub `README.md`.

Let me know if you'd like `.env.example`, sample Firestore security rules, or business plan form UI scaffolding!








Ask ChatGPT



Tools



ChatGPT can make mistakes. Check important info.
