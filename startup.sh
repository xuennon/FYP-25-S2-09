#!/bin/sh

# Simple startup script for static website hosting
echo "Starting Nginx for static website..."

# Start nginx
exec nginx -g "daemon off;"
