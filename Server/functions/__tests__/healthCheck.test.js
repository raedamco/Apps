import { describe, it, expect, beforeEach, jest } from '@jest/globals';
import { healthCheck } from '../index.js';

// Mock Firebase Admin
jest.mock('firebase-admin/firestore', () => ({
  getFirestore: jest.fn(() => ({
    collection: jest.fn(() => ({
      doc: jest.fn(() => ({
        get: jest.fn()
      }))
    }))
  }))
}));

describe('Health Check Endpoint', () => {
  let mockReq;
  let mockRes;

  beforeEach(() => {
    mockReq = global.testUtils.createMockRequest({
      method: 'GET',
      path: '/health',
      headers: {
        'x-request-id': 'test-request-123'
      }
    });

    mockRes = global.testUtils.createMockResponse();
  });

  describe('GET /health', () => {
    it('should return successful health check response', async () => {
      await healthCheck(mockReq, mockRes);

      expect(mockRes.json).toHaveBeenCalledWith(
        expect.objectContaining({
          success: true,
          message: 'Parking App Server is running',
          version: '3.0.0',
          checks: expect.objectContaining({
            firebase: true,
            database: true,
            timestamp: expect.any(String)
          }),
          responseTime: expect.stringMatching(/^\d+ms$/),
          timestamp: expect.any(String)
        })
      );
    });

    it('should include request ID in response headers', async () => {
      await healthCheck(mockReq, mockRes);

      expect(mockRes.set).toHaveBeenCalledWith('X-Request-ID', 'test-request-123');
    });

    it('should handle Firebase connection failure gracefully', async () => {
      // Mock Firebase failure
      const { getFirestore } = await import('firebase-admin/firestore');
      const mockDb = getFirestore();
      mockDb.collection.mockImplementation(() => {
        throw new Error('Firebase connection failed');
      });

      await healthCheck(mockReq, mockRes);

      expect(mockRes.json).toHaveBeenCalledWith(
        expect.objectContaining({
          success: true,
          checks: expect.objectContaining({
            firebase: false,
            database: false
          })
        })
      );
    });

    it('should handle unexpected errors', async () => {
      // Mock an unexpected error
      mockRes.json.mockImplementation(() => {
        throw new Error('Unexpected error');
      });

      await healthCheck(mockReq, mockRes);

      expect(mockRes.status).toHaveBeenCalledWith(500);
      expect(mockRes.json).toHaveBeenCalledWith(
        expect.objectContaining({
          success: false,
          message: 'Internal server error'
        })
      );
    });

    it('should include error details in development mode', async () => {
      // Set development mode
      const originalEnv = process.env.NODE_ENV;
      process.env.NODE_ENV = 'development';

      // Mock an error
      mockRes.json.mockImplementation(() => {
        throw new Error('Test error');
      });

      await healthCheck(mockReq, mockRes);

      expect(mockRes.json).toHaveBeenCalledWith(
        expect.objectContaining({
          success: false,
          error: 'Test error'
        })
      );

      // Restore environment
      process.env.NODE_ENV = originalEnv;
    });

    it('should mask error details in production mode', async () => {
      // Set production mode
      const originalEnv = process.env.NODE_ENV;
      process.env.NODE_ENV = 'production';

      // Mock an error
      mockRes.json.mockImplementation(() => {
        throw new Error('Test error');
      });

      await healthCheck(mockReq, mockRes);

      expect(mockRes.json).toHaveBeenCalledWith(
        expect.objectContaining({
          success: false,
          error: 'Something went wrong'
        })
      );

      // Restore environment
      process.env.NODE_ENV = originalEnv;
    });

    it('should measure response time accurately', async () => {
      const startTime = Date.now();
      
      await healthCheck(mockReq, mockRes);
      
      const endTime = Date.now();
      const actualResponseTime = endTime - startTime;

      const response = mockRes.json.mock.calls[0][0];
      const reportedResponseTime = parseInt(response.responseTime.replace('ms', ''));

      // Response time should be reasonable (within 100ms of actual)
      expect(reportedResponseTime).toBeGreaterThanOrEqual(0);
      expect(reportedResponseTime).toBeLessThanOrEqual(actualResponseTime + 100);
    });
  });
});
