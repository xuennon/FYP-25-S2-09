# 🤖 AI Analysis Setup Guide

## Getting Started with AI-Powered Testimonial Analysis

The ManageLandingPage.html includes advanced AI analysis features powered by OpenAI's GPT models. Here's how to set it up:

### 📋 Prerequisites

1. **OpenAI Account**: Sign up at [OpenAI](https://platform.openai.com/)
2. **API Key**: Generate an API key from [API Keys page](https://platform.openai.com/api-keys)
3. **Credits**: Ensure you have API credits in your OpenAI account

### 🔧 Configuration Steps

#### Method 1: Using the UI (Recommended)
1. Open `ManageLandingPage.html`
2. Navigate to **Testimonials Management** section
3. Click **🤖 View & Manage Testimonials**
4. Click **🔑 API Key** button
5. Enter your OpenAI API key when prompted
6. Click **🧪 Test API** to verify the connection

#### Method 2: Manual Configuration
1. Open your browser's Developer Tools (F12)
2. Go to Console tab
3. Run: `localStorage.setItem('openai_api_key', 'your-api-key-here')`
4. Replace `'your-api-key-here'` with your actual API key
5. Refresh the page

### ✨ Features

Once configured, the AI analysis provides:

- **Sentiment Analysis**: Positive, negative, neutral classification
- **Spam Detection**: Identifies spam and inappropriate content
- **Content Moderation**: Flags inappropriate language
- **Rating Correlation**: Detects mismatched ratings vs text sentiment
- **Confidence Scoring**: AI confidence levels for each analysis

### 🎯 Usage

1. **Analyze All**: Bulk analyze all unanalyzed testimonials
2. **Individual Analysis**: Analyze specific testimonials
3. **Filter Results**: Filter by sentiment, membership type, rating
4. **Export Data**: Use the testimonials for landing page display

### 🔒 Security Notes

- API keys are stored locally in your browser
- Never commit API keys to version control
- GitHub push protection will block commits with exposed keys
- Use environment variables in production

### 📊 Pricing

OpenAI API pricing is usage-based:
- GPT-3.5-turbo: ~$0.002 per 1K tokens
- Typical testimonial analysis: ~100-200 tokens
- Cost per analysis: ~$0.0002-0.0004

### 🛠️ Troubleshooting

**API Key Issues:**
- Ensure your key starts with `sk-`
- Check your OpenAI account has sufficient credits
- Verify the key hasn't expired

**Rate Limiting:**
- Free tier: 3 requests per minute
- Paid tier: Higher limits based on usage tier
- The system processes in batches to respect limits

**CORS Errors:**
- Use HTTPS when possible
- Some browsers may block HTTP requests to HTTPS APIs

### 📝 Example Output

```json
{
  "sentiment": "positive",
  "confidence": 0.95,
  "flags": []
}
```

### 🚀 Advanced Features

- **Batch Processing**: Handles multiple testimonials efficiently
- **Fallback Analysis**: Uses rule-based analysis if API fails
- **Data Persistence**: Stores results in Firestore for future use
- **Real-time Updates**: Updates landing page testimonials automatically

---

For support or questions, refer to the [OpenAI API documentation](https://platform.openai.com/docs).
