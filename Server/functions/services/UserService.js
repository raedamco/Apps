import admin from 'firebase-admin';
import Stripe from 'stripe';
import { logger } from '../utils/logger.js';

class UserService {
  constructor() {
    // Lazy initialization of services
    this._db = null;
    this._auth = null;
    this._stripe = null;
  }

  // Lazy getters for services
  get db() {
    if (!this._db) {
      this._db = admin.firestore();
    }
    return this._db;
  }

  get auth() {
    if (!this._auth) {
      this._auth = admin.auth();
    }
    return this._auth;
  }

  get stripe() {
    if (!this._stripe) {
      this._stripe = new Stripe(process.env.STRIPE_SECRET_KEY, {
        apiVersion: '2023-10-16',
        maxNetworkRetries: 3,
        timeout: 30000
      });
    }
    return this._stripe;
  }

  // In-memory cache for frequently accessed data
  _userCache = new Map();
  _CACHE_TTL = 5 * 60 * 1000; // 5 minutes

  // Create a new user profile in Firestore with optimization
  async createUserProfile(user) {
    try {
      const userData = {
        uid: user.uid,
        email: user.email,
        displayName: user.displayName || null,
        photoURL: user.photoURL || null,
        phoneNumber: user.phoneNumber || null,
        emailVerified: user.emailVerified || false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        status: 'active',
        preferences: {
          notifications: true,
          locationServices: true,
          darkMode: false,
          language: 'en'
        },
        stats: {
          totalSessions: 0,
          totalSpent: 0,
          sessionsCompleted: 0,
          paymentsCompleted: 0
        },
        metadata: {
          createdVia: user.providerData?.[0]?.providerId || 'email',
          lastLogin: admin.firestore.FieldValue.serverTimestamp(),
          loginCount: 1
        }
      };

      // Use batch write for better performance
      const batch = this.db.batch();
      const userRef = this.db.collection('users').doc(user.uid);
      batch.set(userRef, userData);
      
      // Create user's subcollections
      const vehiclesRef = userRef.collection('vehicles').doc('default');
      const permitsRef = userRef.collection('permits').doc('default');
      
      batch.set(vehiclesRef, { placeholder: true, createdAt: admin.firestore.FieldValue.serverTimestamp() });
      batch.set(permitsRef, { placeholder: true, createdAt: admin.firestore.FieldValue.serverTimestamp() });
      
      await batch.commit();
      
      // Cache the user data
      this._cacheUser(user.uid, userData);
      
      logger.info('User profile created successfully', { uid: user.uid });
      return userData;
    } catch (error) {
      logger.error('Error creating user profile', { uid: user.uid, error: error.message });
      throw new Error(`Failed to create user profile: ${error.message}`);
    }
  }

  // Create a Stripe customer for the user with retry logic
  async createStripeCustomer(user) {
    try {
      const customer = await this.stripe.customers.create({
        email: user.email,
        metadata: {
          firebase_uid: user.uid,
          created_at: new Date().toISOString()
        },
        description: `Parking App User: ${user.email}`,
        preferred_locales: ['en']
      });

      // Store Stripe customer ID in user profile
      await this.db.collection('users').doc(user.uid).update({
        stripeCustomerId: customer.id,
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      });

      logger.info('Stripe customer created successfully', { uid: user.uid, customerId: customer.id });
      return customer;
    } catch (error) {
      logger.error('Error creating Stripe customer', { uid: user.uid, error: error.message });
      throw new Error(`Failed to create Stripe customer: ${error.message}`);
    }
  }

  // Get user profile by ID with caching
  async getUserProfile(uid) {
    try {
      // Check cache first
      const cached = this._getCachedUser(uid);
      if (cached) {
        return cached;
      }

      const userDoc = await this.db.collection('users').doc(uid).get();
      
      if (!userDoc.exists) {
        return null;
      }

      const userData = userDoc.data();
      
      // Cache the user data
      this._cacheUser(uid, userData);
      
      return userData;
    } catch (error) {
      logger.error('Error getting user profile', { uid, error: error.message });
      throw new Error(`Failed to get user profile: ${error.message}`);
    }
  }

  // Update user profile
  async updateUserProfile(uid, updates) {
    try {
      const updateData = {
        ...updates,
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      };

      await this.db.collection('users').doc(uid).update(updateData);
      
      // Invalidate cache
      this._invalidateUserCache(uid);
      
      logger.info('User profile updated successfully', { uid });
      return true;
    } catch (error) {
      logger.error('Error updating user profile', { uid, error: error.message });
      throw new Error(`Failed to update user profile: ${error.message}`);
    }
  }

  // Delete user profile and cleanup
  async deleteUserProfile(uid) {
    try {
      // Delete user document
      await this.db.collection('users').doc(uid).delete();
      
      // Invalidate cache
      this._invalidateUserCache(uid);
      
      logger.info('User profile deleted successfully', { uid });
      return true;
    } catch (error) {
      logger.error('Error deleting user profile', { uid, error: error.message });
      throw new Error(`Failed to delete user profile: ${error.message}`);
    }
  }

  // Cleanup user data when account is deleted
  async cleanupUserData(user) {
    try {
      const batch = this.db.batch();
      
      // Get all user's subcollections
      const collections = ['parkingSessions', 'payments', 'vehicles', 'permits', 'notifications'];
      
      for (const collectionName of collections) {
        const snapshot = await this.db.collection('users').doc(user.uid).collection(collectionName).get();
        snapshot.docs.forEach(doc => {
          batch.delete(doc.ref);
        });
      }
      
      await batch.commit();
      
      logger.info('User data cleanup completed', { uid: user.uid });
      return true;
    } catch (error) {
      logger.error('Error cleaning up user data', { uid: user.uid, error: error.message });
      throw new Error(`Failed to cleanup user data: ${error.message}`);
    }
  }

  // Delete Stripe customer
  async deleteStripeCustomer(user) {
    try {
      if (user.stripeCustomerId) {
        await this.stripe.customers.del(user.stripeCustomerId);
        logger.info('Stripe customer deleted', { uid: user.uid, customerId: user.stripeCustomerId });
      }
      return true;
    } catch (error) {
      logger.error('Error deleting Stripe customer', { uid: user.uid, error: error.message });
      // Don't throw error as this is not critical
      return false;
    }
  }

  // Update user stats
  async updateUserStats(uid, statType, value = 1) {
    try {
      const updateData = {};
      updateData[`stats.${statType}`] = admin.firestore.FieldValue.increment(value);
      updateData.updatedAt = admin.firestore.FieldValue.serverTimestamp();

      await this.db.collection('users').doc(uid).update(updateData);
      
      // Invalidate cache
      this._invalidateUserCache(uid);
      
      logger.info('User stats updated', { uid, statType, value });
      return true;
    } catch (error) {
      logger.error('Error updating user stats', { uid, statType, error: error.message });
      throw new Error(`Failed to update user stats: ${error.message}`);
    }
  }

  // Get user's parking sessions
  async getUserSessions(uid, options = {}) {
    try {
      const { limit = 20, offset = 0, status = null } = options;
      
      let query = this.db.collection('users').doc(uid).collection('parkingSessions');
      
      if (status) {
        query = query.where('status', '==', status);
      }
      
      query = query.orderBy('startTime', 'desc');
      
      const snapshot = await query.limit(limit).offset(offset).get();
      
      const sessions = [];
      snapshot.forEach(doc => {
        sessions.push({
          id: doc.id,
          ...doc.data()
        });
      });

      return { sessions };
    } catch (error) {
      logger.error('Error getting user sessions', { uid, error: error.message });
      throw new Error(`Failed to get user sessions: ${error.message}`);
    }
  }

  // Get recent payments
  async getRecentPayments(uid, limit = 30) {
    try {
      const snapshot = await this.db.collection('users').doc(uid)
        .collection('payments')
        .where('status', '==', 'succeeded')
        .orderBy('createdAt', 'desc')
        .limit(limit)
        .get();

      const payments = [];
      snapshot.forEach(doc => {
        payments.push({
          id: doc.id,
          ...doc.data()
        });
      });

      return { payments };
    } catch (error) {
      logger.error('Error getting recent payments', { uid, error: error.message });
      throw new Error(`Failed to get recent payments: ${error.message}`);
    }
  }

  // Get favorite parking locations
  _getFavoriteLocations(sessions) {
    const locationCounts = {};
    
    sessions.forEach(session => {
      const locationKey = `${session.location?.organization}-${session.location?.name}`;
      if (locationKey && locationKey !== 'undefined-undefined') {
        locationCounts[locationKey] = (locationCounts[locationKey] || 0) + 1;
      }
    });

    return Object.entries(locationCounts)
      .sort(([,a], [,b]) => b - a)
      .slice(0, 5)
      .map(([location, count]) => ({
        location: location.replace('-', ' - '),
        count
      }));
  }

  // Get peak usage times
  _getPeakUsageTimes(sessions) {
    const hourCounts = new Array(24).fill(0);
    
    sessions.forEach(session => {
      if (session.startTime) {
        const hour = new Date(session.startTime.toDate()).getHours();
        hourCounts[hour]++;
      }
    });

    const peakHours = hourCounts
      .map((count, hour) => ({ hour, count }))
      .sort((a, b) => b.count - a.count)
      .slice(0, 3);

    return peakHours.map(({ hour, count }) => ({
      hour: `${hour}:00`,
      count
    }));
  }

  // Cache management methods
  _cacheUser(uid, userData) {
    this._userCache.set(uid, {
      data: userData,
      timestamp: Date.now()
    });
  }

  _getCachedUser(uid) {
    const cached = this._userCache.get(uid);
    if (cached && Date.now() - cached.timestamp < this._CACHE_TTL) {
      return cached.data;
    }
    return null;
  }

  _invalidateUserCache(uid) {
    this._userCache.delete(uid);
  }

  // Generate unique ID
  _generateId() {
    return Math.random().toString(36).substring(2) + Date.now().toString(36);
  }
}

export default new UserService();
