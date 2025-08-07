#!/bin/sh

# Replace environment variables in HTML files
echo "Substituting environment variables..."

# Substitute OPENAI_API_KEY in ManageLandingPage.html
if [ -n "$OPENAI_API_KEY" ]; then
    echo "Setting OpenAI API Key..."
    sed -i "s/PLACEHOLDER_OPENAI_API_KEY/$OPENAI_API_KEY/g" /usr/share/nginx/html/ManageLandingPage.html
else
    echo "Warning: OPENAI_API_KEY environment variable not set"
    sed -i "s/PLACEHOLDER_OPENAI_API_KEY/your-openai-api-key-here/g" /usr/share/nginx/html/ManageLandingPage.html
fi

echo "Environment variable substitution complete"

# Start nginx
exec nginx -g "daemon off;"
