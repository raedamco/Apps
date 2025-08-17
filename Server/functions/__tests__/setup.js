// Test environment setup
import { jest } from '@jest/globals';

// Set test environment variables
process.env.NODE_ENV = 'test';
process.env.FIREBASE_PROJECT_ID = 'test-project';
process.env.FIREBASE_STORAGE_BUCKET = 'test-project.appspot.com';
process.env.FIREBASE_DATABASE_URL = 'https://test-project.firebaseio.com';
process.env.STRIPE_SECRET_KEY = 'sk_test_1234567890';
process.env.LOG_LEVEL = 'error';

// Global test timeout
jest.setTimeout(15000);

// Mock console methods in tests
global.console = {
  ...console,
  log: jest.fn(),
  debug: jest.fn(),
  info: jest.fn(),
  warn: jest.fn(),
  error: jest.fn()
};

// Mock Firebase Admin
jest.mock('firebase-admin', () => ({
  initializeApp: jest.fn(),
  getApps: jest.fn(() => []),
  getFirestore: jest.fn(() => ({
    collection: jest.fn(() => ({
      doc: jest.fn(() => ({
        get: jest.fn(),
        set: jest.fn(),
        update: jest.fn(),
        delete: jest.fn()
      })),
      where: jest.fn(() => ({
        orderBy: jest.fn(() => ({
          limit: jest.fn(() => ({
            offset: jest.fn(() => ({
              get: jest.fn()
            }))
          }))
        }))
      }))
    })),
    batch: jest.fn(() => ({
      set: jest.fn(),
      update: jest.fn(),
      delete: jest.fn(),
      commit: jest.fn()
    }))
  })),
  auth: jest.fn(() => ({
    verifyIdToken: jest.fn(),
    createCustomToken: jest.fn(),
    getUser: jest.fn()
  })),
  firestore: {
    FieldValue: {
      serverTimestamp: jest.fn(() => new Date()),
      increment: jest.fn((value) => ({ _increment: value }))
    }
  }
}));

// Mock Stripe
jest.mock('stripe', () => {
  return jest.fn().mockImplementation(() => ({
    customers: {
      create: jest.fn(),
      retrieve: jest.fn(),
      update: jest.fn(),
      del: jest.fn()
    },
    paymentIntents: {
      create: jest.fn(),
      retrieve: jest.fn(),
      confirm: jest.fn(),
      cancel: jest.fn()
    },
    paymentMethods: {
      create: jest.fn(),
      retrieve: jest.fn(),
      update: jest.fn(),
      detach: jest.fn()
    }
  }));
});

// Mock Winston logger
jest.mock('../utils/logger.js', () => ({
  logger: {
    info: jest.fn(),
    warn: jest.fn(),
    error: jest.fn(),
    debug: jest.fn()
  }
}));

// Mock Redis
jest.mock('ioredis', () => {
  return jest.fn().mockImplementation(() => ({
    get: jest.fn(),
    set: jest.fn(),
    del: jest.fn(),
    expire: jest.fn(),
    exists: jest.fn(),
    incr: jest.fn(),
    decr: jest.fn()
  }));
});

// Mock Node Cache
jest.mock('node-cache', () => {
  return jest.fn().mockImplementation(() => ({
    get: jest.fn(),
    set: jest.fn(),
    del: jest.fn(),
    flushAll: jest.fn(),
    keys: jest.fn(() => [])
  }));
});

// Mock Twilio
jest.mock('twilio', () => ({
  twiml: {
    VoiceResponse: jest.fn(() => ({
      say: jest.fn(() => ({
        play: jest.fn()
      }))
    }))
  }
}));

// Mock Nodemailer
jest.mock('nodemailer', () => ({
  createTransport: jest.fn(() => ({
    sendMail: jest.fn()
  }))
}));

// Mock Multer
jest.mock('multer', () => {
  const multer = jest.fn(() => {
    const middleware = jest.fn((req, res, next) => next());
    middleware.single = jest.fn(() => middleware);
    middleware.array = jest.fn(() => middleware);
    middleware.fields = jest.fn(() => middleware);
    middleware.none = jest.fn(() => middleware);
    middleware.any = jest.fn(() => middleware);
    return middleware;
  });
  return multer;
});

// Mock Sharp
jest.mock('sharp', () => {
  return jest.fn(() => ({
    resize: jest.fn(() => ({
      jpeg: jest.fn(() => ({
        toBuffer: jest.fn()
      })),
      png: jest.fn(() => ({
        toBuffer: jest.fn()
      }))
    })),
    metadata: jest.fn(() => Promise.resolve({ width: 100, height: 100 }))
  }));
});

// Mock compression
jest.mock('compression', () => jest.fn(() => (req, res, next) => next()));

// Mock helmet
jest.mock('helmet', () => jest.fn(() => (req, res, next) => next()));

// Mock rate limiting
jest.mock('express-rate-limit', () => {
  return jest.fn(() => ({
    apply: jest.fn((req, res) => Promise.resolve())
  }));
});

// Mock CORS
jest.mock('cors', () => jest.fn(() => (req, res, next) => next()));

// Mock Morgan
jest.mock('morgan', () => jest.fn(() => (req, res, next) => next()));

// Mock Joi
jest.mock('joi', () => ({
  string: jest.fn(() => ({
    required: jest.fn(() => ({
      min: jest.fn(() => ({
        max: jest.fn(() => ({
          email: jest.fn(() => ({
            uri: jest.fn(() => ({
              valid: jest.fn(() => ({
                validate: jest.fn()
              }))
            }))
          }))
        }))
      }))
    })),
    valid: jest.fn(() => ({
      validate: jest.fn()
    })),
    email: jest.fn(() => ({
      required: jest.fn(() => ({
        max: jest.fn(() => ({
          validate: jest.fn()
        }))
      }))
    })),
    uri: jest.fn(() => ({
      max: jest.fn(() => ({
        validate: jest.fn()
      }))
    }))
  })),
  number: jest.fn(() => ({
    integer: jest.fn(() => ({
      min: jest.fn(() => ({
        max: jest.fn(() => ({
          positive: jest.fn(() => ({
            required: jest.fn(() => ({
              validate: jest.fn()
            }))
          }))
        }))
      }))
    })),
    min: jest.fn(() => ({
      max: jest.fn(() => ({
        positive: jest.fn(() => ({
          max: jest.fn(() => ({
            validate: jest.fn()
          }))
        }))
      }))
    }))
  })),
  boolean: jest.fn(() => ({
    optional: jest.fn(() => ({
      validate: jest.fn()
    }))
  })),
  date: jest.fn(() => ({
    iso: jest.fn(() => ({
      required: jest.fn(() => ({
        validate: jest.fn()
      }))
    })),
    min: jest.fn(() => ({
      required: jest.fn(() => ({
        validate: jest.fn()
      }))
    }))
  })),
  array: jest.fn(() => ({
    items: jest.fn(() => ({
      min: jest.fn(() => ({
        max: jest.fn(() => ({
          validate: jest.fn()
        }))
      }))
    }))
  })),
  object: jest.fn(() => ({
    keys: jest.fn(() => ({
      validate: jest.fn()
    })),
    min: jest.fn(() => ({
      required: jest.fn(() => ({
        validate: jest.fn()
      }))
    }))
  })),
  ref: jest.fn(() => 'ref')
}));

// Mock bcryptjs
jest.mock('bcryptjs', () => ({
  hash: jest.fn(() => Promise.resolve('hashedPassword')),
  compare: jest.fn(() => Promise.resolve(true)),
  genSalt: jest.fn(() => Promise.resolve('salt'))
}));

// Mock jsonwebtoken
jest.mock('jsonwebtoken', () => ({
  sign: jest.fn(() => 'mock.jwt.token'),
  verify: jest.fn(() => ({ userId: 'mock-user-id' })),
  decode: jest.fn(() => ({ userId: 'mock-user-id' }))
}));

// Mock uuid
jest.mock('uuid', () => ({
  v4: jest.fn(() => 'mock-uuid-1234'),
  validate: jest.fn(() => true)
}));

// Mock nanoid
jest.mock('nanoid', () => ({
  nanoid: jest.fn(() => 'mock-nanoid-1234')
}));

// Mock date-fns
jest.mock('date-fns', () => ({
  format: jest.fn((date) => date.toISOString()),
  parseISO: jest.fn((date) => new Date(date)),
  add: jest.fn((date, duration) => new Date(date.getTime() + duration)),
  differenceInMinutes: jest.fn(() => 30),
  differenceInHours: jest.fn(() => 2)
}));

// Mock moment
jest.mock('moment', () => {
  const moment = jest.fn((date) => ({
    format: jest.fn(() => '2024-01-01 12:00:00'),
    add: jest.fn(() => moment()),
    subtract: jest.fn(() => moment()),
    diff: jest.fn(() => 30),
    toDate: jest.fn(() => new Date()),
    isValid: jest.fn(() => true)
  }));
  moment.utc = jest.fn(() => moment());
  moment.now = jest.fn(() => Date.now());
  return moment;
});

// Mock lodash
jest.mock('lodash', () => ({
  get: jest.fn((obj, path, defaultValue) => defaultValue || 'mock-value'),
  set: jest.fn(),
  merge: jest.fn(),
  cloneDeep: jest.fn((obj) => obj),
  debounce: jest.fn((fn) => fn),
  throttle: jest.fn((fn) => fn)
}));

// Mock ramda
jest.mock('ramda', () => ({
  prop: jest.fn((key) => (obj) => obj[key]),
  path: jest.fn((path) => (obj) => obj[path[0]]),
  compose: jest.fn((...fns) => (x) => fns.reduceRight((acc, fn) => fn(acc), x)),
  pipe: jest.fn((...fns) => (x) => fns.reduce((acc, fn) => fn(acc), x))
}));

// Global test utilities
global.testUtils = {
  createMockRequest: (overrides = {}) => ({
    method: 'GET',
    path: '/test',
    url: '/test',
    headers: {},
    query: {},
    params: {},
    body: {},
    ip: '127.0.0.1',
    get: jest.fn(),
    ...overrides
  }),
  
  createMockResponse: (overrides = {}) => {
    const res = {
      status: jest.fn(() => res),
      json: jest.fn(() => res),
      send: jest.fn(() => res),
      set: jest.fn(() => res),
      get: jest.fn(),
      ...overrides
    };
    return res;
  },
  
  createMockNext: () => jest.fn(),
  
  createMockUser: (overrides = {}) => ({
    uid: 'test-user-123',
    email: 'test@example.com',
    displayName: 'Test User',
    photoURL: null,
    phoneNumber: null,
    emailVerified: false,
    ...overrides
  }),
  
  createMockParkingSession: (overrides = {}) => ({
    id: 'session-123',
    uid: 'test-user-123',
    status: 'active',
    startTime: new Date(),
    location: {
      latitude: 40.7128,
      longitude: -74.0060,
      address: '123 Test St, Test City, TS 12345'
    },
    rate: 2.50,
    organization: 'Test Parking',
    ...overrides
  }),
  
  createMockPaymentIntent: (overrides = {}) => ({
    id: 'pi_1234567890',
    amount: 2500,
    currency: 'usd',
    status: 'requires_payment_method',
    client_secret: 'pi_1234567890_secret_abcdef',
    ...overrides
  })
};

// Clean up after each test
afterEach(() => {
  jest.clearAllMocks();
  jest.clearAllTimers();
});

// Clean up after all tests
afterAll(() => {
  jest.restoreAllMocks();
});
