const express = require('express');
const path = require('path');
const cors = require('cors');
const helmet = require('helmet');
const compression = require('compression');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3000;

// Security middleware
app.use(helmet({
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      styleSrc: ["'self'", "'unsafe-inline'", "https://fonts.googleapis.com"],
      fontSrc: ["'self'", "https://fonts.gstatic.com"],
      scriptSrc: [
        "'self'", 
        "'unsafe-inline'", 
        "https://www.gstatic.com",
        "https://api.openai.com"
      ],
      imgSrc: [
        "'self'", 
        "data:", 
        "https:", 
        "https://images.unsplash.com",
        "https://github.com"
      ],
      connectSrc: [
        "'self'", 
        "https://api.openai.com",
        "https://fyp-25-s2-09-default-rtdb.firebaseio.com",
        "https://firestore.googleapis.com"
      ],
      frameSrc: ["'none'"],
      objectSrc: ["'none'"],
      upgradeInsecureRequests: []
    }
  }
}));

// Enable compression
app.use(compression());

// Enable CORS for Firebase and API calls
app.use(cors({
  origin: [
    'https://fyp-25-s2-09.firebaseapp.com',
    'https://api.openai.com',
    'http://localhost:3000',
    'https://*.onrender.com'
  ],
  credentials: true
}));

// Parse JSON bodies
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Serve static files from "FYP Websites" directory
app.use(express.static(path.join(__dirname, 'FYP Websites'), {
  maxAge: '1d', // Cache static files for 1 day
  etag: true,
  setHeaders: (res, path) => {
    // Set specific cache headers for different file types
    if (path.endsWith('.html')) {
      res.setHeader('Cache-Control', 'public, max-age=300'); // 5 minutes for HTML
    } else if (path.endsWith('.js') || path.endsWith('.css')) {
      res.setHeader('Cache-Control', 'public, max-age=86400'); // 1 day for JS/CSS
    } else if (path.match(/\.(jpg|jpeg|png|gif|ico|svg)$/)) {
      res.setHeader('Cache-Control', 'public, max-age=604800'); // 1 week for images
    }
  }
}));

// Serve wise_workout_app assets
app.use('/wise_workout_app', express.static(path.join(__dirname, 'wise_workout_app'), {
  maxAge: '7d' // Cache app assets for 7 days
}));

// API Routes
app.get('/api/health', (req, res) => {
  res.json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    environment: process.env.NODE_ENV || 'development'
  });
});

// API endpoint for checking OpenAI configuration status
app.get('/api/ai-status', (req, res) => {
  res.json({
    configured: !!process.env.OPENAI_API_KEY,
    endpoint: 'https://api.openai.com/v1/chat/completions',
    note: 'Configure OPENAI_API_KEY environment variable for AI features'
  });
});

// Route for the main landing page
app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, 'FYP Websites', 'index.html'));
});

// Route for management pages (admin routes)
app.get('/admin/*', (req, res) => {
  const filename = req.params[0] || 'SystemAdmin.html';
  const filePath = path.join(__dirname, 'FYP Websites', filename);
  
  // Check if file exists, otherwise send SystemAdmin.html as default
  res.sendFile(filePath, (err) => {
    if (err) {
      res.sendFile(path.join(__dirname, 'FYP Websites', 'SystemAdmin.html'));
    }
  });
});

// Specific routes for key pages
const routes = [
  'Login.html',
  'Signup.html',
  'BusinessUserSignup.html',
  'SystemAdmin.html',
  'ManageLandingPage.html',
  'ManageUsers.html',
  'ManageBusiness.html',
  'PendingApplications.html'
];

routes.forEach(route => {
  app.get(`/${route.replace('.html', '')}`, (req, res) => {
    res.sendFile(path.join(__dirname, 'FYP Websites', route));
  });
});

// Handle 404 errors
app.use('*', (req, res) => {
  // For API routes, return JSON
  if (req.originalUrl.startsWith('/api/')) {
    return res.status(404).json({
      error: 'API endpoint not found',
      path: req.originalUrl,
      timestamp: new Date().toISOString()
    });
  }
  
  // For web routes, redirect to home page
  res.redirect('/');
});

// Global error handler
app.use((err, req, res, next) => {
  console.error('Error:', err);
  
  if (req.originalUrl.startsWith('/api/')) {
    res.status(500).json({
      error: 'Internal server error',
      message: process.env.NODE_ENV === 'development' ? err.message : 'Something went wrong'
    });
  } else {
    res.status(500).send(`
      <!DOCTYPE html>
      <html>
      <head>
        <title>Error - Wise Fitness</title>
        <style>
          body { font-family: Arial, sans-serif; text-align: center; padding: 50px; }
          .error { color: #dc3545; }
          .back-link { color: #007bff; text-decoration: none; }
        </style>
      </head>
      <body>
        <h1 class="error">Something went wrong</h1>
        <p>We're sorry, but something went wrong on our end.</p>
        <a href="/" class="back-link">← Back to Home</a>
      </body>
      </html>
    `);
  }
});

// Start server
app.listen(PORT, '0.0.0.0', () => {
  console.log(`🚀 Wise Fitness server running on port ${PORT}`);
  console.log(`📱 Local: http://localhost:${PORT}`);
  console.log(`🌐 Environment: ${process.env.NODE_ENV || 'development'}`);
  console.log(`🤖 AI Features: ${process.env.OPENAI_API_KEY ? '✅ Configured' : '❌ Not configured'}`);
});

// Graceful shutdown
process.on('SIGTERM', () => {
  console.log('📴 SIGTERM received, shutting down gracefully');
  process.exit(0);
});

process.on('SIGINT', () => {
  console.log('📴 SIGINT received, shutting down gracefully');
  process.exit(0);
});
