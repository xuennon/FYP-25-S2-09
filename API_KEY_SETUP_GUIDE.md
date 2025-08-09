# OpenAI API Key Setup Guide

## For Local Development & Testing

### Step 1: Get Your API Key
1. Go to https://platform.openai.com/api-keys
2. Create a new API key
3. Copy the key (starts with `sk-...`)

### Step 2: Local Testing
1. Open `FYP Websites/ManageLandingPage.html`
2. Find line with: `const OPENAI_API_KEY = 'PLACEHOLDER_OPENAI_API_KEY';`
3. Replace with: `const OPENAI_API_KEY = 'sk-your-actual-key-here';`
4. Test locally (open file in browser)
5. **IMPORTANT**: Do NOT commit this change to Git

### Step 3: Production Deployment
For production on Render, use environment variables:

1. Go to Render Dashboard
2. Select your service
3. Go to Environment tab
4. Add variable:
   - Key: `OPENAI_API_KEY`
   - Value: `sk-your-actual-key-here`

### Step 4: Code for Production (Optional)
To read from environment variables, modify the JavaScript:
```javascript
const OPENAI_API_KEY = process.env.OPENAI_API_KEY || 'PLACEHOLDER_OPENAI_API_KEY';
```

## Security Best Practices

✅ **DO:**
- Use environment variables for production
- Test with real keys locally
- Keep the placeholder in your Git repository
- Rotate keys periodically

❌ **DON'T:**
- Commit real API keys to Git
- Share keys in chat/email
- Use the same key for multiple projects
- Leave keys in production code

## Current Code Status
- Repository: Contains safe placeholder
- Local testing: Replace placeholder temporarily
- Production: Use Render environment variables
