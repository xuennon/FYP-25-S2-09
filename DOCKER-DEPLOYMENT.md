# Wise Fitness Landing Page - Docker Deployment

This Docker configuration hosts only the **FYP Websites** folder as a static website on Render.

## 🚀 Deployment on Render

### Automatic Deployment
1. Connect your GitHub repository to Render
2. Select the `render-deployment` branch
3. Render will automatically detect the `render.yaml` file
4. The website will be built and deployed automatically

### Manual Setup
1. **Service Type**: Web Service
2. **Environment**: Docker
3. **Build Command**: (leave empty)
4. **Start Command**: (leave empty)
5. **Dockerfile Path**: `./Dockerfile`
6. **Branch**: `render-deployment`

## 📁 What's Included

- **Static Website**: All files from `FYP Websites/` folder
- **Nginx Server**: Lightweight web server for optimal performance
- **Compression**: Gzip enabled for faster loading
- **Security Headers**: Basic security configurations
- **Caching**: Static assets cached for 1 year

## 🔧 Local Testing

```bash
# Build Docker image
docker build -t fyp-wise-fitness .

# Run locally on port 8080
docker run -p 8080:80 fyp-wise-fitness

# Visit http://localhost:8080
```

## 🌟 Features

- ✅ **Firebase Integration**: Real-time testimonials and content
- ✅ **Responsive Design**: Mobile-friendly layout
- ✅ **Auto-rotating Testimonials**: Unique usernames with smooth transitions
- ✅ **Dynamic Content**: Loads from Firestore database
- ✅ **Modern UI**: Dark theme with smooth animations

## 📋 File Structure

```
├── Dockerfile              # Docker configuration
├── nginx.conf             # Nginx server configuration
├── render.yaml            # Render deployment configuration
├── .dockerignore          # Docker ignore file
└── FYP Websites/          # Static website files
    ├── index.html         # Main landing page
    ├── Login.html         # Login page
    ├── Signup.html        # User signup
    └── ...               # Other website files
```

## 🔗 Live Demo

Once deployed on Render, your website will be available at:
`https://fyp-wise-fitness-landing.onrender.com`

## 🛠️ Troubleshooting

- **Build fails**: Check that all files in `FYP Websites/` are present
- **404 errors**: Nginx is configured to fallback to `index.html`
- **Firebase errors**: Ensure Firebase config is correct in `index.html`
