import { onRequest } from 'firebase-functions/v2/https';
import { onDocumentCreated } from 'firebase-functions/v2/firestore';
import { setGlobalOptions } from 'firebase-functions/v2';
import { initializeApp, getApps } from 'firebase-admin/app';

// Set global options for all functions with optimized settings
setGlobalOptions({
  maxInstances: 20,
  timeoutSeconds: 30,
  memory: '512MiB',
  region: 'us-central1',
  concurrency: 80,
  retryCount: 3,
  minInstances: 1
});

// Initialize Firebase Admin with optimized settings
if (getApps().length === 0) {
  initializeApp({
    projectId: process.env.FIREBASE_PROJECT_ID,
    storageBucket: process.env.FIREBASE_STORAGE_BUCKET,
    databaseURL: process.env.FIREBASE_DATABASE_URL
  });
}

// Import service modules
import { 
  UserService, 
  ParkingService, 
  PaymentService, 
  NotificationService 
} from './services/index.js';

// Import middleware
import { 
  validateRequest, 
  rateLimiter, 
  corsMiddleware, 
  requestLogger,
  errorHandler,
  performanceMonitor
} from './middleware/index.js';

// Import validation schemas
import { 
  parkingSchemas, 
  paymentSchemas 
} from './validation/index.js';

// Import utilities
import { logger } from './utils/logger.js';

// ============================================================================
// HTTP FUNCTIONS
// ============================================================================

// Health check endpoint
export const healthCheck = onRequest({
  cors: true,
  maxInstances: 10,
  memory: '256MiB',
  timeoutSeconds: 10
}, async (req, res) => {
  try {
    // Apply middleware
    await corsMiddleware(req, res);
    await requestLogger(req, res);
    
    const startTime = Date.now();
    
    // Basic health checks
    const checks = {
      firebase: true,
      database: true,
      timestamp: new Date().toISOString()
    };
    
    // Check Firebase connection
    try {
      const { getFirestore } = await import('firebase-admin/firestore');
      const db = getFirestore();
      await db.collection('_health').doc('check').get();
    } catch (error) {
      checks.firebase = false;
      checks.database = false;
    }
    
    const responseTime = Date.now() - startTime;
    
    res.json({
      success: true,
      message: 'Parking App Server is running',
      version: '3.0.0',
      checks,
      responseTime: `${responseTime}ms`,
      timestamp: checks.timestamp
    });
  } catch (error) {
    logger.error('Health check error', { error: error.message, stack: error.stack });
    res.status(500).json({
      success: false,
      message: 'Internal server error',
      error: process.env.NODE_ENV === 'development' ? error.message : 'Something went wrong'
    });
  }
});

// Start a new parking session
export const startParkingSession = onRequest({
  cors: true,
  maxInstances: 50,
  memory: '512MiB',
  timeoutSeconds: 30,
  concurrency: 100
}, async (req, res) => {
  try {
    // Apply middleware
    await corsMiddleware(req, res);
    await rateLimiter.apply(req, res);
    await requestLogger(req, res);
    await performanceMonitor.start(req, res);

    // Validate request
    const { error, value } = validateRequest(req.body, parkingSchemas.startSession);
    if (error) {
      return res.status(400).json({
        success: false,
        error: 'Validation failed',
        details: error.details,
        code: 'VALIDATION_ERROR'
      });
    }

    const session = await ParkingService.startSession(value);
    
    await performanceMonitor.end(req, res);
    
    res.json({
      success: true,
      data: session,
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    await performanceMonitor.end(req, res);
    logger.error('Error starting parking session', { 
      error: error.message, 
      stack: error.stack,
      body: req.body 
    });
    
    const statusCode = error.statusCode || 500;
    const message = error.statusCode ? error.message : 'Failed to start parking session';
    
    res.status(statusCode).json({
      success: false,
      error: message,
      code: error.code || 'INTERNAL_ERROR',
      ...(process.env.NODE_ENV === 'development' && { stack: error.stack })
    });
  }
});

// End a parking session
export const endParkingSession = onRequest({
  cors: true,
  maxInstances: 50,
  memory: '512MiB',
  timeoutSeconds: 30
}, async (req, res) => {
  try {
    await corsMiddleware(req, res);
    await rateLimiter.apply(req, res);
    await requestLogger(req, res);
    await performanceMonitor.start(req, res);

    const { sessionId, uid } = req.body;
    
    if (!sessionId || !uid) {
      return res.status(400).json({
        success: false,
        error: 'Missing required fields',
        code: 'MISSING_FIELDS',
        required: ['sessionId', 'uid']
      });
    }

    const session = await ParkingService.endSession(sessionId, uid);
    
    await performanceMonitor.end(req, res);
    
    res.json({
      success: true,
      data: session,
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    await performanceMonitor.end(req, res);
    logger.error('Error ending parking session', { 
      error: error.message, 
      stack: error.stack,
      body: req.body 
    });
    
    const statusCode = error.statusCode || 500;
    const message = error.statusCode ? error.message : 'Failed to end parking session';
    
    res.status(statusCode).json({
      success: false,
      error: message,
      code: error.code || 'INTERNAL_ERROR',
      ...(process.env.NODE_ENV === 'development' && { stack: error.stack })
    });
  }
});

// Create payment intent
export const createPaymentIntent = onRequest({
  cors: true,
  maxInstances: 30,
  memory: '512MiB',
  timeoutSeconds: 30
}, async (req, res) => {
  try {
    await corsMiddleware(req, res);
    await rateLimiter.apply(req, res);
    await requestLogger(req, res);
    await performanceMonitor.start(req, res);

    const { error, value } = validateRequest(req.body, paymentSchemas.createPayment);
    if (error) {
      return res.status(400).json({
        success: false,
        error: 'Validation failed',
        details: error.details,
        code: 'VALIDATION_ERROR'
      });
    }

    const paymentIntent = await PaymentService.createPaymentIntent(value);
    
    await performanceMonitor.end(req, res);
    
    res.json({
      success: true,
      data: paymentIntent,
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    await performanceMonitor.end(req, res);
    logger.error('Error creating payment intent', { 
      error: error.message, 
      stack: error.stack,
      body: req.body 
    });
    
    const statusCode = error.statusCode || 500;
    const message = error.statusCode ? error.message : 'Failed to create payment intent';
    
    res.status(statusCode).json({
      success: false,
      error: message,
      code: error.code || 'INTERNAL_ERROR',
      ...(process.env.NODE_ENV === 'development' && { stack: error.stack })
    });
  }
});

// Confirm payment
export const confirmPayment = onRequest({
  cors: true,
  maxInstances: 30,
  memory: '512MiB',
  timeoutSeconds: 30
}, async (req, res) => {
  try {
    await corsMiddleware(req, res);
    await rateLimiter.apply(req, res);
    await requestLogger(req, res);
    await performanceMonitor.start(req, res);

    const { error, value } = validateRequest(req.body, paymentSchemas.confirmPayment);
    if (error) {
      return res.status(400).json({
        success: false,
        error: 'Validation failed',
        details: error.details,
        code: 'VALIDATION_ERROR'
      });
    }

    const result = await PaymentService.confirmPayment(value);
    
    await performanceMonitor.end(req, res);
    
    res.json({
      success: true,
      data: result,
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    await performanceMonitor.end(req, res);
    logger.error('Error confirming payment', { 
      error: error.message, 
      stack: error.stack,
      body: req.body 
    });
    
    const statusCode = error.statusCode || 500;
    const message = error.statusCode ? error.message : 'Failed to confirm payment';
    
    res.status(statusCode).json({
      success: false,
      error: message,
      code: error.code || 'INTERNAL_ERROR',
      ...(process.env.NODE_ENV === 'development' && { stack: error.stack })
    });
  }
});

// Get user profile
export const getUserProfile = onRequest({
  cors: true,
  maxInstances: 20,
  memory: '256MiB',
  timeoutSeconds: 15
}, async (req, res) => {
  try {
    await corsMiddleware(req, res);
    await rateLimiter.apply(req, res);
    await requestLogger(req, res);
    await performanceMonitor.start(req, res);

    const { uid } = req.query;
    
    if (!uid) {
      return res.status(400).json({
        success: false,
        error: 'Missing user ID',
        code: 'MISSING_USER_ID'
      });
    }

    const profile = await UserService.getUserProfile(uid);
    
    if (!profile) {
      return res.status(404).json({
        success: false,
        error: 'User not found',
        code: 'USER_NOT_FOUND'
      });
    }
    
    await performanceMonitor.end(req, res);
    
    res.json({
      success: true,
      data: profile,
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    await performanceMonitor.end(req, res);
    logger.error('Error getting user profile', { 
      error: error.message, 
      stack: error.stack,
      query: req.query 
    });
    
    const statusCode = error.statusCode || 500;
    const message = error.statusCode ? error.message : 'Failed to get user profile';
    
    res.status(statusCode).json({
      success: false,
      error: message,
      code: error.code || 'INTERNAL_ERROR',
      ...(process.env.NODE_ENV === 'development' && { stack: error.stack })
    });
  }
});

// Update user profile
export const updateUserProfile = onRequest({
  cors: true,
  maxInstances: 20,
  memory: '256MiB',
  timeoutSeconds: 15
}, async (req, res) => {
  try {
    await corsMiddleware(req, res);
    await rateLimiter.apply(req, res);
    await requestLogger(req, res);
    await performanceMonitor.start(req, res);

    const { uid } = req.params;
    const updates = req.body;
    
    if (!uid) {
      return res.status(400).json({
        success: false,
        error: 'Missing user ID',
        code: 'MISSING_USER_ID'
      });
    }

    const result = await UserService.updateUserProfile(uid, updates);
    
    await performanceMonitor.end(req, res);
    
    res.json({
      success: true,
      data: result,
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    await performanceMonitor.end(req, res);
    logger.error('Error updating user profile', { 
      error: error.message, 
      stack: error.stack,
      params: req.params,
      body: req.body 
    });
    
    const statusCode = error.statusCode || 500;
    const message = error.statusCode ? error.message : 'Failed to update user profile';
    
    res.status(statusCode).json({
      success: false,
      error: message,
      code: error.code || 'INTERNAL_ERROR',
      ...(process.env.NODE_ENV === 'development' && { stack: error.stack })
    });
  }
});

// Get parking session
export const getParkingSession = onRequest({
  cors: true,
  maxInstances: 20,
  memory: '256MiB',
  timeoutSeconds: 15
}, async (req, res) => {
  try {
    await corsMiddleware(req, res);
    await rateLimiter.apply(req, res);
    await requestLogger(req, res);
    await performanceMonitor.start(req, res);

    const { sessionId, uid } = req.query;
    
    if (!sessionId || !uid) {
      return res.status(400).json({
        success: false,
        error: 'Missing required fields',
        code: 'MISSING_FIELDS',
        required: ['sessionId', 'uid']
      });
    }

    const session = await ParkingService.getSession(sessionId, uid);
    
    if (!session) {
      return res.status(404).json({
        success: false,
        error: 'Session not found',
        code: 'SESSION_NOT_FOUND'
      });
    }
    
    await performanceMonitor.end(req, res);
    
    res.json({
      success: true,
      data: session,
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    await performanceMonitor.end(req, res);
    logger.error('Error getting parking session', { 
      error: error.message, 
      stack: error.stack,
      query: req.query 
    });
    
    const statusCode = error.statusCode || 500;
    const message = error.statusCode ? error.message : 'Failed to get parking session';
    
    res.status(statusCode).json({
      success: false,
      error: message,
      code: error.code || 'INTERNAL_ERROR',
      ...(process.env.NODE_ENV === 'development' && { stack: error.stack })
    });
  }
});

// Get parking history
export const getParkingHistory = onRequest({
  cors: true,
  maxInstances: 20,
  memory: '256MiB',
  timeoutSeconds: 15
}, async (req, res) => {
  try {
    await corsMiddleware(req, res);
    await rateLimiter.apply(req, res);
    await requestLogger(req, res);
    await performanceMonitor.start(req, res);

    const { uid } = req.query;
    const options = {
      limit: parseInt(req.query.limit) || 20,
      offset: parseInt(req.query.offset) || 0,
      status: req.query.status || null
    };
    
    if (!uid) {
      return res.status(400).json({
        success: false,
        error: 'Missing user ID',
        code: 'MISSING_USER_ID'
      });
    }

    const history = await ParkingService.getUserHistory(uid, options);
    
    await performanceMonitor.end(req, res);
    
    res.json({
      success: true,
      data: history,
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    await performanceMonitor.end(req, res);
    logger.error('Error getting parking history', { 
      error: error.message, 
      stack: error.stack,
      query: req.query 
    });
    
    const statusCode = error.statusCode || 500;
    const message = error.statusCode ? error.message : 'Failed to get parking history';
    
    res.status(statusCode).json({
      success: false,
      error: message,
      code: error.code || 'INTERNAL_ERROR',
      ...(process.env.NODE_ENV === 'development' && { stack: error.stack })
    });
  }
});

// Get payment methods
export const getPaymentMethods = onRequest({
  cors: true,
  maxInstances: 20,
  memory: '256MiB',
  timeoutSeconds: 15
}, async (req, res) => {
  try {
    await corsMiddleware(req, res);
    await rateLimiter.apply(req, res);
    await requestLogger(req, res);
    await performanceMonitor.start(req, res);

    const { uid } = req.query;
    
    if (!uid) {
      return res.status(400).json({
        success: false,
        error: 'Missing user ID',
        code: 'MISSING_USER_ID'
      });
    }

    const methods = await PaymentService.getUserPaymentMethods(uid);
    
    await performanceMonitor.end(req, res);
    
    res.json({
      success: true,
      data: methods,
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    await performanceMonitor.end(req, res);
    logger.error('Error getting payment methods', { 
      error: error.message, 
      stack: error.stack,
      query: req.query 
    });
    
    const statusCode = error.statusCode || 500;
    const message = error.statusCode ? error.message : 'Failed to get payment methods';
    
    res.status(statusCode).json({
      success: false,
      error: message,
      code: error.code || 'INTERNAL_ERROR',
      ...(process.env.NODE_ENV === 'development' && { stack: error.stack })
    });
  }
});

// Add payment method
export const addPaymentMethod = onRequest({
  cors: true,
  maxInstances: 20,
  memory: '256MiB',
  timeoutSeconds: 15
}, async (req, res) => {
  try {
    await corsMiddleware(req, res);
    await rateLimiter.apply(req, res);
    await requestLogger(req, res);
    await performanceMonitor.start(req, res);

    const { error, value } = validateRequest(req.body, paymentSchemas.addPaymentMethod);
    if (error) {
      return res.status(400).json({
        success: false,
        error: 'Validation failed',
        details: error.details,
        code: 'VALIDATION_ERROR'
      });
    }

    const result = await PaymentService.addPaymentMethod(value);
    
    await performanceMonitor.end(req, res);
    
    res.json({
      success: true,
      data: result,
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    await performanceMonitor.end(req, res);
    logger.error('Error adding payment method', { 
      error: error.message, 
      stack: error.stack,
      body: req.body 
    });
    
    const statusCode = error.statusCode || 500;
    const message = error.statusCode ? error.message : 'Failed to add payment method';
    
    res.status(statusCode).json({
      success: false,
      error: message,
      code: error.code || 'INTERNAL_ERROR',
      ...(process.env.NODE_ENV === 'development' && { stack: error.stack })
    });
  }
});

// Get app configuration
export const getAppConfig = onRequest({
  cors: true,
  maxInstances: 10,
  memory: '256MiB',
  timeoutSeconds: 10
}, async (req, res) => {
  try {
    await corsMiddleware(req, res);
    await requestLogger(req, res);
    await performanceMonitor.start(req, res);

    await performanceMonitor.end(req, res);
    
    res.json({
      success: true,
      data: {
        version: '3.0.0',
        features: {
          parking: true,
          payments: true,
          notifications: true,
          userProfiles: true
        },
        limits: {
          maxSessions: 10,
          maxPaymentMethods: 5,
          sessionTimeout: 24 * 60 * 60 * 1000 // 24 hours in milliseconds
        },
        api: {
          rateLimit: '100 requests per 15 minutes',
          maxFileSize: '10MB',
          supportedFormats: ['JSON']
        }
      },
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    await performanceMonitor.end(req, res);
    logger.error('Error getting app config', { 
      error: error.message, 
      stack: error.stack 
    });
    
    res.status(500).json({
      success: false,
      error: 'Failed to get app configuration',
      code: 'INTERNAL_ERROR',
      ...(process.env.NODE_ENV === 'development' && { stack: error.stack })
    });
  }
});

// ============================================================================
// FIRESTORE TRIGGERS
// ============================================================================

// Handle parking session completion
export const onParkingSessionComplete = onDocumentCreated(
  'users/{userId}/parkingSessions/{sessionId}',
  {
    memory: '256MiB',
    timeoutSeconds: 60,
    retryCount: 2
  },
  async (event) => {
    try {
      const sessionData = event.data.data();
      const { userId, sessionId } = event.params;
      
      if (sessionData.status === 'completed') {
        // Parallel execution for better performance
        const [notification, statsUpdate] = await Promise.allSettled([
          NotificationService.sendSessionCompletionNotification(userId, sessionId),
          UserService.updateUserStats(userId, 'sessionsCompleted')
        ]);

        // Handle individual results
        if (notification.status === 'rejected') {
          logger.warn('Failed to send session completion notification', { 
            userId, sessionId, error: notification.reason 
          });
        }
        
        if (statsUpdate.status === 'rejected') {
          logger.warn('Failed to update user stats', { 
            userId, error: statsUpdate.reason 
          });
        }
        
        logger.info('Parking session completion handled', { userId, sessionId });
      }
    } catch (error) {
      logger.error('Error handling parking session completion', { 
        userId: event.params?.userId, 
        sessionId: event.params?.sessionId,
        error: error.message,
        stack: error.stack 
      });
    }
  }
);

// Handle payment success
export const onPaymentSuccess = onDocumentCreated(
  'users/{userId}/payments/{paymentId}',
  {
    memory: '256MiB',
    timeoutSeconds: 60,
    retryCount: 2
  },
  async (event) => {
    try {
      const paymentData = event.data.data();
      const { userId, paymentId } = event.params;
      
      if (paymentData.status === 'succeeded') {
        // Parallel execution for better performance
        const [notification, statsUpdate] = await Promise.allSettled([
          NotificationService.sendPaymentSuccessNotification(userId, paymentId),
          UserService.updateUserStats(userId, 'paymentsCompleted')
        ]);

        // Handle individual results
        if (notification.status === 'rejected') {
          logger.warn('Failed to send payment success notification', { 
            userId, paymentId, error: notification.reason 
          });
        }
        
        if (statsUpdate.status === 'rejected') {
          logger.warn('Failed to update user stats', { 
            userId, error: statsUpdate.reason 
          });
        }
        
        logger.info('Payment success handled', { userId, paymentId });
      }
    } catch (error) {
      logger.error('Error handling payment success', { 
        userId: event.params?.userId, 
        paymentId: event.params?.paymentId,
        error: error.message,
        stack: error.stack 
      });
    }
  }
);


