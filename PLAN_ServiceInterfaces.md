# Service Interfaces Plan

## 1. Overview
This document defines the REST API contracts between all services, standardized error handling, and data formats to ensure seamless inter-service communication with minimal coordination requirements.

## 2. API Design Principles

### 2.1 RESTful Standards
- HTTP methods follow REST conventions (GET, POST, PUT, DELETE)
- Status codes provide meaningful information
- JSON request/response bodies with consistent structure
- Stateless operations with no session dependencies

### 2.2 Error Handling Philosophy
- Graceful failure with structured error responses
- Full debug information in development environments
- Consistent error format across all services
- HTTP status codes align with error types

### 2.3 Data Format Standards
- ISO 8601 timestamps for all time data
- UTF-8 encoding for all text content
- Consistent field naming (snake_case)
- Optional fields clearly documented

## 3. Service API Contracts

### 3.1 Categorizer Service (Port 8002)

#### 3.1.1 Categorize Prompt
**Endpoint**: `POST /categorize`
**Purpose**: Analyze and categorize instructions within a prompt

**Request Format**:
```json
{
  "prompt": "string (required) - The prompt text to categorize",
  "options": {
    "include_confidence": "boolean (optional, default: true) - Include confidence scores",
    "detailed_analysis": "boolean (optional, default: false) - Include detailed breakdown"
  },
  "request_id": "string (optional) - UUID for request tracing"
}
```

**Success Response** (HTTP 200):
```json
{
  "success": true,
  "request_id": "string - UUID for request tracing",
  "timestamp": "string - ISO 8601 timestamp",
  "result": {
    "categories": [
      {
        "name": "string - Category name (e.g., 'code_generation', 'harmful_content')",
        "confidence": "float - Confidence score 0.0-1.0",
        "evidence": "string - Text excerpt supporting categorization"
      }
    ],
    "primary_category": "string - Highest confidence category",
    "overall_confidence": "float - Overall categorization confidence",
    "analysis_metadata": {
      "processing_time_ms": "integer - Processing time in milliseconds",
      "model_used": "string - LLM model identifier",
      "prompt_length": "integer - Character count of input prompt"
    }
  }
}
```

**Error Response** (HTTP 4xx/5xx):
```json
{
  "error": true,
  "request_id": "string - UUID for request tracing",
  "timestamp": "string - ISO 8601 timestamp",
  "message": "string - Human-readable error description",
  "error_code": "string - Machine-readable error code",
  "debug_info": {
    "service": "categorizer",
    "exception_type": "string - Exception class name",
    "exception_details": "string - Exception message",
    "traceback": "string - Full traceback (development only)"
  }
}
```

#### 3.1.2 Health Check
**Endpoint**: `GET /health`
**Purpose**: Service health and readiness check

**Success Response** (HTTP 200):
```json
{
  "status": "healthy",
  "timestamp": "string - ISO 8601 timestamp",
  "version": "string - Service version",
  "dependencies": {
    "llm_backend": "healthy|degraded|unhealthy",
    "configuration": "healthy|unhealthy"
  }
}
```

---

### 3.2 Filtering Engine Service (Port 8003)

#### 3.2.1 Evaluate Prompt
**Endpoint**: `POST /evaluate`
**Purpose**: Evaluate categorized prompt against filtering criteria

**Request Format**:
```json
{
  "categorization_result": {
    "categories": [
      {
        "name": "string - Category name",
        "confidence": "float - Confidence score 0.0-1.0",
        "evidence": "string - Supporting evidence"
      }
    ],
    "primary_category": "string - Primary category",
    "overall_confidence": "float - Overall confidence"
  },
  "original_prompt": "string (optional) - Original prompt text for logging",
  "evaluation_options": {
    "strict_mode": "boolean (optional, default: false) - Use stricter filtering",
    "explain_decision": "boolean (optional, default: true) - Include reasoning"
  },
  "request_id": "string (optional) - UUID for request tracing"
}
```

**Success Response** (HTTP 200):
```json
{
  "success": true,
  "request_id": "string - UUID for request tracing",
  "timestamp": "string - ISO 8601 timestamp",
  "result": {
    "decision": "allow|block|review",
    "confidence": "float - Decision confidence 0.0-1.0",
    "reasoning": {
      "primary_reason": "string - Main reason for decision",
      "triggered_rules": [
        {
          "rule_name": "string - Name of triggered filtering rule",
          "rule_type": "string - Type of rule (category_block, confidence_threshold, etc.)",
          "match_details": "string - Details of why rule was triggered"
        }
      ],
      "risk_factors": [
        {
          "factor": "string - Risk factor name",
          "severity": "low|medium|high",
          "description": "string - Risk factor description"
        }
      ]
    },
    "metadata": {
      "processing_time_ms": "integer - Processing time",
      "rules_evaluated": "integer - Number of rules checked",
      "config_version": "string - Configuration version used"
    }
  }
}
```

#### 3.2.2 Health Check
**Endpoint**: `GET /health`
**Purpose**: Service health and dependency status

**Success Response** (HTTP 200):
```json
{
  "status": "healthy",
  "timestamp": "string - ISO 8601 timestamp", 
  "version": "string - Service version",
  "dependencies": {
    "categorizer_service": "healthy|degraded|unhealthy",
    "configuration": "healthy|unhealthy"
  }
}
```

---

### 3.3 Prompt Proxy Service (Port 8001)

#### 3.3.1 OpenAI Chat Completions (Main Interface)
**Endpoint**: `POST /v1/chat/completions`
**Purpose**: OpenAI-compatible chat completions with filtering

**Request Format** (OpenAI-compatible):
```json
{
  "model": "string (required) - Model identifier",
  "messages": [
    {
      "role": "system|user|assistant",
      "content": "string - Message content"
    }
  ],
  "temperature": "float (optional) - Sampling temperature",
  "max_tokens": "integer (optional) - Maximum response tokens",
  "stream": "boolean (optional, default: false) - Stream response",
  "filtering_options": {
    "bypass_filter": "boolean (optional, default: false) - Skip filtering pipeline",
    "strict_mode": "boolean (optional, default: false) - Use strict filtering",
    "include_filter_metadata": "boolean (optional, default: false) - Include filtering details"
  }
}
```

**Success Response** (HTTP 200, OpenAI-compatible):
```json
{
  "id": "string - Request ID",
  "object": "chat.completion",
  "created": "integer - Unix timestamp",
  "model": "string - Model used",
  "choices": [
    {
      "index": "integer - Choice index",
      "message": {
        "role": "assistant",
        "content": "string - Response content"
      },
      "finish_reason": "stop|length|filter_blocked"
    }
  ],
  "usage": {
    "prompt_tokens": "integer - Input token count",
    "completion_tokens": "integer - Output token count", 
    "total_tokens": "integer - Total token count"
  },
  "filter_metadata": {
    "decision": "allow|block",
    "processing_time_ms": "integer - Filter processing time",
    "categorization": "object - Categorization result (if requested)",
    "filtering_result": "object - Filtering evaluation (if requested)"
  }
}
```

**Blocked Response** (HTTP 200, content blocked):
```json
{
  "id": "string - Request ID",
  "object": "chat.completion",
  "created": "integer - Unix timestamp",
  "model": "string - Model used",
  "choices": [
    {
      "index": 0,
      "message": {
        "role": "assistant",
        "content": "I cannot process this request as it contains content that violates our usage policies."
      },
      "finish_reason": "filter_blocked"
    }
  ],
  "usage": {
    "prompt_tokens": "integer - Input token count",
    "completion_tokens": 0,
    "total_tokens": "integer - Total token count"
  },
  "filter_metadata": {
    "decision": "block",
    "reasoning": "string - Explanation for blocking",
    "processing_time_ms": "integer - Filter processing time"
  }
}
```

#### 3.3.2 Health Check
**Endpoint**: `GET /health`
**Purpose**: Complete pipeline health check

**Success Response** (HTTP 200):
```json
{
  "status": "healthy",
  "timestamp": "string - ISO 8601 timestamp",
  "version": "string - Service version",
  "dependencies": {
    "categorizer_service": "healthy|degraded|unhealthy",
    "filtering_service": "healthy|degraded|unhealthy", 
    "llm_backend": "healthy|degraded|unhealthy",
    "configuration": "healthy|unhealthy"
  },
  "pipeline_status": {
    "bypass_mode_available": "boolean - Can operate without filtering",
    "full_pipeline_available": "boolean - Complete filtering pipeline functional"
  }
}
```

---

### 3.4 Test Prompt Generator Service (Port 8004)

#### 3.4.1 Generate Test Prompt
**Endpoint**: `POST /generate`
**Purpose**: Generate test prompts with specified characteristics

**Request Format**:
```json
{
  "generation_parameters": {
    "complexity_level": "simple|medium|complex|adversarial",
    "target_categories": ["string - Desired categories to target"],
    "prompt_type": "instruction|conversation|creative|technical",
    "length_preference": "short|medium|long"
  },
  "count": "integer (optional, default: 1) - Number of prompts to generate",
  "test_options": {
    "test_through_pipeline": "boolean (optional, default: false) - Test generated prompts",
    "include_expected_results": "boolean (optional, default: true) - Include expected outcomes"
  },
  "request_id": "string (optional) - UUID for request tracing"
}
```

**Success Response** (HTTP 200):
```json
{
  "success": true,
  "request_id": "string - UUID for request tracing",
  "timestamp": "string - ISO 8601 timestamp",
  "result": {
    "generated_prompts": [
      {
        "prompt_id": "string - Unique identifier for this prompt",
        "prompt_text": "string - Generated prompt content",
        "metadata": {
          "complexity_level": "string - Actual complexity achieved",
          "target_categories": ["string - Categories this prompt should trigger"],
          "generation_parameters": "object - Parameters used for generation",
          "expected_outcome": {
            "should_be_blocked": "boolean - Expected filtering decision",
            "expected_categories": ["string - Expected categorization results"],
            "confidence_range": "string - Expected confidence range"
          }
        },
        "pipeline_test_result": {
          "tested": "boolean - Whether prompt was tested through pipeline",
          "actual_outcome": "object - Actual results from pipeline (if tested)",
          "matches_expected": "boolean - Whether results match expectations"
        }
      }
    ],
    "generation_metadata": {
      "processing_time_ms": "integer - Time to generate prompts",
      "model_used": "string - LLM model for generation",
      "success_rate": "float - Percentage of successful generations"
    }
  }
}
```

#### 3.4.2 Health Check
**Endpoint**: `GET /health`
**Purpose**: Service and pipeline testing capability status

**Success Response** (HTTP 200):
```json
{
  "status": "healthy",
  "timestamp": "string - ISO 8601 timestamp",
  "version": "string - Service version",
  "dependencies": {
    "llm_backend": "healthy|degraded|unhealthy",
    "proxy_service": "healthy|degraded|unhealthy",
    "configuration": "healthy|unhealthy"
  },
  "capabilities": {
    "prompt_generation": "available|unavailable",
    "pipeline_testing": "available|unavailable"
  }
}
```

## 4. Standardized Error Handling

### 4.1 HTTP Status Code Usage
- **200 OK**: Successful operation
- **400 Bad Request**: Invalid request format or parameters
- **401 Unauthorized**: Authentication required (future use)
- **403 Forbidden**: Request forbidden (future use)
- **404 Not Found**: Endpoint not found
- **422 Unprocessable Entity**: Valid format but business logic error
- **429 Too Many Requests**: Rate limiting (future use)
- **500 Internal Server Error**: Unexpected server error
- **502 Bad Gateway**: Downstream service error
- **503 Service Unavailable**: Service overloaded or maintenance
- **504 Gateway Timeout**: Downstream service timeout

### 4.2 Standard Error Response Format
All services use this consistent error format:
```json
{
  "error": true,
  "request_id": "string - UUID for request tracing",
  "timestamp": "string - ISO 8601 timestamp",
  "message": "string - Human-readable error description",
  "error_code": "string - Machine-readable error code",
  "debug_info": {
    "service": "string - Service name that generated error",
    "exception_type": "string - Exception class name",
    "exception_details": "string - Exception message",
    "traceback": "string - Full traceback (development only)",
    "context": "object - Additional context information"
  },
  "retry_info": {
    "retryable": "boolean - Whether client should retry",
    "retry_after_seconds": "integer - Suggested retry delay (if retryable)"
  }
}
```

### 4.3 Error Code Categories
- **VALIDATION_ERROR**: Request format or parameter validation failed
- **DEPENDENCY_ERROR**: Downstream service call failed
- **TIMEOUT_ERROR**: Operation timed out
- **CONFIGURATION_ERROR**: Service configuration problem
- **RESOURCE_ERROR**: Insufficient resources (memory, disk, etc.)
- **BUSINESS_LOGIC_ERROR**: Business rule validation failed
- **UNKNOWN_ERROR**: Unexpected error condition

## 5. Request/Response Middleware

### 5.1 Request ID Propagation
- All requests include optional `request_id` field
- Services generate UUID if not provided
- Request ID passed to all downstream service calls
- Request ID included in all log entries

### 5.2 Timing and Performance
- All responses include `processing_time_ms` field
- Services track and log response times
- Timeout handling for all downstream calls
- Performance metrics collection

### 5.3 Content Validation
- Request body JSON schema validation
- Response body format validation
- UTF-8 encoding enforcement
- Content-Type header validation

## 6. Development and Testing Support

### 6.1 Mock Service Contracts
Each service provides OpenAPI/Swagger specifications for:
- Request/response format documentation
- Example requests and responses
- Error scenario examples
- Mock server generation for downstream teams

### 6.2 Contract Testing
- JSON schema validation for all interfaces
- Integration tests validate actual service compliance
- Contract change detection and versioning
- Backward compatibility validation

### 6.3 Debugging and Observability
- Request/response logging (configurable detail level)
- Debug endpoints for service introspection
- Health check endpoints for dependency monitoring
- Structured logging with consistent format

These service interfaces ensure clear contracts between teams while maintaining flexibility for independent development and comprehensive error handling throughout the system.