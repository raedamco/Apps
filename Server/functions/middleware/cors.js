import cors from 'cors';
import { logger } from '../utils/logger.js';

// CORS configuration for different environments
const corsOptions = {
  origin: (origin, callback) => {
    // Allow requests with no origin (like mobile apps or curl requests)
    if (!origin) return callback(null, true);
    
    const allowedOrigins = [
      // Production domains
      'https://yourdomain.com',
      'https://www.yourdomain.com',
      'https://app.yourdomain.com',
      
      // Development domains
      'http://localhost:3000',
      'http://localhost:3001',
      'http://localhost:8080',
      'http://127.0.0.1:3000',
      'http://127.0.0.1:3001',
      
      // Firebase hosting domains
      'https://your-project.web.app',
      'https://your-project.firebaseapp.com'
    ];
    
    if (allowedOrigins.includes(origin)) {
      callback(null, true);
    } else {
      logger.warn('CORS blocked request from unauthorized origin', { origin });
      callback(new Error('Not allowed by CORS'));
    }
  },
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
  allowedHeaders: [
    'Origin',
    'X-Requested-With',
    'Content-Type',
    'Accept',
    'Authorization',
    'X-API-Key',
    'X-Request-ID',
    'Cache-Control',
    'Pragma'
  ],
  exposedHeaders: [
    'X-Request-ID',
    'X-Response-Time',
    'X-RateLimit-Limit',
    'X-RateLimit-Remaining',
    'X-RateLimit-Reset'
  ],
  credentials: true,
  maxAge: 86400, // 24 hours
  preflightContinue: false,
  optionsSuccessStatus: 204
};

// Create CORS middleware
export const corsMiddleware = cors(corsOptions);

// Security headers middleware
export const securityHeaders = (req, res, next) => {
  // Basic security headers
  res.set({
    'X-Content-Type-Options': 'nosniff',
    'X-Frame-Options': 'DENY',
    'X-XSS-Protection': '1; mode=block',
    'Referrer-Policy': 'strict-origin-when-cross-origin',
    'Permissions-Policy': 'geolocation=(), microphone=(), camera=()',
    'Strict-Transport-Security': 'max-age=31536000; includeSubDomains; preload'
  });
  
  // Content Security Policy
  res.set('Content-Security-Policy', [
    "default-src 'self'",
    "script-src 'self' 'unsafe-inline' 'unsafe-eval' https://js.stripe.com",
    "style-src 'self' 'unsafe-inline' https://fonts.googleapis.com",
    "font-src 'self' https://fonts.gstatic.com",
    "img-src 'self' data: https:",
    "connect-src 'self' https://api.stripe.com https://firestore.googleapis.com",
    "frame-src 'self' https://js.stripe.com",
    "object-src 'none'",
    "base-uri 'self'",
    "form-action 'self'"
  ].join('; '));
  
  next();
};

// Request origin validation
export const validateOrigin = (req, res, next) => {
  const origin = req.get('Origin');
  
  if (origin) {
    // Log origin for monitoring
    logger.debug('Request origin', { 
      origin, 
      path: req.path, 
      method: req.method 
    });
  }
  
  next();
};

// Combined CORS and security middleware
export const enhancedCors = (req, res, next) => {
  // Apply CORS
  corsMiddleware(req, res, (err) => {
    if (err) {
      logger.warn('CORS error', { 
        error: err.message, 
        origin: req.get('Origin'),
        path: req.path 
      });
      return res.status(403).json({
        success: false,
        error: 'CORS policy violation',
        code: 'CORS_ERROR'
      });
    }
    
    // Apply security headers
    securityHeaders(req, res, next);
  });
};

export default enhancedCors;
