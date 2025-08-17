import { logger } from '../utils/logger.js';

// Request logging middleware
export const requestLogger = (req, res, next) => {
  const startTime = Date.now();
  
  // Log request start
  logger.info('Request started', {
    method: req.method,
    path: req.path,
    ip: req.ip,
    userAgent: req.get('User-Agent'),
    timestamp: new Date().toISOString()
  });

  // Override res.end to log response
  const originalEnd = res.end;
  res.end = function(chunk, encoding) {
    const duration = Date.now() - startTime;
    
    // Log request completion
    logger.info('Request completed', {
      method: req.method,
      path: req.path,
      statusCode: res.statusCode,
      duration,
      ip: req.ip,
      userAgent: req.get('User-Agent'),
      timestamp: new Date().toISOString()
    });

    // Call original end method
    originalEnd.call(this, chunk, encoding);
  };

  next();
};

// Detailed request logger for debugging
export const detailedRequestLogger = (req, res, next) => {
  const startTime = Date.now();
  
  // Log detailed request information
  logger.info('Detailed request info', {
    method: req.method,
    path: req.path,
    url: req.url,
    query: req.query,
    body: req.body,
    headers: req.headers,
    ip: req.ip,
    userAgent: req.get('User-Agent'),
    timestamp: new Date().toISOString()
  });

  // Override res.end to log detailed response
  const originalEnd = res.end;
  res.end = function(chunk, encoding) {
    const duration = Date.now() - startTime;
    
    // Log detailed response information
    logger.info('Detailed response info', {
      method: req.method,
      path: req.path,
      statusCode: res.statusCode,
      statusMessage: res.statusMessage,
      duration,
      headers: res.getHeaders(),
      timestamp: new Date().toISOString()
    });

    // Call original end method
    originalEnd.call(this, chunk, encoding);
  };

  next();
};

// Error request logger
export const errorRequestLogger = (error, req, res, next) => {
  logger.error('Request error', {
    method: req.method,
    path: req.path,
    error: error.message,
    stack: error.stack,
    ip: req.ip,
    userAgent: req.get('User-Agent'),
    timestamp: new Date().toISOString()
  });

  next(error);
};
