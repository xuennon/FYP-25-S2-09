# Use the official Nginx image as base
FROM nginx:alpine

# Install envsubst for environment variable substitution
RUN apk add --no-cache gettext

# Set working directory
WORKDIR /usr/share/nginx/html

# Remove default nginx website
RUN rm -rf /usr/share/nginx/html/*

# Copy your static site (all files in FYP Websites)
COPY ["FYP Websites/", "/usr/share/nginx/html/"]

# Copy custom nginx configuration
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Copy startup script
COPY startup.sh /startup.sh
RUN chmod +x /startup.sh

# Expose port 80
EXPOSE 80

# Start with our custom script
CMD ["/startup.sh"]
