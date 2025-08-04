# Use nginx alpine for lightweight static file serving
FROM nginx:alpine

# Copy the FYP Websites folder to nginx html directory
COPY "FYP Websites/" /usr/share/nginx/html/

# Copy custom nginx configuration
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Expose port 80
EXPOSE 80

# Start nginx
CMD ["nginx", "-g", "daemon off;"]
