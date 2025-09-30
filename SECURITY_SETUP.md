# 🔐 Security Setup Guide

## ⚠️ IMPORTANT: API Key Security

Your OpenWeatherMap API key was previously exposed in the GitHub repository. This has been fixed, but you need to take additional security measures.

## 🚨 Immediate Actions Required:

### 1. **Regenerate Your OpenWeatherMap API Key**
- Go to: https://openweathermap.org/api
- Log into your account
- **REGENERATE/REVOKE** the old API key: `2b92acfdb08bac9746248ed2051558a1`
- Create a new API key

### 2. **Add Your New API Key Securely**
- Open: `lib/config/api_keys.dart`
- Replace `YOUR_API_KEY_HERE` with your new API key
- **DO NOT COMMIT THIS FILE TO GITHUB**

### 3. **Verify .gitignore Protection**
The following files are now protected from being committed:
- `lib/config/api_keys.dart`
- `.env*` files
- `*.key` files
- `secrets/` directory

## 🔧 How to Use the Secure Setup:

### For Local Development:
1. Copy `lib/config/api_keys.dart.example` to `lib/config/api_keys.dart`
2. Add your API key to the new file
3. The file is automatically ignored by git

### For Production Deployment:
1. Use environment variables
2. Set `OPENWEATHER_API_KEY` in your deployment platform
3. Never hardcode API keys in production

## 🛡️ Security Best Practices:

### ✅ DO:
- Use environment variables for production
- Store API keys in separate files
- Add sensitive files to .gitignore
- Regularly rotate API keys
- Use different keys for development/production

### ❌ DON'T:
- Commit API keys to version control
- Share API keys in chat/email
- Use the same key across multiple projects
- Store keys in plain text files

## 🔍 Verification Steps:

1. Check that `lib/config/api_keys.dart` is in .gitignore
2. Verify your API key is not visible in GitHub
3. Test the app locally with your new API key
4. Deploy to production using environment variables

## 📞 If You Need Help:

If you're unsure about any of these steps, please ask for assistance before proceeding with deployment.

---
**Remember: Security is everyone's responsibility!**
