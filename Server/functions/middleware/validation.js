import Joi from 'joi';

// Validate request data against a Joi schema
function validateRequest(data, schema) {
  const { error, value } = schema.validate(data, {
    abortEarly: false,
    stripUnknown: true,
    allowUnknown: false
  });

  if (error) {
    const validationErrors = error.details.map(detail => ({
      field: detail.path.join('.'),
      message: detail.message,
      type: detail.type
    }));

    return {
      error: {
        message: 'Validation failed',
        details: validationErrors
      }
    };
  }

  return { value };
}

// Common validation schemas
const commonSchemas = {
  uid: Joi.string().required().min(1).max(128),
  email: Joi.string().email().required().max(255),
  timestamp: Joi.date().iso().required(),
  pagination: Joi.object({
    limit: Joi.number().integer().min(1).max(100).default(20),
    offset: Joi.number().integer().min(0).default(0)
  })
};

// User validation schemas
const userSchemas = {
  getProfile: Joi.object({
    uid: commonSchemas.uid
  }),

  updateProfile: Joi.object({
    uid: commonSchemas.uid,
    updates: Joi.object({
      displayName: Joi.string().max(100).optional(),
      photoURL: Joi.string().uri().max(500).optional(),
      phoneNumber: Joi.string().max(20).optional(),
      preferences: Joi.object({
        notifications: Joi.boolean().optional(),
        locationServices: Joi.boolean().optional(),
        darkMode: Joi.boolean().optional(),
        language: Joi.string().valid('en', 'es', 'fr', 'de', 'zh').optional()
      }).optional()
    }).min(1).required()
  }),

  addVehicle: Joi.object({
    uid: commonSchemas.uid,
    vehicleData: Joi.object({
      make: Joi.string().required().max(50),
      model: Joi.string().required().max(50),
      year: Joi.number().integer().min(1900).max(new Date().getFullYear() + 1).required(),
      color: Joi.string().required().max(30),
      licensePlate: Joi.string().required().max(20),
      vin: Joi.string().max(17).optional()
    }).required()
  }),

  addPermit: Joi.object({
    uid: commonSchemas.uid,
    permitData: Joi.object({
      permitNumber: Joi.string().required().max(50),
      type: Joi.string().required().max(50),
      organization: Joi.string().required().max(100),
      validFrom: Joi.date().iso().required(),
      validUntil: Joi.date().iso().min(Joi.ref('validFrom')).required(),
      restrictions: Joi.array().items(Joi.string().max(100)).optional()
    }).required()
  })
};

// Parking validation schemas
const parkingSchemas = {
  startSession: Joi.object({
    uid: commonSchemas.uid,
    location: Joi.object({
      latitude: Joi.number().min(-90).max(90).required(),
      longitude: Joi.number().min(-180).max(180).required(),
      address: Joi.string().max(500).optional(),
      name: Joi.string().max(200).optional(),
      floor: Joi.string().max(50).optional(),
      spot: Joi.string().max(50).optional()
    }).required(),
    rate: Joi.number().positive().max(1000).required(),
    organization: Joi.string().max(100).required()
  }),

  endSession: Joi.object({
    uid: commonSchemas.uid,
    sessionId: Joi.string().required().max(128)
  }),

  getSession: Joi.object({
    uid: commonSchemas.uid,
    sessionId: Joi.string().required().max(128)
  }),

  getHistory: Joi.object({
    uid: commonSchemas.uid,
    limit: Joi.number().integer().min(1).max(100).default(20),
    offset: Joi.number().integer().min(0).default(0),
    status: Joi.string().valid('active', 'completed', 'cancelled').optional()
  }),

  extendSession: Joi.object({
    uid: commonSchemas.uid,
    sessionId: Joi.string().required().max(128),
    extensionMinutes: Joi.number().integer().min(1).max(1440).required() // Max 24 hours
  }),

  cancelSession: Joi.object({
    uid: commonSchemas.uid,
    sessionId: Joi.string().required().max(128)
  }),

  findSpots: Joi.object({
    location: Joi.object({
      latitude: Joi.number().min(-90).max(90).required(),
      longitude: Joi.number().min(-180).max(180).required()
    }).required(),
    radius: Joi.number().integer().min(100).max(10000).default(1000), // 100m to 10km
    maxSpots: Joi.number().integer().min(1).max(50).default(20)
  }),

  reserveSpot: Joi.object({
    uid: commonSchemas.uid,
    spotId: Joi.string().required().max(128),
    duration: Joi.number().integer().min(15).max(1440).default(60) // 15min to 24 hours
  })
};

// Payment validation schemas
const paymentSchemas = {
  createIntent: Joi.object({
    uid: commonSchemas.uid,
    sessionId: Joi.string().required().max(128),
    paymentMethodId: Joi.string().required().max(128)
  }),

  confirmPayment: Joi.object({
    uid: commonSchemas.uid,
    sessionId: Joi.string().required().max(128),
    paymentIntentId: Joi.string().required().max(128)
  }),

  getMethods: Joi.object({
    uid: commonSchemas.uid
  }),

  addMethod: Joi.object({
    uid: commonSchemas.uid,
    paymentMethodId: Joi.string().required().max(128),
    setAsDefault: Joi.boolean().default(false)
  }),

  removeMethod: Joi.object({
    uid: commonSchemas.uid,
    paymentMethodId: Joi.string().required().max(128)
  }),

  setDefault: Joi.object({
    uid: commonSchemas.uid,
    paymentMethodId: Joi.string().required().max(128)
  }),

  getHistory: Joi.object({
    uid: commonSchemas.uid,
    limit: Joi.number().integer().min(1).max(100).default(20),
    offset: Joi.number().integer().min(0).default(0),
    status: Joi.string().valid('pending', 'succeeded', 'failed', 'refunded').optional()
  }),

  processRefund: Joi.object({
    uid: commonSchemas.uid,
    paymentIntentId: Joi.string().required().max(128),
    amount: Joi.number().positive().max(10000).optional(), // Max $10,000
    reason: Joi.string().valid(
      'requested_by_customer',
      'duplicate',
      'fraudulent',
      'requested_by_customer'
    ).default('requested_by_customer')
  })
};

// Notification validation schemas
const notificationSchemas = {
  sendNotification: Joi.object({
    uid: commonSchemas.uid,
    type: Joi.string().valid(
      'welcome',
      'session_complete',
      'payment_success',
      'payment_failure',
      'parking_reminder',
      'promotional'
    ).required(),
    title: Joi.string().required().max(100),
    body: Joi.string().required().max(500),
    data: Joi.object().optional()
  }),

  bulkNotification: Joi.object({
    userIds: Joi.array().items(commonSchemas.uid).min(1).max(1000).required(),
    title: Joi.string().required().max(100),
    body: Joi.string().required().max(500),
    data: Joi.object().optional()
  }),

  updateToken: Joi.object({
    uid: commonSchemas.uid,
    fcmToken: Joi.string().required().max(500)
  }),

  getHistory: Joi.object({
    uid: commonSchemas.uid,
    limit: Joi.number().integer().min(1).max(100).default(20),
    offset: Joi.number().integer().min(0).default(0),
    type: Joi.string().valid(
      'welcome',
      'session_complete',
      'payment_success',
      'payment_failure',
      'parking_reminder',
      'promotional',
      'bulk'
    ).optional()
  })
};

// Analytics validation schemas
const analyticsSchemas = {
  getUserAnalytics: Joi.object({
    uid: commonSchemas.uid,
    timeRange: Joi.string().valid('7d', '30d', '90d').default('30d')
  }),

  getParkingAnalytics: Joi.object({
    uid: commonSchemas.uid,
    timeRange: Joi.string().valid('7d', '30d', '90d').default('30d')
  }),

  getPaymentAnalytics: Joi.object({
    uid: commonSchemas.uid,
    timeRange: Joi.string().valid('7d', '30d', '90d').default('30d')
  })
};

export {
  validateRequest,
  commonSchemas,
  userSchemas,
  parkingSchemas,
  paymentSchemas,
  notificationSchemas,
  analyticsSchemas
};
