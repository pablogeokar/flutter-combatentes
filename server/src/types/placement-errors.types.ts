/**
 * Server-side error handling types for placement operations
 */

export enum PlacementErrorType {
  // Validation errors
  INVALID_POSITION = "INVALID_POSITION",
  PIECE_NOT_AVAILABLE = "PIECE_NOT_AVAILABLE",
  INCOMPLETE_PLACEMENT = "INCOMPLETE_PLACEMENT",
  INVALID_PIECE_COMPOSITION = "INVALID_PIECE_COMPOSITION",

  // Game state errors
  INVALID_GAME_STATE = "INVALID_GAME_STATE",
  PLAYER_NOT_FOUND = "PLAYER_NOT_FOUND",
  GAME_NOT_FOUND = "GAME_NOT_FOUND",
  WRONG_GAME_PHASE = "WRONG_GAME_PHASE",

  // Authorization errors
  UNAUTHORIZED_OPERATION = "UNAUTHORIZED_OPERATION",
  PLAYER_NOT_IN_GAME = "PLAYER_NOT_IN_GAME",

  // Rate limiting
  RATE_LIMIT_EXCEEDED = "RATE_LIMIT_EXCEEDED",
  TOO_MANY_REQUESTS = "TOO_MANY_REQUESTS",

  // Server errors
  INTERNAL_SERVER_ERROR = "INTERNAL_SERVER_ERROR",
  DATABASE_ERROR = "DATABASE_ERROR",
  NETWORK_ERROR = "NETWORK_ERROR",
}

export interface PlacementErrorDetails {
  type: PlacementErrorType;
  message: string;
  userMessage: string;
  code: string;
  context?: Record<string, any>;
  timestamp: string;
  requestId?: string;
}

export interface PlacementValidationResult {
  isValid: boolean;
  error?: PlacementErrorDetails;
  warnings?: string[];
}

export interface PlacementOperationResult<T = any> {
  success: boolean;
  data?: T;
  error?: PlacementErrorDetails;
  warnings?: string[];
}

export interface RateLimitInfo {
  playerId: string;
  operationType: string;
  count: number;
  windowStart: number;
  limit: number;
  windowDuration: number;
}

export interface ValidationContext {
  gameId: string;
  playerId: string;
  operationType: string;
  timestamp: number;
  requestId?: string;
}

/**
 * Standard error codes for client-server communication
 */
export const PLACEMENT_ERROR_CODES = {
  // Validation (4000-4099)
  INVALID_POSITION: "P4001",
  PIECE_NOT_AVAILABLE: "P4002",
  INCOMPLETE_PLACEMENT: "P4003",
  INVALID_PIECE_COMPOSITION: "P4004",
  POSITION_OUT_OF_BOUNDS: "P4005",
  POSITION_OCCUPIED: "P4006",
  INVALID_PIECE_TYPE: "P4007",

  // Game State (4100-4199)
  INVALID_GAME_STATE: "P4101",
  PLAYER_NOT_FOUND: "P4102",
  GAME_NOT_FOUND: "P4103",
  WRONG_GAME_PHASE: "P4104",
  GAME_ALREADY_STARTED: "P4105",

  // Authorization (4200-4299)
  UNAUTHORIZED_OPERATION: "P4201",
  PLAYER_NOT_IN_GAME: "P4202",
  INVALID_PLAYER_TEAM: "P4203",

  // Rate Limiting (4300-4399)
  RATE_LIMIT_EXCEEDED: "P4301",
  TOO_MANY_REQUESTS: "P4302",

  // Server Errors (5000-5099)
  INTERNAL_SERVER_ERROR: "P5001",
  DATABASE_ERROR: "P5002",
  NETWORK_ERROR: "P5003",
  TIMEOUT_ERROR: "P5004",
} as const;

/**
 * Rate limiting configuration
 */
export interface RateLimitConfig {
  maxRequestsPerWindow: number;
  windowDurationMs: number;
  operationType: string;
}

export const DEFAULT_RATE_LIMITS: Record<string, RateLimitConfig> = {
  PIECE_PLACEMENT: {
    maxRequestsPerWindow: 100,
    windowDurationMs: 60000, // 1 minute
    operationType: "PIECE_PLACEMENT",
  },
  PIECE_MOVEMENT: {
    maxRequestsPerWindow: 200,
    windowDurationMs: 60000,
    operationType: "PIECE_MOVEMENT",
  },
  PLACEMENT_CONFIRMATION: {
    maxRequestsPerWindow: 10,
    windowDurationMs: 60000,
    operationType: "PLACEMENT_CONFIRMATION",
  },
} as const;

/**
 * Logging levels for placement operations
 */
export enum LogLevel {
  DEBUG = "DEBUG",
  INFO = "INFO",
  WARN = "WARN",
  ERROR = "ERROR",
  CRITICAL = "CRITICAL",
}

export interface PlacementLogEntry {
  level: LogLevel;
  message: string;
  context: ValidationContext;
  error?: PlacementErrorDetails;
  timestamp: string;
  duration?: number;
}
