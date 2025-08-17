import admin from 'firebase-admin';
import { logger } from '../utils/logger.js';

class ParkingService {
  constructor() {
    // Lazy initialization of services
    this._db = null;
  }

  // Lazy getters for services
  get db() {
    if (!this._db) {
      this._db = admin.firestore();
    }
    return this._db;
  }

  // Start a new parking session
  async startSession(sessionData) {
    try {
      const { uid, location, rate, organization, startTime } = sessionData;
      
      const session = {
        id: this.db.collection('parkingSessions').doc().id,
        uid,
        location: {
          latitude: location.latitude,
          longitude: location.longitude,
          address: location.address,
          organization,
          name: location.name || 'Unknown Location',
          floor: location.floor || null,
          spot: location.spot || null
        },
        rate: parseFloat(rate),
        startTime: admin.firestore.Timestamp.fromDate(startTime),
        status: 'active',
        estimatedCost: 0,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      };

      // Save to user's parking sessions collection
      await this.db.collection('users').doc(uid)
        .collection('parkingSessions')
        .doc(session.id)
        .set(session);

      // Save to global parking sessions collection for analytics
      await this.db.collection('parkingSessions')
        .doc(session.id)
        .set(session);

      // Update user stats
      await this.db.collection('users').doc(uid).update({
        'stats.totalSessions': admin.firestore.FieldValue.increment(1),
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      });

      logger.info('Parking session started successfully', { 
        uid, 
        sessionId: session.id,
        location: session.location 
      });

      return session;
    } catch (error) {
      logger.error('Error starting parking session', { 
        uid: sessionData.uid, 
        error: error.message 
      });
      throw new Error(`Failed to start parking session: ${error.message}`);
    }
  }

  // End a parking session and calculate final cost
  async endSession(sessionId, uid) {
    try {
      // Get the session
      const sessionDoc = await this.db.collection('users').doc(uid)
        .collection('parkingSessions')
        .doc(sessionId)
        .get();

      if (!sessionDoc.exists) {
        throw new Error('Parking session not found');
      }

      const session = sessionDoc.data();
      
      if (session.status !== 'active') {
        throw new Error('Parking session is not active');
      }

      const endTime = new Date();
      const startTime = session.startTime.toDate();
      const durationMinutes = Math.floor((endTime - startTime) / (1000 * 60));
      const cost = this._calculateCost(durationMinutes, session.rate);

      const updatedSession = {
        ...session,
        endTime: admin.firestore.Timestamp.fromDate(endTime),
        duration: durationMinutes,
        cost: parseFloat(cost.toFixed(2)),
        status: 'completed',
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      };

      // Update session in user's collection
      await this.db.collection('users').doc(uid)
        .collection('parkingSessions')
        .doc(sessionId)
        .update(updatedSession);

      // Update session in global collection
      await this.db.collection('parkingSessions')
        .doc(sessionId)
        .update(updatedSession);

      // Update user stats
      await this.db.collection('users').doc(uid).update({
        'stats.sessionsCompleted': admin.firestore.FieldValue.increment(1),
        'stats.totalSpent': admin.firestore.FieldValue.increment(updatedSession.cost),
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      });

      logger.info('Parking session ended successfully', { 
        uid, 
        sessionId,
        duration: durationMinutes,
        cost: updatedSession.cost
      });

      return updatedSession;
    } catch (error) {
      logger.error('Error ending parking session', { 
        uid, 
        sessionId,
        error: error.message 
      });
      throw new Error(`Failed to end parking session: ${error.message}`);
    }
  }

  // Get a specific parking session
  async getSession(sessionId, uid) {
    try {
      const sessionDoc = await this.db.collection('users').doc(uid)
        .collection('parkingSessions')
        .doc(sessionId)
        .get();

      if (!sessionDoc.exists) {
        return null;
      }

      return {
        id: sessionDoc.id,
        ...sessionDoc.data()
      };
    } catch (error) {
      logger.error('Error getting parking session', { 
        uid, 
        sessionId,
        error: error.message 
      });
      throw new Error(`Failed to get parking session: ${error.message}`);
    }
  }

  // Get user's parking history
  async getUserHistory(uid, options = {}) {
    try {
      const { limit = 20, offset = 0, status = null } = options;
      
      let query = this.db.collection('users').doc(uid)
        .collection('parkingSessions')
        .orderBy('startTime', 'desc');

      if (status) {
        query = query.where('status', '==', status);
      }

      const snapshot = await query.limit(limit).offset(offset).get();
      
      const sessions = [];
      snapshot.forEach(doc => {
        sessions.push({
          id: doc.id,
          ...doc.data()
        });
      });

      return {
        sessions,
        total: sessions.length,
        hasMore: sessions.length === limit
      };
    } catch (error) {
      logger.error('Error getting parking history', { 
        uid, 
        error: error.message 
      });
      throw new Error(`Failed to get parking history: ${error.message}`);
    }
  }

  // Extend a parking session
  async extendSession(sessionId, uid, extensionMinutes) {
    try {
      // Get the session
      const sessionDoc = await this.db.collection('users').doc(uid)
        .collection('parkingSessions')
        .doc(sessionId)
        .get();

      if (!sessionDoc.exists) {
        throw new Error('Parking session not found');
      }

      const session = sessionDoc.data();
      
      if (session.status !== 'active') {
        throw new Error('Parking session is not active');
      }

      // Calculate new estimated cost
      const currentDuration = Math.floor((new Date() - session.startTime.toDate()) / (1000 * 60));
      const newDuration = currentDuration + extensionMinutes;
      const newCost = this._calculateCost(newDuration, session.rate);

      const updatedSession = {
        ...session,
        estimatedCost: parseFloat(newCost.toFixed(2)),
        extensionMinutes: (session.extensionMinutes || 0) + extensionMinutes,
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      };

      // Update session in user's collection
      await this.db.collection('users').doc(uid)
        .collection('parkingSessions')
        .doc(sessionId)
        .update(updatedSession);

      // Update session in global collection
      await this.db.collection('parkingSessions')
        .doc(sessionId)
        .update(updatedSession);

      logger.info('Parking session extended successfully', { 
        uid, 
        sessionId,
        extensionMinutes,
        newEstimatedCost: newCost
      });

      return updatedSession;
    } catch (error) {
      logger.error('Error extending parking session', { 
        uid, 
        sessionId,
        extensionMinutes,
        error: error.message 
      });
      throw new Error(`Failed to extend parking session: ${error.message}`);
    }
  }

  // Cancel a parking session
  async cancelSession(sessionId, uid) {
    try {
      // Get the session
      const sessionDoc = await this.db.collection('users').doc(uid)
        .collection('parkingSessions')
        .doc(sessionId)
        .get();

      if (!sessionDoc.exists) {
        throw new Error('Parking session not found');
      }

      const session = sessionDoc.data();
      
      if (session.status !== 'active') {
        throw new Error('Parking session is not active');
      }

      const updatedSession = {
        ...session,
        status: 'cancelled',
        cancelledAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      };

      // Update session in user's collection
      await this.db.collection('users').doc(uid)
        .collection('parkingSessions')
        .doc(sessionId)
        .update(updatedSession);

      // Update session in global collection
      await this.db.collection('parkingSessions')
        .doc(sessionId)
        .update(updatedSession);

      logger.info('Parking session cancelled successfully', { 
        uid, 
        sessionId
      });

      return updatedSession;
    } catch (error) {
      logger.error('Error cancelling parking session', { 
        uid, 
        sessionId,
        error: error.message 
      });
      throw new Error(`Failed to cancel parking session: ${error.message}`);
    }
  }

  // Find available parking spots near a location
  async findSpots(location, radius = 1000, maxSpots = 20) {
    try {
      // This is a simplified implementation
      // In a real app, you'd use geospatial queries
      const spotsSnapshot = await this.db.collection('parkingSpots')
        .where('status', '==', 'available')
        .limit(maxSpots)
        .get();

      const spots = [];
      spotsSnapshot.forEach(doc => {
        const spot = doc.data();
        const distance = this._calculateDistance(
          location.latitude,
          location.longitude,
          spot.location.latitude,
          spot.location.longitude
        );

        if (distance <= radius) {
          spots.push({
            id: doc.id,
            ...spot,
            distance: Math.round(distance)
          });
        }
      });

      // Sort by distance
      spots.sort((a, b) => a.distance - b.distance);

      logger.info('Parking spots found', { 
        location,
        radius,
        spotsFound: spots.length
      });

      return spots;
    } catch (error) {
      logger.error('Error finding parking spots', { 
        location,
        error: error.message 
      });
      throw new Error(`Failed to find parking spots: ${error.message}`);
    }
  }

  // Reserve a parking spot
  async reserveSpot(spotId, uid, duration = 60) {
    try {
      // Get the spot
      const spotDoc = await this.db.collection('parkingSpots').doc(spotId).get();
      
      if (!spotDoc.exists) {
        throw new Error('Parking spot not found');
      }

      const spot = spotDoc.data();
      
      if (spot.status !== 'available') {
        throw new Error('Parking spot is not available');
      }

      // Create reservation
      const reservation = {
        id: this.db.collection('reservations').doc().id,
        spotId,
        uid,
        duration,
        startTime: admin.firestore.Timestamp.fromDate(new Date()),
        status: 'reserved',
        createdAt: admin.firestore.FieldValue.serverTimestamp()
      };

      // Save reservation
      await this.db.collection('reservations').doc(reservation.id).set(reservation);

      // Update spot status
      await this.db.collection('parkingSpots').doc(spotId).update({
        status: 'reserved',
        reservedBy: uid,
        reservedUntil: admin.firestore.Timestamp.fromDate(
          new Date(Date.now() + duration * 60 * 1000)
        ),
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      });

      logger.info('Parking spot reserved successfully', { 
        uid, 
        spotId,
        duration
      });

      return reservation;
    } catch (error) {
      logger.error('Error reserving parking spot', { 
        uid, 
        spotId,
        error: error.message 
      });
      throw new Error(`Failed to reserve parking spot: ${error.message}`);
    }
  }

  // Calculate cost based on duration and rate
  _calculateCost(durationMinutes, hourlyRate) {
    const hours = durationMinutes / 60;
    return hours * hourlyRate;
  }

  // Calculate distance between two points using Haversine formula
  _calculateDistance(lat1, lon1, lat2, lon2) {
    const R = 6371; // Earth's radius in kilometers
    const dLat = this._toRadians(lat2 - lat1);
    const dLon = this._toRadians(lon2 - lon1);
    
    const a = Math.sin(dLat / 2) * Math.sin(dLat / 2) +
              Math.cos(this._toRadians(lat1)) * Math.cos(this._toRadians(lat2)) *
              Math.sin(dLon / 2) * Math.sin(dLon / 2);
    
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    const distance = R * c;
    
    return distance * 1000; // Convert to meters
  }

  // Convert degrees to radians
  _toRadians(degrees) {
    return degrees * (Math.PI / 180);
  }
}

export default new ParkingService();
