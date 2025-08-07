# Wise Fitness - Node.js Deployment

## 🚀 Quick Deploy to Render

### Option 1: One-Click Deploy
[![Deploy to Render](https://render.com/images/deploy-to-render-button.svg)](https://render.com/deploy?repo=https://github.com/xuennon/FYP-25-S2-09)

### Option 2: Manual Setup

1. **Fork/Clone Repository**
   ```bash
   git clone https://github.com/xuennon/FYP-25-S2-09.git
   cd FYP-25-S2-09
   ```

2. **Install Dependencies**
   ```bash
   npm install
   ```

3. **Test Locally**
   ```bash
   npm start
   # Visit: http://localhost:3000
   ```

4. **Deploy to Render**
   - Go to [Render Dashboard](https://dashboard.render.com/)
   - Click "New +" → "Web Service"
   - Connect your GitHub repository
   - Configure as shown below

## ⚙️ Render Configuration

### Basic Settings
- **Name**: `wise-fitness-website`
- **Environment**: `Node`
- **Region**: Choose closest to your users
- **Branch**: `main`
- **Root Directory**: `.` (leave empty)

### Build & Deploy Settings
- **Build Command**: `npm install`
- **Start Command**: `npm start`

### Environment Variables
Set these in Render Dashboard → Environment:

| Variable | Value | Required |
|----------|-------|----------|
| `NODE_ENV` | `production` | Yes |
| `OPENAI_API_KEY` | `your-openai-api-key` | Optional* |

*Required only for AI testimonial analysis features

### Advanced Settings
- **Auto-Deploy**: `Yes`
- **Health Check Path**: `/api/health`

## 🏗️ Architecture

```
📦 Wise Fitness Website
├── 🌐 Express.js Server (server.js)
├── 📁 Static Files (FYP Websites/)
│   ├── 🏠 index.html (Landing Page)
│   ├── 👤 Login.html
│   ├── 📝 Signup.html
│   ├── 🏢 BusinessUserSignup.html
│   ├── ⚙️ SystemAdmin.html
│   ├── 📊 ManageLandingPage.html
│   └── 📱 Other pages...
├── 📱 Mobile App Assets (wise_workout_app/)
└── 🔧 Configuration Files
```

## 🛣️ URL Routes

### Public Routes
- `/` → Landing page (`index.html`)
- `/login` → Login page
- `/signup` → User registration
- `/business-signup` → Business registration

### Admin Routes
- `/admin/system` → System administration
- `/admin/landing` → Landing page management
- `/admin/users` → User management
- `/admin/business` → Business management

### API Routes
- `/api/health` → Health check endpoint
- `/api/ai-status` → AI configuration status

## 🔒 Security Features

- **Helmet.js**: Security headers
- **CORS**: Configured for Firebase/OpenAI
- **CSP**: Content Security Policy
- **Compression**: Gzip compression
- **Rate Limiting**: Built-in Express rate limiting

## 📱 Mobile App Integration

The server serves mobile app assets from `/wise_workout_app/*`:
- APK downloads
- App assets and images
- Deep linking support

## 🤖 AI Features

When `OPENAI_API_KEY` is configured:
- ✅ AI testimonial analysis
- ✅ Sentiment detection
- ✅ Spam filtering
- ✅ Content moderation

## 🚀 Performance Optimizations

- **Static File Caching**: Configurable cache headers
- **Compression**: Gzip for all responses
- **CDN Ready**: Works with Render's CDN
- **Health Monitoring**: Built-in health checks

## 📊 Monitoring & Logs

### Health Check
```bash
curl https://your-app.onrender.com/api/health
```

### Response Example
```json
{
  "status": "healthy",
  "timestamp": "2025-01-07T12:00:00.000Z",
  "uptime": 3600,
  "environment": "production"
}
```

## 🔧 Local Development

1. **Setup Environment**
   ```bash
   cp .env.example .env
   # Edit .env with your configurations
   ```

2. **Install Dependencies**
   ```bash
   npm install
   ```

3. **Development Mode**
   ```bash
   npm run dev  # Uses nodemon for auto-restart
   ```

4. **Production Mode**
   ```bash
   npm start
   ```

## 🌍 Environment Variables

### Required
- `NODE_ENV`: Set to `production` for deployment
- `PORT`: Auto-set by Render (default: 3000)

### Optional
- `OPENAI_API_KEY`: For AI features
- `SESSION_SECRET`: For session management

## 📦 Dependencies

### Production
- `express`: Web framework
- `cors`: Cross-origin resource sharing
- `helmet`: Security middleware
- `compression`: Response compression
- `dotenv`: Environment variable loading

### Development
- `nodemon`: Auto-restart during development

## 🚨 Troubleshooting

### Common Issues

1. **Build Fails**
   - Check Node.js version (>=18.0.0)
   - Verify package.json syntax

2. **Static Files Not Loading**
   - Check file paths in "FYP Websites" folder
   - Verify Express static middleware configuration

3. **AI Features Not Working**
   - Ensure `OPENAI_API_KEY` is set in Render environment
   - Check API key validity
   - Monitor usage limits

4. **CORS Errors**
   - Firebase domain must be in CORS allowlist
   - Check browser developer tools for specific errors

### Logs & Debugging

Access logs in Render Dashboard:
- Go to your service
- Click "Logs" tab
- Monitor real-time server output

## 🔄 Updates & Maintenance

### Auto-Deploy
- Push to `main` branch triggers automatic deployment
- Build logs available in Render dashboard

### Manual Deploy
- Use Render dashboard "Manual Deploy" button
- Select specific commit/branch if needed

## 📞 Support

- **Render Docs**: [render.com/docs](https://render.com/docs)
- **Express.js Guide**: [expressjs.com](https://expressjs.com/)
- **Project Issues**: GitHub Issues tab

---

🌟 **Your Wise Fitness website is now ready for production deployment on Render!**
