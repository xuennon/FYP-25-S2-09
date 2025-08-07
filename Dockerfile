# Use the official Nginx image as base
FROM nginx:alpine

# Set working directory
WORKDIR /usr/share/nginx/html

# Remove default nginx website
RUN rm -rf /usr/share/nginx/html/*

# Copy the index.html file from FYP Websites directory
COPY ["FYP Websites/index.html", "/usr/share/nginx/html/index.html"]

# Copy the hero image from FYP Websites assets directory
COPY ["FYP Websites/assets/adib-the-builder.jpg", "/usr/share/nginx/html/assets/adib-the-builder.jpg"]

# Copy custom nginx configuration
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Create assets directory and health check endpoint
RUN mkdir -p /usr/share/nginx/html/assets && \
    echo '<!DOCTYPE html><html><head><title>Health Check</title></head><body><h1>OK</h1><p>Service is running</p></body></html>' > /usr/share/nginx/html/health.html

# Expose port 80
EXPOSE 80

# Start nginx
CMD ["nginx", "-g", "daemon off;"]
