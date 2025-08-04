# Prompt Proxy Service Plan (Microservice Architecture)

## 1. Overview
The Prompt Proxy Service provides an OpenAI-compatible interface that orchestrates the complete filtering pipeline. It operates as the main user-facing service, handling incoming requests and coordinating with the Categorizer and Filtering Engine services to provide filtered LLM responses.

## 2. Service Architecture
- **Port**: 8001 (Main user-facing service)
- **Framework**: FastAPI with async/await support
- **Dependencies**: Categorizer Service (8002), Filtering Engine Service (8003), LLM Backend
- **Phase**: 3 (Orchestration service - depends on Phases 1 & 2)

## 3. Core Functionality

### 3.1 OpenAI-Compatible Interface
- **Primary Endpoint**: `POST /v1/chat/completions`
- **Compatibility**: Full OpenAI Chat Completions API compliance
- **Request Format**: Standard OpenAI request structure
- **Response Format**: Standard OpenAI response structure with filtering metadata

### 3.2 Pipeline Orchestration
- **Request Processing**: Parse and validate OpenAI-compatible requests
- **Categorization**: Call Categorizer Service for prompt analysis
- **Filtering**: Call Filtering Engine Service for allow/block decisions
- **LLM Integration**: Forward allowed requests to LLM backend
- **Response Assembly**: Format responses with filtering metadata

### 3.3 Operational Modes
- **Full Pipeline Mode**: Complete filtering pipeline (Categorizer → Filtering → LLM)
- **Bypass Mode**: Direct LLM proxying without filtering (for testing/verification)
- **Filtering Only Mode**: Apply filtering but log results instead of blocking

## 4. Implementation Requirements

### 4.1 FastAPI Application Structure
```
services/proxy/
├── pyproject.toml              # UV-managed dependencies
├── main.py                     # FastAPI application entry point
├── api/                        # API endpoints and routing
│   ├── __init__.py
│   ├── chat_completions.py     # OpenAI-compatible chat completions
│   ├── proxy.py               # Proxy-specific endpoints
│   └── health.py              # Health check endpoints
├── core/                       # Business logic
│   ├── __init__.py
│   ├── proxy_engine.py        # Pipeline orchestration logic
│   ├── openai_adapter.py      # OpenAI interface adaptation
│   └── models.py              # Pydantic models and schemas
├── tests/                      # Comprehensive test suite
│   ├── __init__.py
│   ├── unit/                  # Unit tests with mocked services
│   ├── integration/           # Integration tests with real services
│   ├── staged/                # Progressive integration tests
│   └── fixtures/              # Test data and mock responses
├── Dockerfile                  # Container configuration
└── README.md                  # Service documentation
```

### 4.2 Key Dependencies (pyproject.toml)
```toml
[project]
name = "prompt-proxy-service"
version = "1.0.0"
requires-python = ">=3.11"
dependencies = [
    "fastapi>=0.104.0",
    "uvicorn>=0.24.0",
    "httpx>=0.25.0",          # HTTP client for service calls
    "pydantic>=2.5.0",
    "pydantic-settings>=2.1.0",
    "structlog>=23.2.0",      # Structured logging
]

[project.optional-dependencies]
test = [
    "pytest>=7.4.0",
    "pytest-asyncio>=0.21.0",
    "pytest-mock>=3.12.0",
    "httpx>=0.25.0",          # For testing HTTP clients
]
```

## 5. API Endpoints

### 5.1 OpenAI Chat Completions
**Endpoint**: `POST /v1/chat/completions`
**Purpose**: Main OpenAI-compatible interface with filtering

**Request Processing Flow**:
1. Validate OpenAI request format
2. Extract prompt from messages
3. Call Categorizer Service for analysis
4. Call Filtering Engine Service for decision
5. If allowed: Forward to LLM backend
6. If blocked: Return filtered response
7. Format response with metadata

### 5.2 Proxy Control Endpoints
**Endpoint**: `POST /proxy/configure`
**Purpose**: Runtime configuration of proxy behavior

**Endpoint**: `GET /proxy/status`
**Purpose**: Proxy service status and pipeline health

### 5.3 Health Check
**Endpoint**: `GET /health`
**Purpose**: Complete pipeline health validation

## 6. Service Communication

### 6.1 Categorizer Service Integration
```python
# Example service call pattern
async def categorize_prompt(self, prompt: str, request_id: str) -> dict:
    """Call Categorizer Service for prompt analysis"""
    async with httpx.AsyncClient() as client:
        response = await client.post(
            f"{self.config.categorizer_url}/categorize",
            json={
                "prompt": prompt,
                "request_id": request_id,
                "options": {
                    "include_confidence": True,
                    "detailed_analysis": True
                }
            },
            timeout=self.config.categorizer_timeout
        )
        response.raise_for_status()
        return response.json()
```

### 6.2 Filtering Engine Integration
```python
async def evaluate_prompt(self, categorization_result: dict, 
                         original_prompt: str, request_id: str) -> dict:
    """Call Filtering Engine for decision"""
    async with httpx.AsyncClient() as client:
        response = await client.post(
            f"{self.config.filtering_url}/evaluate",
            json={
                "categorization_result": categorization_result,
                "original_prompt": original_prompt,
                "request_id": request_id,
                "evaluation_options": {
                    "strict_mode": False,
                    "explain_decision": True
                }
            },
            timeout=self.config.filtering_timeout
        )
        response.raise_for_status()
        return response.json()
```

### 6.3 LLM Backend Integration
```python
async def call_llm_backend(self, openai_request: dict, request_id: str) -> dict:
    """Forward request to LLM backend"""
    async with httpx.AsyncClient() as client:
        response = await client.post(
            f"{self.config.llm_endpoint}/v1/chat/completions",
            json=openai_request,
            headers={"Authorization": f"Bearer {self.config.llm_api_key}"},
            timeout=self.config.llm_timeout
        )
        response.raise_for_status()
        return response.json()
```

## 7. Error Handling Strategy

### 7.1 Service Failure Handling
- **Categorizer Failure**: Fallback to basic content analysis or bypass
- **Filtering Failure**: Fallback to allow with warning or strict deny
- **LLM Failure**: Return standard error response with retry suggestions
- **Configuration Errors**: Detailed error messages with resolution steps

### 7.2 Error Response Format
```python
# Example error response (OpenAI-compatible)
{
    "error": {
        "message": "Content filtering service temporarily unavailable",
        "type": "service_unavailable",
        "code": "filtering_service_error"
    },
    "filter_metadata": {
        "decision": "error",
        "fallback_action": "allow_with_warning",
        "debug_info": {
            "service": "proxy",
            "failed_dependency": "filtering_service",
            "request_id": "uuid-here"
        }
    }
}
```

## 8. Testing Strategy

### 8.1 Unit Tests (`tests/unit/`)
- **Mock all downstream services** (Categorizer, Filtering, LLM)
- **Test request validation** and OpenAI compatibility
- **Test pipeline orchestration logic** with various scenarios
- **Test error handling** for each service failure mode
- **Test bypass mode** functionality

**Key Test Files**:
- `test_proxy_engine.py`: Core orchestration logic
- `test_openai_adapter.py`: OpenAI interface compliance
- `test_api.py`: FastAPI endpoint behavior

### 8.2 Integration Tests (`tests/integration/`)
- **Real service calls** to Categorizer and Filtering services
- **Real LLM backend integration** testing
- **End-to-end request processing** validation
- **Performance and timeout** testing

**Key Test Files**:
- `test_pipeline_integration.py`: Complete pipeline testing
- `test_openai_compatibility.py`: OpenAI API compliance validation

### 8.3 Staged Integration Tests (`tests/staged/`)
- **Stage 1**: Proxy + Categorizer integration
- **Stage 2**: Proxy + Categorizer + Filtering integration  
- **Stage 3**: Complete pipeline with LLM backend
- **Progressive complexity** testing at each stage

**Key Test Files**:
- `test_categorizer_integration.py`: Proxy-Categorizer interaction
- `test_filtering_integration.py`: Proxy-Filtering interaction
- `test_full_pipeline.py`: Complete system integration

## 9. Performance Requirements

### 9.1 Response Time Targets
- **Bypass Mode**: < 100ms overhead + LLM response time (2-5 minutes)
- **Full Pipeline**: < 6 minutes total response time (accounts for slow LLM backend)
- **Error Responses**: < 500ms
- **Health Checks**: < 100ms

### 9.2 Throughput Requirements
- **Concurrent Requests**: Support 10+ concurrent requests (limited by slow LLM)
- **Request Rate**: Handle 1-2 requests/second sustained (due to LLM latency)
- **Resource Usage**: < 512MB memory under normal load

## 10. Configuration Integration

### 10.1 Service Configuration Access
```python
# Configuration loading pattern
from shared.config_loader import ConfigLoader

config = ConfigLoader("proxy")
service_config = config.get_service_config()

# Access downstream service URLs
categorizer_url = service_config["services"]["categorizer"]["url"]
filtering_url = service_config["services"]["filtering"]["url"]
llm_endpoint = service_config["llm"]["endpoint"]

# Access proxy-specific settings
proxy_settings = config.get_proxy_config()  # Custom proxy configuration
```

### 10.2 Runtime Configuration
- **Dynamic filtering mode switching** (full/bypass/logging)
- **Service endpoint updates** without restart
- **Timeout and retry configuration** updates
- **Debug mode toggling** for development

## 11. Operational Modes

### 11.1 Bypass Mode
- **Purpose**: Direct LLM proxying for testing and verification
- **Activation**: Request parameter `filtering_options.bypass_filter: true`
- **Behavior**: Skip categorization and filtering, direct LLM call
- **Use Cases**: Performance testing, LLM compatibility verification

### 11.2 Logging Mode
- **Purpose**: Apply filtering but log results instead of blocking
- **Activation**: Configuration setting `filtering.mode: logging`
- **Behavior**: Process through pipeline, log decisions, allow all requests
- **Use Cases**: Monitoring, false positive analysis, gradual rollout

### 11.3 Strict Mode
- **Purpose**: Enhanced filtering with lower tolerance thresholds
- **Activation**: Request parameter `filtering_options.strict_mode: true`
- **Behavior**: Use stricter filtering criteria
- **Use Cases**: High-security environments, sensitive applications

## 12. Monitoring and Observability

### 12.1 Metrics Collection
- **Request counts** by endpoint and result type
- **Response times** for each pipeline stage
- **Error rates** by service dependency
- **Filtering decisions** (allow/block/error) distribution

### 12.2 Logging Strategy
- **Structured logging** with request IDs
- **Pipeline stage timing** for performance analysis
- **Filtering decisions** with reasoning (configurable detail)
- **Error details** with full context for debugging

## 13. Development Workflow

### 13.1 TDD Development Process
1. **Write unit tests** for core orchestration logic
2. **Implement proxy engine** to pass unit tests
3. **Write integration tests** for service communication
4. **Implement service clients** and error handling
5. **Write staged tests** for progressive integration
6. **Implement OpenAI adapter** and API endpoints

### 13.2 Testing Commands
```bash
# Unit tests (fast feedback)
cd services/proxy
uv run pytest tests/unit/ -v

# Integration tests (requires services)
uv run pytest tests/integration/ -v

# Staged integration (requires specific services)
uv run pytest tests/staged/ -v

# All tests
uv run pytest -v

# Run service for development
uv run uvicorn main:app --host 0.0.0.0 --port 8001 --reload
```

## 14. Deployment Considerations

### 14.1 Service Dependencies
- **Required Services**: Categorizer (8002), Filtering Engine (8003)
- **External Services**: LLM Backend
- **Startup Order**: Must start after dependent services
- **Health Checks**: Validate all dependencies before accepting requests

### 14.2 Service Execution
```bash
# Install dependencies
cd services/proxy
uv init
uv add fastapi uvicorn httpx pydantic pydantic-settings structlog

# Run service for development
uv run uvicorn main:app --host 0.0.0.0 --port 8001 --reload

# Run service for production
uv run uvicorn main:app --host 0.0.0.0 --port 8001
```

This Prompt Proxy Service plan provides a comprehensive foundation for implementing the main user-facing service that orchestrates the complete filtering pipeline while maintaining OpenAI compatibility and independent service operation.