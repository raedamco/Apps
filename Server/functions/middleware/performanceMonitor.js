import { logger } from '../utils/logger.js';

class PerformanceMonitor {
  constructor() {
    this.metrics = new Map();
    this.thresholds = {
      slow: 1000, // 1 second
      verySlow: 5000 // 5 seconds
    };
  }

  async start(req, res) {
    const startTime = Date.now();
    const requestId = req.headers['x-request-id'] || this.generateRequestId();
    
    // Store start time
    this.metrics.set(requestId, {
      startTime,
      path: req.path,
      method: req.method,
      userAgent: req.get('User-Agent'),
      ip: req.ip
    });

    // Add request ID to response headers
    res.set('X-Request-ID', requestId);
    
    // Add timing header
    res.set('X-Response-Time', '0ms');
    
    return requestId;
  }

  async end(req, res) {
    const requestId = res.get('X-Request-ID');
    if (!requestId) return;

    const metric = this.metrics.get(requestId);
    if (!metric) return;

    const endTime = Date.now();
    const duration = endTime - metric.startTime;
    
    // Update response time header
    res.set('X-Response-Time', `${duration}ms`);
    
    // Log performance metrics
    this.logPerformance(requestId, metric, duration);
    
    // Clean up
    this.metrics.delete(requestId);
  }

  logPerformance(requestId, metric, duration) {
    const logData = {
      requestId,
      path: metric.path,
      method: metric.method,
      duration: `${duration}ms`,
      userAgent: metric.userAgent,
      ip: metric.ip
    };

    if (duration > this.thresholds.verySlow) {
      logger.warn('Very slow request detected', logData);
    } else if (duration > this.thresholds.slow) {
      logger.info('Slow request detected', logData);
    } else {
      logger.debug('Request completed', logData);
    }
  }

  generateRequestId() {
    return `req_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
  }

  // Get performance statistics
  getStats() {
    const stats = {
      activeRequests: this.metrics.size,
      totalRequests: 0,
      averageResponseTime: 0,
      slowRequests: 0,
      verySlowRequests: 0
    };

    return stats;
  }

  // Reset metrics (useful for testing)
  reset() {
    this.metrics.clear();
  }
}

export const performanceMonitor = new PerformanceMonitor();
export default performanceMonitor;
