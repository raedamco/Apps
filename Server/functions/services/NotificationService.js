import admin from 'firebase-admin';
import { logger } from '../utils/logger.js';

class NotificationService {
  constructor() {
    // Lazy initialization of services
    this._db = null;
    this._messaging = null;
  }

  // Lazy getters for services
  get db() {
    if (!this._db) {
      this._db = admin.firestore();
    }
    return this._db;
  }

  get messaging() {
    if (!this._messaging) {
      this._messaging = admin.messaging();
    }
    return this._messaging;
  }

  // Send welcome notification to new user
  async sendWelcomeNotification(user) {
    try {
      const notification = {
        title: 'Welcome to Parking App! 🎉',
        body: 'Thank you for joining us. Start parking smarter today!',
        data: {
          type: 'welcome',
          userId: user.uid,
          clickAction: 'OPEN_HOME'
        },
        android: {
          notification: {
            icon: 'ic_notification',
            color: '#4CAF50',
            clickAction: 'OPEN_HOME'
          }
        },
        apns: {
          payload: {
            aps: {
              badge: 1,
              sound: 'default',
              category: 'WELCOME'
            }
          }
        }
      };

      // Send to user's FCM token if available
      const userProfile = await this.db.collection('users').doc(user.uid).get();
      if (userProfile.exists && userProfile.data().fcmToken) {
        await this.messaging.send({
          ...notification,
          token: userProfile.data().fcmToken
        });
      }

      // Store notification in database
      await this._storeNotification(user.uid, {
        type: 'welcome',
        title: notification.title,
        body: notification.body,
        data: notification.data,
        status: 'sent',
        createdAt: admin.firestore.FieldValue.serverTimestamp()
      });

      logger.info('Welcome notification sent successfully', { uid: user.uid });
    } catch (error) {
      logger.error('Error sending welcome notification', { 
        uid: user.uid, 
        error: error.message 
      });
      // Don't throw error as this is not critical
    }
  }

  // Send parking session completion notification
  async sendSessionCompletionNotification(userId, sessionId) {
    try {
      // Get session details
      const sessionDoc = await this.db.collection('users').doc(userId)
        .collection('parkingSessions')
        .doc(sessionId)
        .get();

      if (!sessionDoc.exists) {
        throw new Error('Session not found');
      }

      const session = sessionDoc.data();
      
      const notification = {
        title: 'Parking Session Complete! 🚗',
        body: `Your ${session.duration} minute session at ${session.location.name} is complete. ` +
              'Total cost: $${session.cost}',
        data: {
          type: 'session_complete',
          sessionId,
          userId,
          clickAction: 'OPEN_PAYMENT',
          cost: session.cost.toString(),
          location: session.location.name
        },
        android: {
          notification: {
            icon: 'ic_notification',
            color: '#2196F3',
            clickAction: 'OPEN_PAYMENT'
          }
        },
        apns: {
          payload: {
            aps: {
              badge: 1,
              sound: 'default',
              category: 'SESSION_COMPLETE'
            }
          }
        }
      };

      // Send to user's FCM token
      const userProfile = await this.db.collection('users').doc(userId).get();
      if (userProfile.exists && userProfile.data().fcmToken) {
        await this.messaging.send({
          ...notification,
          token: userProfile.data().fcmToken
        });
      }

      // Store notification
      await this._storeNotification(userId, {
        type: 'session_complete',
        title: notification.title,
        body: notification.body,
        data: notification.data,
        sessionId,
        status: 'sent',
        createdAt: admin.firestore.FieldValue.serverTimestamp()
      });

      logger.info('Session completion notification sent', { userId, sessionId });
    } catch (error) {
      logger.error('Error sending session completion notification', { 
        userId, 
        sessionId,
        error: error.message 
      });
    }
  }

  // Send payment success notification
  async sendPaymentSuccessNotification(userId, paymentId) {
    try {
      // Get payment details
      const paymentDoc = await this.db.collection('users').doc(userId)
        .collection('payments')
        .doc(paymentId)
        .get();

      if (!paymentDoc.exists) {
        throw new Error('Payment not found');
      }

      const payment = paymentDoc.data();
      
      const notification = {
        title: 'Payment Successful! 💳',
        body: `Your payment of $${payment.amount} has been processed successfully.`,
        data: {
          type: 'payment_success',
          paymentId,
          userId,
          clickAction: 'OPEN_PAYMENT_HISTORY',
          amount: payment.amount.toString()
        },
        android: {
          notification: {
            icon: 'ic_notification',
            color: '#4CAF50',
            clickAction: 'OPEN_PAYMENT_HISTORY'
          }
        },
        apns: {
          payload: {
            aps: {
              badge: 1,
              sound: 'default',
              category: 'PAYMENT_SUCCESS'
            }
          }
        }
      };

      // Send to user's FCM token
      const userProfile = await this.db.collection('users').doc(userId).get();
      if (userProfile.exists && userProfile.data().fcmToken) {
        await this.messaging.send({
          ...notification,
          token: userProfile.data().fcmToken
        });
      }

      // Store notification
      await this._storeNotification(userId, {
        type: 'payment_success',
        title: notification.title,
        body: notification.body,
        data: notification.data,
        paymentId,
        status: 'sent',
        createdAt: admin.firestore.FieldValue.serverTimestamp()
      });

      logger.info('Payment success notification sent', { userId, paymentId });
    } catch (error) {
      logger.error('Error sending payment success notification', { 
        userId, 
        paymentId,
        error: error.message 
      });
    }
  }

  // Send payment failure notification
  async sendPaymentFailureNotification(userId, paymentId, reason) {
    try {
      const notification = {
        title: 'Payment Failed ❌',
        body: `Your payment could not be processed. Reason: ${reason}`,
        data: {
          type: 'payment_failure',
          paymentId,
          userId,
          clickAction: 'OPEN_PAYMENT_RETRY',
          reason
        },
        android: {
          notification: {
            icon: 'ic_notification',
            color: '#F44336',
            clickAction: 'OPEN_PAYMENT_RETRY'
          }
        },
        apns: {
          payload: {
            aps: {
              badge: 1,
              sound: 'default',
              category: 'PAYMENT_FAILURE'
            }
          }
        }
      };

      // Send to user's FCM token
      const userProfile = await this.db.collection('users').doc(userId).get();
      if (userProfile.exists && userProfile.data().fcmToken) {
        await this.messaging.send({
          ...notification,
          token: userProfile.data().fcmToken
        });
      }

      // Store notification
      await this._storeNotification(userId, {
        type: 'payment_failure',
        title: notification.title,
        body: notification.body,
        data: notification.data,
        paymentId,
        reason,
        status: 'sent',
        createdAt: admin.firestore.FieldValue.serverTimestamp()
      });

      logger.info('Payment failure notification sent', { userId, paymentId, reason });
    } catch (error) {
      logger.error('Error sending payment failure notification', { 
        userId, 
        paymentId,
        error: error.message 
      });
    }
  }

  // Send parking reminder notification
  async sendParkingReminderNotification(userId, sessionId) {
    try {
      // Get session details
      const sessionDoc = await this.db.collection('users').doc(userId)
        .collection('parkingSessions')
        .doc(sessionId)
        .get();

      if (!sessionDoc.exists) {
        throw new Error('Session not found');
      }

      const session = sessionDoc.data();
      
      const notification = {
        title: 'Parking Reminder ⏰',
        body: `Your parking session at ${session.location.name} is still active. ` +
              'Don\'t forget to end it when you\'re done!',
        data: {
          type: 'parking_reminder',
          sessionId,
          userId,
          clickAction: 'OPEN_SESSION',
          location: session.location.name
        },
        android: {
          notification: {
            icon: 'ic_notification',
            color: '#FF9800',
            clickAction: 'OPEN_SESSION'
          }
        },
        apns: {
          payload: {
            aps: {
              badge: 1,
              sound: 'default',
              category: 'PARKING_REMINDER'
            }
          }
        }
      };

      // Send to user's FCM token
      const userProfile = await this.db.collection('users').doc(userId).get();
      if (userProfile.exists && userProfile.data().fcmToken) {
        await this.messaging.send({
          ...notification,
          token: userProfile.data().fcmToken
        });
      }

      // Store notification
      await this._storeNotification(userId, {
        type: 'parking_reminder',
        title: notification.title,
        body: notification.body,
        data: notification.data,
        sessionId,
        status: 'sent',
        createdAt: admin.firestore.FieldValue.serverTimestamp()
      });

      logger.info('Parking reminder notification sent', { userId, sessionId });
    } catch (error) {
      logger.error('Error sending parking reminder notification', { 
        userId, 
        sessionId,
        error: error.message 
      });
    }
  }

  // Send promotional notification
  async sendPromotionalNotification(userId, title, body, data = {}) {
    try {
      const notification = {
        title,
        body,
        data: {
          type: 'promotional',
          userId,
          clickAction: 'OPEN_PROMOTION',
          ...data
        },
        android: {
          notification: {
            icon: 'ic_notification',
            color: '#9C27B0',
            clickAction: 'OPEN_PROMOTION'
          }
        },
        apns: {
          payload: {
            aps: {
              badge: 1,
              sound: 'default',
              category: 'PROMOTIONAL'
            }
          }
        }
      };

      // Send to user's FCM token
      const userProfile = await this.db.collection('users').doc(userId).get();
      if (userProfile.exists && userProfile.data().fcmToken) {
        await this.messaging.send({
          ...notification,
          token: userProfile.data().fcmToken
        });
      }

      // Store notification
      await this._storeNotification(userId, {
        type: 'promotional',
        title: notification.title,
        body: notification.body,
        data: notification.data,
        status: 'sent',
        createdAt: admin.firestore.FieldValue.serverTimestamp()
      });

      logger.info('Promotional notification sent', { userId, title });
    } catch (error) {
      logger.error('Error sending promotional notification', { 
        userId, 
        title,
        error: error.message 
      });
    }
  }

  // Send bulk notification to multiple users
  async sendBulkNotification(userIds, title, body, data = {}) {
    try {
      const results = [];
      
      for (const userId of userIds) {
        try {
          await this.sendPromotionalNotification(userId, title, body, data);
          results.push({ userId, status: 'success' });
        } catch (error) {
          results.push({ userId, status: 'failed', error: error.message });
        }
      }

      // Store bulk notification record
      await this._storeBulkNotification(userIds, title, body, data, results);

      logger.info('Bulk notification completed', { 
        totalUsers: userIds.length,
        successful: results.filter(r => r.status === 'success').length,
        failed: results.filter(r => r.status === 'failed').length
      });

      return results;
    } catch (error) {
      logger.error('Error sending bulk notification', { 
        userIds,
        error: error.message 
      });
      throw error;
    }
  }

  // Update user's FCM token
  async updateFCMToken(userId, fcmToken) {
    try {
      await this.db.collection('users').doc(userId).update({
        fcmToken,
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      });

      logger.info('FCM token updated', { userId });
    } catch (error) {
      logger.error('Error updating FCM token', { 
        userId, 
        error: error.message 
      });
      throw error;
    }
  }

  // Get user's notification history
  async getNotificationHistory(userId, options = {}) {
    try {
      const { limit = 20, offset = 0, type = null } = options;
      
      let query = this.db.collection('users').doc(userId)
        .collection('notifications')
        .orderBy('createdAt', 'desc');

      if (type) {
        query = query.where('type', '==', type);
      }

      const snapshot = await query.limit(limit).offset(offset).get();
      
      const notifications = [];
      snapshot.forEach(doc => {
        notifications.push({
          id: doc.id,
          ...doc.data()
        });
      });

      return {
        notifications,
        total: notifications.length,
        hasMore: notifications.length === limit
      };
    } catch (error) {
      logger.error('Error getting notification history', { 
        userId, 
        error: error.message 
      });
      throw error;
    }
  }

  // Mark notification as read
  async markNotificationAsRead(userId, notificationId) {
    try {
      await this.db.collection('users').doc(userId)
        .collection('notifications')
        .doc(notificationId)
        .update({
          read: true,
          readAt: admin.firestore.FieldValue.serverTimestamp()
        });

      logger.info('Notification marked as read', { userId, notificationId });
    } catch (error) {
      logger.error('Error marking notification as read', { 
        userId, 
        notificationId,
        error: error.message 
      });
      throw error;
    }
  }

  // Delete notification
  async deleteNotification(userId, notificationId) {
    try {
      await this.db.collection('users').doc(userId)
        .collection('notifications')
        .doc(notificationId)
        .delete();

      logger.info('Notification deleted', { userId, notificationId });
    } catch (error) {
      logger.error('Error deleting notification', { 
        userId, 
        notificationId,
        error: error.message 
      });
      throw error;
    }
  }

  // Send deletion notification to user
  async sendDeletionNotification(user) {
    try {
      const notification = {
        title: 'Account Deleted',
        body: 'Your account has been successfully deleted. We hope to see you again!',
        data: {
          type: 'account_deleted',
          userId: user.uid,
          clickAction: 'OPEN_APP'
        },
        android: {
          notification: {
            icon: 'ic_notification',
            color: '#757575',
            clickAction: 'OPEN_APP'
          }
        },
        apns: {
          payload: {
            aps: {
              badge: 1,
              sound: 'default',
              category: 'ACCOUNT_DELETED'
            }
          }
        }
      };

      // Send to user's FCM token if available
      const userProfile = await this.db.collection('users').doc(user.uid).get();
      if (userProfile.exists && userProfile.data().fcmToken) {
        await this.messaging.send({
          ...notification,
          token: userProfile.data().fcmToken
        });
      }

      logger.info('Deletion notification sent', { uid: user.uid });
    } catch (error) {
      logger.error('Error sending deletion notification', { 
        uid: user.uid, 
        error: error.message 
      });
      // Don't throw error as this is not critical
    }
  }

  // Store notification in database
  async _storeNotification(userId, notificationData) {
    try {
      await this.db.collection('users').doc(userId)
        .collection('notifications')
        .add(notificationData);
    } catch (error) {
      logger.error('Error storing notification', { 
        userId, 
        error: error.message 
      });
      // Don't throw error as this is not critical
    }
  }

  // Store bulk notification record
  async _storeBulkNotification(userIds, title, body, data, results) {
    try {
      await this.db.collection('bulkNotifications').add({
        userIds,
        title,
        body,
        data,
        results,
        createdAt: admin.firestore.FieldValue.serverTimestamp()
      });
    } catch (error) {
      logger.error('Error storing bulk notification record', { 
        error: error.message 
      });
      // Don't throw error as this is not critical
    }
  }
}

export default new NotificationService();
