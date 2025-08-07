# Docker Deployment for Render - Wise Fitness Website

This project uses Docker for deployment on Render, providing a reliable and consistent hosting environment.

## 🚀 Deployment Architecture

- **Base Image**: `nginx:alpine` (lightweight and secure)
- **Web Server**: Nginx with custom configuration
- **Static Files**: All HTML/CSS/JS files served directly
- **Health Checks**: Built-in endpoints for monitoring
- **Security**: Security headers and access controls

## 📁 Project Structure

```
├── Dockerfile              # Docker container definition
├── nginx.conf              # Nginx web server configuration
├── render.yaml             # Render deployment settings
├── .dockerignore           # Files excluded from Docker build
└── FYP Websites/           # Website source files (served by Nginx)
    ├── index.html          # Main landing page
    ├── Login.html          # User authentication
    ├── ManageLandingPage.html # Admin dashboard
    └── ...                 # Other website files
```

## 🔧 Features

### Web Server Configuration
- **Gzip Compression**: Automatic compression for faster loading
- **Security Headers**: XSS protection, content type sniffing prevention
- **Custom Routing**: Clean URLs without .html extensions
- **Static Asset Caching**: 1-year cache for images, CSS, JS
- **Error Handling**: Custom 404 and 50x error pages

### Health Monitoring
- `/health` - HTML health check page
- `/api/health` - JSON health check endpoint

### Security
- Prevents access to sensitive files (`.env`, `.git`, etc.)
- CORS and XSS protection headers
- Content Security Policy

## 🌐 Deployment on Render

### Automatic Deployment
1. Push code to GitHub repository
2. Render automatically builds Docker image
3. Deploys to production URL
4. Health checks ensure service availability

### Manual Deployment
1. Go to [Render Dashboard](https://dashboard.render.com)
2. Create new "Web Service"
3. Connect GitHub repository
4. Select **Docker** environment
5. Deploy automatically uses `render.yaml` configuration

## 🔍 Health Checks

Render monitors these endpoints:
- **Primary**: `/health` (returns HTML page)
- **API**: `/api/health` (returns JSON status)

Both endpoints confirm the service is running and accessible.

## 🛠️ Local Development

### Prerequisites
- Docker installed on your machine
- Git for version control

### Build and Run Locally
```bash
# Build the Docker image
docker build -t wise-fitness-website .

# Run the container
docker run -p 8080:80 wise-fitness-website

# Visit http://localhost:8080 in your browser
```

### Test Health Checks
```bash
# HTML health check
curl http://localhost:8080/health

# JSON health check
curl http://localhost:8080/api/health
```

## 📊 Performance Optimizations

- **Nginx**: High-performance web server
- **Gzip Compression**: Reduces bandwidth usage
- **Static Asset Caching**: Improves repeat visit performance
- **Alpine Linux**: Minimal container size for faster deployments

## 🔐 Security Features

- Security headers prevent common web vulnerabilities
- Access controls block sensitive file requests
- Content Security Policy limits resource loading
- No server-side code execution (static files only)

## 🚨 Troubleshooting

### Common Issues

1. **Build Fails**: Check that `FYP Websites/` directory exists and contains files
2. **Health Check Fails**: Verify nginx configuration and port 80 exposure
3. **Files Not Found**: Ensure file paths are correct in nginx.conf

### Debug Commands
```bash
# Check container logs
docker logs <container-id>

# Execute commands in running container
docker exec -it <container-id> /bin/sh

# Test nginx configuration
docker exec <container-id> nginx -t
```

## 📈 Monitoring

Render provides built-in monitoring:
- **Health Checks**: Automatic endpoint monitoring
- **Logs**: Real-time application logs
- **Metrics**: Performance and resource usage
- **Alerts**: Notification of service issues

## 🔄 Updates and Maintenance

1. **Code Changes**: Push to GitHub triggers automatic rebuild
2. **Configuration Updates**: Modify `nginx.conf` or `render.yaml`
3. **Security Updates**: Base image updates handled by Render
4. **Scaling**: Upgrade Render plan for higher traffic needs

## 📞 Support

For deployment issues:
1. Check Render dashboard logs
2. Verify health check endpoints
3. Review nginx configuration
4. Contact Render support if needed

---

**Last Updated**: August 2025  
**Deployment Type**: Docker + Nginx on Render  
**Environment**: Production-ready static website hosting
