# Weather API Setup Instructions

## Getting Real Weather Data

Your app now supports real weather data from OpenWeatherMap API. Currently, it's using improved simulated data, but you can easily switch to real weather data.

## Step 1: Get Free API Key

1. Go to [OpenWeatherMap API](https://openweathermap.org/api)
2. Sign up for a free account
3. Go to your API keys section
4. Copy your API key (it will look like: `a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6`)

## Step 2: Add API Key to App

1. Open `lib/config/weather_config.dart`
2. Replace `'demo_key_replace_with_your_key'` with your actual API key:

```dart
static const String openWeatherMapApiKey = 'YOUR_ACTUAL_API_KEY_HERE';
```

## Step 3: Rebuild and Deploy

```bash
flutter build web --release -O4
netlify deploy --prod --dir=build/web
```

## API Limits (Free Tier)

- **1,000 API calls per day**
- **Current weather and 5-day forecast**
- **Perfect for personal use**

## What You'll Get

✅ **Real weather data** that matches Google Weather  
✅ **Accurate rainfall measurements**  
✅ **Current temperature and conditions**  
✅ **5-day weather forecast**  
✅ **Location-specific data**  

## Fallback System

- If API fails or exceeds limits, app automatically uses improved simulated data
- Simulated data is now much more realistic based on Pakistan's climate patterns
- App will continue working even without API key

## Current Status

🟡 **Using Improved Simulated Data** (until you add API key)  
🟢 **Will use Real Weather Data** (once API key is added)

The simulated data is now much more accurate and season-aware, but real API data will be even better!
