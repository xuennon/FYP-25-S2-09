# RunPulse Docker Deployment Guide

This guide explains how to build and deploy the RunPulse application using Docker and Render.

## Project Structure

```
├── website                 # Main RunPulse landing page (HTML)
├── FYP Websites/          # Admin portal and business management pages
├── wise_workout_app/      # Flutter mobile app (not deployed via Docker)
├── Dockerfile             # Docker configuration
├── nginx.conf             # Nginx web server configuration
├── render.yaml            # Render deployment configuration
└── .dockerignore          # Files to exclude from Docker build
```

## Architecture

- **Main Website**: Served at `/` (RunPulse landing page)
- **Admin Portal**: Served at `/admin/` (Business management interface)
- **Web Server**: Nginx (lightweight, production-ready)
- **Health Check**: Available at `/health`

## Local Development

### Build the Docker image:
```bash
docker build -t runpulse-app .
```

### Run locally:
```bash
docker run -p 8080:80 runpulse-app
```

### Access the application:
- Main site: http://localhost:8080
- Admin portal: http://localhost:8080/admin/
- Health check: http://localhost:8080/health

## Render Deployment

### Automatic Deployment:
1. Push changes to the `deploy-for-testing` branch
2. Render will automatically build and deploy
3. Monitor deployment in Render dashboard

### Manual Deployment:
1. Connect your GitHub repository to Render
2. Create a new Web Service
3. Select "Deploy from Git"
4. Choose the `deploy-for-testing` branch
5. Render will use the `render.yaml` configuration

## Configuration Details

### Docker Features:
- Multi-stage build optimized for production
- Nginx Alpine base (lightweight)
- Health checks included
- Proper file permissions
- Security headers configured

### Nginx Features:
- Gzip compression enabled
- Static asset caching (1 year)
- Security headers
- Custom error pages
- Separate routing for main site and admin

### Render Features:
- Free tier compatible
- Auto-deploy from Git
- Health check monitoring
- Environment variable support
- Custom domain ready

## Monitoring

### Health Check:
The application includes a health check endpoint at `/health` that returns a 200 status when the service is running properly.

### Logs:
- Access logs: `/var/log/nginx/access.log`
- Error logs: `/var/log/nginx/error.log`

## Environment Variables

The following environment variables are configured in `render.yaml`:
- `NODE_ENV=production`
- `PORT=80`

## Security

Security headers are automatically added:
- X-Frame-Options
- X-XSS-Protection
- X-Content-Type-Options
- Referrer-Policy
- Content-Security-Policy

## Troubleshooting

### Build Issues:
- Check that all required files are present
- Verify `.dockerignore` isn't excluding necessary files
- Ensure file permissions are correct

### Runtime Issues:
- Check health endpoint: `/health`
- Review Render deployment logs
- Verify nginx configuration syntax

### Performance:
- Static assets are cached for 1 year
- Gzip compression is enabled
- Consider using Render's CDN for better global performance

## Next Steps

1. Test the deployment on the `deploy-for-testing` branch
2. Configure custom domain in Render dashboard
3. Set up monitoring and alerts
4. Consider upgrading to a paid Render plan for production use
