# Parking App Server - Modern Backend

A modern, scalable backend server for the Parking App built with Firebase Functions, featuring the latest Node.js practices, comprehensive security, and robust error handling.

## 🚀 Features

- **Modern Node.js 20** with ES modules
- **Firebase Functions v4** with optimized performance
- **Comprehensive security** with CORS, rate limiting, and security headers
- **Advanced error handling** with custom error classes
- **Performance monitoring** with request tracking and metrics
- **Modern testing** with Jest and comprehensive mocking
- **Code quality** with ESLint 9 flat config and Prettier
- **Type safety** with Joi validation schemas
- **Logging** with Winston and structured logging
- **Caching** with Redis and in-memory strategies

## 📋 Requirements

- Node.js 20+ (LTS)
- Firebase CLI 13+
- Firebase project with Functions enabled

## 🛠️ Installation

```bash
# Clone the repository
git clone <your-repo-url>
cd parking-app-server

# Install dependencies
npm run install:all

# Set up environment variables
cp functions/.env.example functions/.env
# Edit functions/.env with your configuration

# Run locally
npm run dev
```

## 🔧 Configuration

### Environment Variables

Create a `.env` file in the `functions/` directory:

```env
# Firebase Configuration
FIREBASE_PROJECT_ID=your-project-id
FIREBASE_STORAGE_BUCKET=your-project.appspot.com
FIREBASE_DATABASE_URL=https://your-project.firebaseio.com

# Stripe Configuration
STRIPE_SECRET_KEY=sk_test_your_stripe_key
STRIPE_WEBHOOK_SECRET=whsec_your_webhook_secret

# Redis Configuration (optional)
REDIS_URL=redis://localhost:6379

# Twilio Configuration (optional)
TWILIO_ACCOUNT_SID=your_twilio_sid
TWILIO_AUTH_TOKEN=your_twilio_token

# Email Configuration (optional)
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=your_email@gmail.com
SMTP_PASS=your_app_password

# App Configuration
NODE_ENV=development
LOG_LEVEL=info
API_VERSION=v3
```

### Firebase Configuration

Update `firebase.json` with your project settings:

```json
{
  "functions": {
    "source": "functions",
    "runtime": "nodejs20",
    "codebase": "default"
  }
}
```

## 🏗️ Architecture

### Project Structure

```
functions/
├── __tests__/           # Test files
├── middleware/          # Express middleware
├── services/           # Business logic services
├── validation/         # Joi validation schemas
├── utils/              # Utility functions
├── index.js            # Main entry point
├── package.json        # Dependencies
└── eslint.config.js    # ESLint configuration
```

### Key Components

#### 1. **Middleware Layer**
- **CORS & Security**: Enhanced CORS with security headers
- **Rate Limiting**: Multiple rate limiters for different endpoints
- **Error Handling**: Comprehensive error handling with custom error classes
- **Performance Monitoring**: Request tracking and performance metrics
- **Request Logging**: Structured logging for all requests

#### 2. **Service Layer**
- **UserService**: User management and authentication
- **ParkingService**: Parking session management
- **PaymentService**: Stripe payment integration
- **NotificationService**: Push notifications and email

#### 3. **Validation Layer**
- **Joi Schemas**: Comprehensive validation for all endpoints
- **Request Validation**: Automatic request validation middleware
- **Error Details**: Detailed validation error responses

#### 4. **Security Features**
- **CORS Protection**: Configurable origin validation
- **Rate Limiting**: Tiered rate limiting (free, basic, premium, enterprise)
- **Security Headers**: CSP, HSTS, XSS protection
- **Input Validation**: Comprehensive input sanitization
- **Authentication**: Firebase Auth integration

## 🚀 API Endpoints

### Health & Configuration
- `GET /health` - Health check with system status
- `GET /config` - App configuration and feature flags

### User Management
- `GET /user/profile` - Get user profile
- `PUT /user/profile` - Update user profile
- `DELETE /user/profile` - Delete user account

### Parking Management
- `POST /parking/start` - Start parking session
- `POST /parking/end` - End parking session
- `GET /parking/session/:id` - Get session details
- `GET /parking/history` - Get parking history

### Payment Processing
- `POST /payment/intent` - Create payment intent
- `POST /payment/confirm` - Confirm payment
- `GET /payment/methods` - Get payment methods
- `POST /payment/methods` - Add payment method

## 🧪 Testing

### Running Tests

```bash
# Run all tests
npm test

# Run tests in watch mode
npm run test:watch

# Run tests with coverage
npm run test:coverage

# Run specific test file
npm test -- healthCheck.test.js
```

### Test Structure

- **Unit Tests**: Individual function testing
- **Integration Tests**: API endpoint testing
- **Mock System**: Comprehensive mocking for external services
- **Test Utilities**: Helper functions for common test scenarios

### Test Coverage

- **Target**: 80%+ coverage
- **Reports**: HTML, LCOV, and JSON formats
- **Thresholds**: Configurable coverage requirements

## 🔒 Security

### Security Headers

```javascript
// Automatic security headers
'X-Content-Type-Options': 'nosniff'
'X-Frame-Options': 'DENY'
'X-XSS-Protection': '1; mode=block'
'Referrer-Policy': 'strict-origin-when-cross-origin'
'Strict-Transport-Security': 'max-age=31536000; includeSubDomains; preload'
```

### Content Security Policy

```javascript
// Comprehensive CSP
"default-src 'self'"
"script-src 'self' 'unsafe-inline' 'unsafe-eval' https://js.stripe.com"
"style-src 'self' 'unsafe-inline' https://fonts.googleapis.com"
"connect-src 'self' https://api.stripe.com https://firestore.googleapis.com"
```

### Rate Limiting

- **General**: 100 requests per 15 minutes
- **Authentication**: 5 requests per 15 minutes
- **Payments**: 20 requests per 15 minutes
- **File Uploads**: 10 uploads per hour
- **Dynamic**: Based on user tier

## 📊 Performance

### Monitoring Features

- **Request Tracking**: Unique request IDs
- **Response Time**: Automatic timing measurement
- **Performance Metrics**: Slow request detection
- **Memory Usage**: Resource monitoring
- **Error Tracking**: Comprehensive error logging

### Optimization

- **Lazy Loading**: Services initialized on demand
- **Caching**: Multi-level caching strategy
- **Batch Operations**: Firebase batch writes
- **Parallel Processing**: Concurrent operations where possible
- **Connection Pooling**: Optimized database connections

## 🛠️ Development

### Code Quality

```bash
# Lint code
npm run lint

# Fix linting issues
npm run lint:fix

# Format code with Prettier
npx prettier --write .

# Type checking (if using TypeScript)
npm run type-check
```

### ESLint Configuration

- **Modern Rules**: ES2024+ features
- **Security**: Security-focused linting rules
- **Import Order**: Organized import statements
- **Promise Handling**: Best practices for async code
- **Code Style**: Consistent formatting rules

### Prettier Configuration

- **Formatting**: Automatic code formatting
- **Line Length**: 120 character limit
- **Quotes**: Single quotes preferred
- **Semicolons**: Always required
- **Trailing Commas**: None

## 🚀 Deployment

### Firebase Deployment

```bash
# Deploy to development
npm run deploy

# Deploy to production
npm run deploy:prod

# View logs
npm run logs
```

### Environment Management

- **Development**: Local emulators
- **Staging**: Firebase staging project
- **Production**: Firebase production project
- **Environment Variables**: Secure configuration management

## 📈 Monitoring & Logging

### Logging Strategy

- **Structured Logging**: JSON format for easy parsing
- **Log Levels**: Error, Warn, Info, Debug
- **Context**: Request details, user info, performance metrics
- **Storage**: File-based with rotation
- **Monitoring**: Integration with external monitoring tools

### Performance Metrics

- **Response Times**: Per-endpoint timing
- **Error Rates**: Error frequency tracking
- **Throughput**: Requests per second
- **Resource Usage**: Memory and CPU monitoring
- **Custom Metrics**: Business-specific measurements

## 🔧 Maintenance

### Dependency Management

```bash
# Update all dependencies
npm run update:deps

# Security audit
npm run security-audit

# Clean installation
npm run clean
npm run install:all
```

### Health Checks

- **Database Connectivity**: Firebase connection status
- **External Services**: Stripe, Redis, etc.
- **System Resources**: Memory, CPU usage
- **Response Times**: Performance monitoring
- **Error Rates**: System health indicators

## 🤝 Contributing

### Development Workflow

1. **Fork** the repository
2. **Create** a feature branch
3. **Make** your changes
4. **Test** thoroughly
5. **Submit** a pull request

### Code Standards

- **ESLint**: Follow linting rules
- **Prettier**: Use automatic formatting
- **Tests**: Maintain test coverage
- **Documentation**: Update docs as needed
- **Security**: Follow security best practices

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

### Getting Help

- **Documentation**: Check this README first
- **Issues**: Create GitHub issues for bugs
- **Discussions**: Use GitHub discussions for questions
- **Security**: Report security issues privately

### Common Issues

- **CORS Errors**: Check origin configuration
- **Rate Limiting**: Verify rate limit settings
- **Authentication**: Ensure Firebase Auth is configured
- **Performance**: Monitor response times and resource usage

---

**Built with ❤️ using modern Node.js and Firebase technologies**
