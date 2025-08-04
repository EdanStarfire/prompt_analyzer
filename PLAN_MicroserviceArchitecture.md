# Microservice Architecture Plan

## 1. Overview
The Prompt Filtering System is designed as a collection of independent FastAPI microservices that communicate via REST APIs. Each service can be developed, tested, and deployed independently while maintaining clear interfaces and contracts.

## 2. Service Architecture

### 2.1 Categorizer Service (Port 8002)
**Purpose**: Analyzes prompts and categorizes instructions within them using LLM
**Independence**: Can run standalone with direct LLM backend integration
**Team**: Team A (Foundation service - required by others)

**Key Features**:
- FastAPI service with async LLM calls
- Direct integration with `http://172.28.16.136:1234/v1`
- Model: `mistralai/devstral-small-2507`
- Independent unit testing with mocked LLM responses
- Integration testing with real LLM backend

### 2.2 Filtering Engine Service (Port 8003)  
**Purpose**: Evaluates categorized prompts against filtering criteria
**Independence**: Consumes categorization data via REST API calls
**Team**: Team B (Depends on categorization output format)

**Key Features**:
- FastAPI service with configurable filtering logic
- JSON-based filtering criteria from unified config
- REST client for Categorizer Service
- Independent unit testing with mocked categorization data
- Integration testing with real Categorizer Service

### 2.3 Prompt Proxy Service (Port 8001)
**Purpose**: OpenAI-compatible interface that orchestrates the filtering pipeline  
**Independence**: Can operate in bypass mode or with full filtering pipeline
**Team**: Team C (Orchestration service)

**Key Features**:
- FastAPI service with OpenAI-compatible endpoints
- Bypass mode for direct LLM proxying (testing/verification)
- Full pipeline mode (Proxy → Categorizer → Filtering → LLM)
- REST clients for both downstream services
- Comprehensive error handling and debug information

### 2.4 Test Prompt Generator Service (Port 8004)
**Purpose**: Generates test prompts and validates them through the pipeline
**Independence**: Utility service that can test full pipeline or individual components
**Team**: Team D (Testing utility)

**Key Features**:
- FastAPI service for generating complexity test prompts
- LLM integration for prompt generation
- REST clients for testing full pipeline
- Comprehensive test case generation and validation

## 3. Service Communication

### 3.1 REST API Communication
- All inter-service communication via HTTP REST APIs
- No shared databases or message queues for MVP
- Direct service-to-service calls with configurable endpoints
- Graceful error handling with full debug information propagation

### 3.2 Service Discovery
- Services use configurable endpoint URLs from unified config
- Development: Direct localhost:port communication
- Production: Leverage existing internal service discovery infrastructure

## 4. Configuration Management

### 4.1 Unified Configuration
- Single `config/system_config.json` file for all services
- Each service reads relevant sections of the unified config
- Streamlined development and testing workflow

### 4.2 Configuration Sections
```json
{
  "llm": {
    "endpoint": "http://172.28.16.136:1234/v1",
    "api_key": "-",
    "model": "mistralai/devstral-small-2507"
  },
  "services": {
    "categorizer": "http://localhost:8002",
    "filtering": "http://localhost:8003", 
    "proxy": "http://localhost:8001",
    "test_generator": "http://localhost:8004"
  },
  "filtering_criteria": {
    "blocked_categories": ["harmful", "explicit"],
    "confidence_threshold": 0.8
  }
}
```

## 5. Development Standards

### 5.1 Technology Stack
- **Framework**: FastAPI with async/await support
- **Package Management**: `uv` exclusively (no pip/poetry)
- **Testing**: pytest with `uv run pytest`
- **Execution**: `uv run` for all commands

### 5.2 Project Structure
Each service gets its own directory with:
- `pyproject.toml` managed by `uv`
- Independent virtual environment via `uv`
- Service-specific tests and fixtures
- Dockerfile for containerization

## 6. Error Handling Strategy

### 6.1 Graceful Error Propagation
- All errors fail gracefully with structured responses
- Full debug information exposed in development
- Consistent error format across all services
- HTTP status codes following REST conventions

### 6.2 Error Response Format
```json
{
  "error": true,
  "message": "Human-readable error description",
  "debug_info": {
    "service": "categorizer",
    "exception_type": "LLMConnectionError",
    "exception_details": "Connection timeout to LLM endpoint",
    "traceback": "..."
  },
  "request_id": "uuid-for-tracing"
}
```

## 7. Testing Independence

### 7.1 Service-Level Testing
- Each service maintains independent test fixtures
- Unit tests with mocked dependencies
- Integration tests with real external services (LLM, other services)
- No shared test data between services

### 7.2 Cross-Service Testing
- Progressive staged integration testing
- Full end-to-end pipeline testing
- Performance and load testing capabilities

## 8. Development Benefits

### 8.1 Team Independence
- Each team can develop without coordination
- Clear API contracts defined upfront
- Independent testing and deployment cycles
- Minimal cross-team dependencies

### 8.2 Technical Benefits
- Easier debugging and troubleshooting
- Independent scaling of services
- Technology stack flexibility per service
- Clear separation of concerns

## 9. Execution Order

1. **Phase 1**: Categorizer Service (foundational)
2. **Phase 2**: Filtering Engine Service (consumes categorization)
3. **Phase 3**: Prompt Proxy Service (orchestrates pipeline) 
4. **Phase 4**: Test Prompt Generator Service (testing utility)

This architecture ensures each service can be developed, tested, and run completely independently while maintaining clear interfaces for integration.