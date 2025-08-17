import admin from 'firebase-admin';
import Stripe from 'stripe';
import { logger } from '../utils/logger.js';

class PaymentService {
  constructor() {
    // Lazy initialization of services
    this._db = null;
    this._stripe = null;
  }

  // Lazy getters for services
  get db() {
    if (!this._db) {
      this._db = admin.firestore();
    }
    return this._db;
  }

  get stripe() {
    if (!this._stripe) {
      this._stripe = new Stripe(process.env.STRIPE_SECRET_KEY, {
        apiVersion: '2023-10-16'
      });
    }
    return this._stripe;
  }

  // Create a payment intent for a parking session
  async createPaymentIntent(paymentData) {
    try {
      const { uid, sessionId, paymentMethodId } = paymentData;
      
      // Get user profile to get Stripe customer ID
      const userProfile = await this.db.collection('users').doc(uid).get();
      if (!userProfile.exists) {
        throw new Error('User profile not found');
      }

      const user = userProfile.data();
      if (!user.stripeCustomerId) {
        throw new Error('User does not have a Stripe customer account');
      }

      // Get parking session to calculate amount
      const sessionDoc = await this.db.collection('users').doc(uid)
        .collection('parkingSessions')
        .doc(sessionId)
        .get();

      if (!sessionDoc.exists) {
        throw new Error('Parking session not found');
      }

      const session = sessionDoc.data();
      if (session.status !== 'completed') {
        throw new Error('Parking session must be completed before payment');
      }

      const amount = Math.round(session.cost * 100); // Convert to cents
      
      // Create payment intent
      const paymentIntent = await this.stripe.paymentIntents.create({
        amount,
        currency: 'usd',
        customer: user.stripeCustomerId,
        payment_method: paymentMethodId,
        confirm: false,
        description: `Parking session at ${session.location.name}`,
        metadata: {
          firebase_uid: uid,
          session_id: sessionId,
          location: session.location.name,
          duration: session.duration.toString(),
          rate: session.rate.toString()
        }
      });

      // Store payment intent in database
      const paymentRecord = {
        id: paymentIntent.id,
        uid,
        sessionId,
        amount: session.cost,
        currency: 'usd',
        status: 'pending',
        stripePaymentIntentId: paymentIntent.id,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      };

      await this.db.collection('users').doc(uid)
        .collection('payments')
        .doc(paymentIntent.id)
        .set(paymentRecord);

      // Also store in global payments collection
      await this.db.collection('payments')
        .doc(paymentIntent.id)
        .set(paymentRecord);

      logger.info('Payment intent created successfully', { 
        uid, 
        sessionId,
        paymentIntentId: paymentIntent.id,
        amount: session.cost 
      });

      return paymentIntent;
    } catch (error) {
      logger.error('Error creating payment intent', { 
        uid: paymentData.uid, 
        sessionId: paymentData.sessionId,
        error: error.message 
      });
      throw new Error(`Failed to create payment intent: ${error.message}`);
    }
  }

  // Confirm a payment intent
  async confirmPayment(paymentData) {
    try {
      const { uid, sessionId, paymentIntentId } = paymentData;
      
      // Get payment intent from Stripe
      const paymentIntent = await this.stripe.paymentIntents.retrieve(paymentIntentId);
      
      if (paymentIntent.status === 'succeeded') {
        // Payment already succeeded, just update our records
        await this._updatePaymentStatus(uid, paymentIntentId, 'succeeded');
        return this._getPaymentRecord(uid, paymentIntentId);
      }

      // Confirm the payment intent
      const confirmedIntent = await this.stripe.paymentIntents.confirm(paymentIntentId);
      
      if (confirmedIntent.status === 'succeeded') {
        // Update payment status in database
        await this._updatePaymentStatus(uid, paymentIntentId, 'succeeded');
        
        // Update parking session status
        await this._updateSessionStatus(uid, sessionId, 'paid');
        
        // Update user stats
        await this._updateUserStats(uid, confirmedIntent.amount / 100);
        
        logger.info('Payment confirmed successfully', { 
          uid, 
          sessionId,
          paymentIntentId,
          amount: confirmedIntent.amount / 100
        });

        return this._getPaymentRecord(uid, paymentIntentId);
      } else {
        throw new Error(`Payment confirmation failed: ${confirmedIntent.status}`);
      }
    } catch (error) {
      logger.error('Error confirming payment', { 
        uid: paymentData.uid, 
        sessionId: paymentData.sessionId,
        paymentIntentId: paymentData.paymentIntentId,
        error: error.message 
      });
      throw new Error(`Failed to confirm payment: ${error.message}`);
    }
  }

  // Get user's payment methods
  async getUserPaymentMethods(uid) {
    try {
      // Get user profile to get Stripe customer ID
      const userProfile = await this.db.collection('users').doc(uid).get();
      if (!userProfile.exists) {
        throw new Error('User profile not found');
      }

      const user = userProfile.data();
      if (!user.stripeCustomerId) {
        return [];
      }

      // Get payment methods from Stripe
      const paymentMethods = await this.stripe.paymentMethods.list({
        customer: user.stripeCustomerId,
        type: 'card'
      });

      return paymentMethods.data.map(method => ({
        id: method.id,
        type: method.type,
        card: {
          brand: method.card.brand,
          last4: method.card.last4,
          expMonth: method.card.exp_month,
          expYear: method.card.exp_year
        },
        isDefault: method.metadata.isDefault === 'true'
      }));
    } catch (error) {
      logger.error('Error getting user payment methods', { 
        uid, 
        error: error.message 
      });
      throw new Error(`Failed to get payment methods: ${error.message}`);
    }
  }

  // Add a new payment method
  async addPaymentMethod(paymentData) {
    try {
      const { uid, paymentMethodId, setAsDefault = false } = paymentData;
      
      // Get user profile to get Stripe customer ID
      const userProfile = await this.db.collection('users').doc(uid).get();
      if (!userProfile.exists) {
        throw new Error('User profile not found');
      }

      const user = userProfile.data();
      if (!user.stripeCustomerId) {
        throw new Error('User does not have a Stripe customer account');
      }

      // Attach payment method to customer
      await this.stripe.paymentMethods.attach(paymentMethodId, {
        customer: user.stripeCustomerId
      });

      // Set as default if requested
      if (setAsDefault) {
        await this.stripe.customers.update(user.stripeCustomerId, {
          invoice_settings: {
            default_payment_method: paymentMethodId
          }
        });
      }

      // Get the payment method details
      const paymentMethod = await this.stripe.paymentMethods.retrieve(paymentMethodId);
      
      // Store in user's payment methods collection
      const methodRecord = {
        id: paymentMethod.id,
        type: paymentMethod.type,
        card: {
          brand: paymentMethod.card.brand,
          last4: paymentMethod.card.last4,
          expMonth: paymentMethod.card.exp_month,
          expYear: paymentMethod.card.exp_year
        },
        isDefault: setAsDefault,
        createdAt: admin.firestore.FieldValue.serverTimestamp()
      };

      await this.db.collection('users').doc(uid)
        .collection('paymentMethods')
        .doc(paymentMethod.id)
        .set(methodRecord);

      logger.info('Payment method added successfully', { 
        uid, 
        paymentMethodId: paymentMethod.id,
        setAsDefault 
      });

      return methodRecord;
    } catch (error) {
      logger.error('Error adding payment method', { 
        uid: paymentData.uid, 
        paymentMethodId: paymentData.paymentMethodId,
        error: error.message 
      });
      throw new Error(`Failed to add payment method: ${error.message}`);
    }
  }

  // Remove a payment method
  async removePaymentMethod(uid, paymentMethodId) {
    try {
      // Get user profile to get Stripe customer ID
      const userProfile = await this.db.collection('users').doc(uid).get();
      if (!userProfile.exists) {
        throw new Error('User profile not found');
      }

      const user = userProfile.data();
      if (!user.stripeCustomerId) {
        throw new Error('User does not have a Stripe customer account');
      }

      // Detach payment method from customer
      await this.stripe.paymentMethods.detach(paymentMethodId);

      // Remove from user's payment methods collection
      await this.db.collection('users').doc(uid)
        .collection('paymentMethods')
        .doc(paymentMethodId)
        .delete();

      logger.info('Payment method removed successfully', { 
        uid, 
        paymentMethodId 
      });
    } catch (error) {
      logger.error('Error removing payment method', { 
        uid, 
        paymentMethodId,
        error: error.message 
      });
      throw new Error(`Failed to remove payment method: ${error.message}`);
    }
  }

  // Set a payment method as default
  async setDefaultPaymentMethod(uid, paymentMethodId) {
    try {
      // Get user profile to get Stripe customer ID
      const userProfile = await this.db.collection('users').doc(uid).get();
      if (!userProfile.exists) {
        throw new Error('User profile not found');
      }

      const user = userProfile.data();
      if (!user.stripeCustomerId) {
        throw new Error('User does not have a Stripe customer account');
      }

      // Update customer's default payment method
      await this.stripe.customers.update(user.stripeCustomerId, {
        invoice_settings: {
          default_payment_method: paymentMethodId
        }
      });

      // Update all payment methods to remove default flag
      const paymentMethodsSnapshot = await this.db.collection('users').doc(uid)
        .collection('paymentMethods')
        .get();

      const batch = this.db.batch();
      paymentMethodsSnapshot.forEach(doc => {
        batch.update(doc.ref, { isDefault: false });
      });

      // Set the specified method as default
      batch.update(
        this.db.collection('users').doc(uid)
          .collection('paymentMethods')
          .doc(paymentMethodId),
        { isDefault: true }
      );

      await batch.commit();

      logger.info('Default payment method updated', { 
        uid, 
        paymentMethodId 
      });
    } catch (error) {
      logger.error('Error setting default payment method', { 
        uid, 
        paymentMethodId,
        error: error.message 
      });
      throw new Error(`Failed to set default payment method: ${error.message}`);
    }
  }

  // Get payment history
  async getPaymentHistory(uid, options = {}) {
    try {
      const { limit = 20, offset = 0, status = null } = options;
      
      let query = this.db.collection('users').doc(uid)
        .collection('payments')
        .orderBy('createdAt', 'desc');

      if (status) {
        query = query.where('status', '==', status);
      }

      const snapshot = await query.limit(limit).offset(offset).get();
      
      const payments = [];
      snapshot.forEach(doc => {
        payments.push({
          id: doc.id,
          ...doc.data()
        });
      });

      return {
        payments,
        total: payments.length,
        hasMore: payments.length === limit
      };
    } catch (error) {
      logger.error('Error getting payment history', { 
        uid, 
        error: error.message 
      });
      throw new Error(`Failed to get payment history: ${error.message}`);
    }
  }

  // Process refund
  async processRefund(uid, paymentIntentId, amount = null, reason = 'requested_by_customer') {
    try {
      // Get payment record
      const paymentDoc = await this.db.collection('users').doc(uid)
        .collection('payments')
        .doc(paymentIntentId)
        .get();

      if (!paymentDoc.exists) {
        throw new Error('Payment not found');
      }

      const payment = paymentDoc.data();
      
      // Create refund in Stripe
      const refundData = {
        payment_intent: paymentIntentId,
        reason
      };

      if (amount) {
        refundData.amount = Math.round(amount * 100); // Convert to cents
      }

      const refund = await this.stripe.refunds.create(refundData);

      // Update payment record
      await this.db.collection('users').doc(uid)
        .collection('payments')
        .doc(paymentIntentId)
        .update({
          status: 'refunded',
          refundId: refund.id,
          refundAmount: amount || payment.amount,
          refundReason: reason,
          updatedAt: admin.firestore.FieldValue.serverTimestamp()
        });

      logger.info('Refund processed successfully', { 
        uid, 
        paymentIntentId,
        refundId: refund.id,
        amount: amount || payment.amount
      });

      return refund;
    } catch (error) {
      logger.error('Error processing refund', { 
        uid, 
        paymentIntentId,
        error: error.message 
      });
      throw new Error(`Failed to process refund: ${error.message}`);
    }
  }

  // Update payment status in database
  async _updatePaymentStatus(uid, paymentIntentId, status) {
    try {
      await this.db.collection('users').doc(uid)
        .collection('payments')
        .doc(paymentIntentId)
        .update({
          status,
          updatedAt: admin.firestore.FieldValue.serverTimestamp()
        });

      // Also update in global payments collection
      await this.db.collection('payments')
        .doc(paymentIntentId)
        .update({
          status,
          updatedAt: admin.firestore.FieldValue.serverTimestamp()
        });
    } catch (error) {
      logger.error('Error updating payment status', { 
        uid, 
        paymentIntentId,
        status,
        error: error.message 
      });
      throw error;
    }
  }

  // Update session status
  async _updateSessionStatus(uid, sessionId, status) {
    try {
      await this.db.collection('users').doc(uid)
        .collection('parkingSessions')
        .doc(sessionId)
        .update({
          status,
          updatedAt: admin.firestore.FieldValue.serverTimestamp()
        });
    } catch (error) {
      logger.error('Error updating session status', { 
        uid, 
        sessionId,
        status,
        error: error.message 
      });
      throw error;
    }
  }

  // Update user stats
  async _updateUserStats(uid, amount) {
    try {
      await this.db.collection('users').doc(uid).update({
        'stats.totalSpent': admin.firestore.FieldValue.increment(amount),
        'stats.paymentsCompleted': admin.firestore.FieldValue.increment(1),
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      });
    } catch (error) {
      logger.error('Error updating user stats', { 
        uid, 
        amount,
        error: error.message 
      });
      throw error;
    }
  }

  // Get payment record
  async _getPaymentRecord(uid, paymentIntentId) {
    try {
      const doc = await this.db.collection('users').doc(uid)
        .collection('payments')
        .doc(paymentIntentId)
        .get();

      if (!doc.exists) {
        throw new Error('Payment record not found');
      }

      return {
        id: doc.id,
        ...doc.data()
      };
    } catch (error) {
      logger.error('Error getting payment record', { 
        uid, 
        paymentIntentId,
        error: error.message 
      });
      throw error;
    }
  }
}

export default new PaymentService();
