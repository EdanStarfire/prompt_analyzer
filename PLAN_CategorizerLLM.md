# Categorizer Service Plan (Microservice Architecture)

## 1. Overview
The Categorizer Service analyzes prompts and categorizes the instructions contained within them using a dedicated LLM. It operates as an independent FastAPI service that provides the foundation for the filtering pipeline by classifying prompt content into predefined categories with confidence scores.

## 2. Service Architecture
- **Port**: 8002 (Foundation categorization service)
- **Framework**: FastAPI with async/await support
- **Dependencies**: LLM Backend (`http://172.28.16.136:1234/v1`)
- **Phase**: 1 (Foundation service - no dependencies on other services)

## 3. Core Functionality

### 3.1 Prompt Analysis
- **Content Categorization**: Classify prompts into predefined categories
- **Confidence Scoring**: Provide confidence levels for each categorization
- **Evidence Extraction**: Identify text excerpts supporting categorization decisions
- **Multi-Category Support**: Handle prompts that span multiple categories

### 3.2 LLM Integration
- **Slow LLM Handling**: Accommodate 2-5 minute response times with appropriate timeouts
- **Error Recovery**: Handle LLM timeouts and connection failures gracefully
- **Prompt Engineering**: Optimize categorization prompts for accuracy and consistency
- **Response Parsing**: Extract structured categorization data from LLM responses

## 4. Implementation Requirements

### 4.1 FastAPI Application Structure
```
services/categorizer/
├── pyproject.toml              # UV-managed dependencies
├── main.py                     # FastAPI application entry point
├── api/                        # API endpoints and routing
│   ├── __init__.py
│   ├── categorize.py           # Categorization endpoints
│   └── health.py               # Health check endpoints
├── core/                       # Business logic
│   ├── __init__.py
│   ├── categorizer.py          # Core categorization logic
│   ├── llm_client.py           # LLM integration client
│   └── models.py               # Pydantic models and schemas
├── tests/                      # Comprehensive test suite
│   ├── __init__.py
│   ├── unit/                   # Unit tests with mocked LLM
│   ├── integration/            # Integration tests with real LLM
│   └── fixtures/               # Test data and mock responses
└── README.md                   # Service documentation
```

### 4.2 Key Dependencies (pyproject.toml)
```toml
[project]
name = "categorizer-service"
version = "1.0.0"
requires-python = ">=3.11"
dependencies = [
    "fastapi>=0.104.0",
    "uvicorn>=0.24.0",
    "httpx>=0.25.0",          # HTTP client for LLM calls
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

### 5.1 Categorize Prompt
**Endpoint**: `POST /categorize`
**Purpose**: Analyze and categorize instructions within a prompt

**Request Processing Flow**:
1. Validate input prompt format and content
2. Prepare categorization prompt for LLM
3. Call LLM backend with extended timeout (5 minutes)
4. Parse and validate LLM response
5. Extract categories, confidence scores, and evidence
6. Return structured categorization result

### 5.2 Health Check
**Endpoint**: `GET /health`
**Purpose**: Service health and LLM backend connectivity

## 6. LLM Integration

### 6.1 LLM Client Implementation
```python
async def call_llm_for_categorization(self, prompt: str, request_id: str) -> dict:
    """Call LLM backend for prompt categorization"""
    async with httpx.AsyncClient(timeout=300.0) as client:  # 5 minute timeout
        categorization_prompt = self.build_categorization_prompt(prompt)
        
        response = await client.post(
            f"{self.config.llm_endpoint}/v1/chat/completions",
            json={
                "model": self.config.llm_model,
                "messages": [
                    {"role": "system", "content": self.get_system_prompt()},
                    {"role": "user", "content": categorization_prompt}
                ],
                "temperature": 0.1,
                "max_tokens": 1000
            },
            headers={"Authorization": f"Bearer {self.config.llm_api_key}"},
            timeout=300.0
        )
        response.raise_for_status()
        return response.json()
```

### 6.2 Categorization Prompt Engineering
```python
def build_categorization_prompt(self, user_prompt: str) -> str:
    """Build structured prompt for LLM categorization"""
    return f"""
Analyze the following user prompt and categorize it according to these categories:

Categories:
- harmless: Safe, appropriate content
- code_generation: Programming and code-related requests  
- harmful_content: Potentially harmful or inappropriate content
- explicit_content: Adult or sexually explicit content
- personal_information: Requests involving personal or private information

User Prompt: "{user_prompt}"

Return your analysis in JSON format with:
- categories: array of applicable categories with confidence scores (0.0-1.0)
- primary_category: the most applicable category
- overall_confidence: overall confidence in categorization (0.0-1.0)
- evidence: text excerpts supporting your categorization

Response must be valid JSON only.
"""
```

## 7. Testing Strategy

### 7.1 Unit Tests (`tests/unit/`)
- **Mock LLM responses** for predictable categorization testing
- **Test prompt parsing** and preparation logic
- **Test categorization result** formatting and validation
- **Test error handling** for invalid prompts and LLM failures
- **Test timeout handling** and retry logic

**Key Test Files**:
- `test_categorizer.py`: Core categorization logic
- `test_llm_client.py`: LLM integration client
- `test_api.py`: FastAPI endpoint behavior

### 7.2 Integration Tests (`tests/integration/`)
- **Real LLM calls** with actual prompts and 5-minute timeouts
- **Test timeout and connection** error handling with slow LLM
- **Test different prompt types** and edge cases
- **Performance testing** with various prompt sizes and complexity
- **Test adversarial prompts** designed to challenge categorization

**Key Test Files**:
- `test_llm_integration.py`: Real LLM backend integration
- `test_api_integration.py`: API integration with slow responses

## 8. Performance Requirements

### 8.1 Response Time Targets
- **LLM Processing**: 2-5 minutes (depends on LLM backend)
- **Local Processing**: < 100ms (prompt prep, response parsing)
- **Total Service Time**: < 6 minutes including all overhead
- **Health Checks**: < 100ms
- **Error Responses**: < 500ms

### 8.2 Throughput Requirements
- **Concurrent Requests**: Support 5-10 concurrent LLM calls (limited by slow backend)
- **Request Rate**: Handle 1-3 requests/minute sustained (due to LLM latency)
- **Resource Usage**: < 256MB memory under normal load
- **Timeout Management**: Graceful handling of LLM timeouts without service degradation

## 9. Configuration Management

### 9.1 LLM Configuration Access
```python
# Configuration loading pattern
from shared.config_loader import ConfigLoader

config = ConfigLoader("categorizer")
service_config = config.get_service_config()

# Access LLM configuration with extended timeouts
llm_endpoint = service_config["llm"]["endpoint"]
llm_timeout = service_config["llm"]["request_timeout_seconds"]  # 300 seconds
llm_model = service_config["llm"]["model"]

# Access categorization-specific settings
categorization_config = config.get_categorization_config()
confidence_threshold = categorization_config["confidence_threshold"]
categories = categorization_config["categories"]
```

### 9.2 Category Configuration
```python
# Access predefined categories and examples
categories = {
    "harmless": {
        "description": "Safe, appropriate content",
        "examples": ["general questions", "educational content", "creative writing"]
    },
    "code_generation": {
        "description": "Programming and code-related requests",
        "examples": ["write a function", "debug this code", "explain algorithm"]
    },
    "harmful_content": {
        "description": "Potentially harmful or inappropriate content",
        "examples": ["violence", "illegal activities", "harassment"]
    }
}
```

## 10. Error Handling Strategy

### 10.1 LLM Communication Errors
- **Timeout Errors**: Return structured error with retry suggestions
- **Connection Failures**: Graceful degradation with fallback categorization
- **Invalid Responses**: Parse errors handled with default safe categorization
- **Rate Limiting**: Implement backoff and retry strategies

### 10.2 Input Validation Errors
- **Empty Prompts**: Return validation error with guidance
- **Oversized Prompts**: Truncate or reject with size limits
- **Invalid Characters**: Sanitize input or return format errors
- **Malformed Requests**: Detailed error messages for API contract violations

## 11. Development Workflow

### 11.1 TDD Development Process
1. **Write unit tests** for core categorization logic with mocked LLM
2. **Implement categorizer engine** to pass unit tests
3. **Write integration tests** for real LLM communication with timeouts
4. **Implement LLM client** and error handling
5. **Test prompt engineering** for optimal categorization accuracy

### 11.2 Testing Commands
```bash
# Unit tests (fast feedback with mocks)
cd services/categorizer
uv run pytest tests/unit/ -v

# Integration tests (requires LLM backend, slow due to timeouts)
uv run pytest tests/integration/ -v --timeout=360

# All tests
uv run pytest -v

# Run service for development
uv run uvicorn main:app --host 0.0.0.0 --port 8002 --reload
```

## 12. Deployment Considerations

### 12.1 Service Dependencies
- **Required External Services**: LLM Backend at `http://172.28.16.136:1234/v1`
- **Configuration**: Unified configuration file access
- **Startup Validation**: Verify LLM connectivity before accepting requests
- **Health Checks**: Validate LLM backend availability

### 12.2 Service Execution
```bash
# Install dependencies
cd services/categorizer
uv init
uv add fastapi uvicorn httpx pydantic pydantic-settings structlog

# Run service for development
uv run uvicorn main:app --host 0.0.0.0 --port 8002 --reload

# Run service for production
uv run uvicorn main:app --host 0.0.0.0 --port 8002
```

## 13. Service Handoff Process

### 13.1 Development Team Deliverables
- Complete unit test coverage (>90%) for categorization logic
- Service runs independently with health checks
- Integration tests pass with real LLM backend (allowing for slow responses)
- Category definitions and examples documented
- Service execution instructions for QA team
- LLM prompt engineering documented for consistency

### 13.2 QA Integration Requirements
- Service must respond to health checks before integration testing
- LLM backend must be available for integration tests
- Extended test timeouts (6+ minutes) to accommodate slow LLM responses
- Categorization examples provided for various prompt types
- Error scenarios documented for timeout and connection failure testing

## 14. Prompt Engineering

### 14.1 System Prompt Optimization
```python
def get_system_prompt(self) -> str:
    """Optimized system prompt for consistent categorization"""
    return """You are a content categorization system. Analyze user prompts and classify them into predefined categories with high accuracy and consistency.

Guidelines:
- Be conservative with harmful/explicit content classification
- Provide confidence scores based on clear evidence
- Extract specific text excerpts that support your categorization
- Handle ambiguous content by selecting the most applicable primary category
- Return only valid JSON format responses"""
```

### 14.2 Response Parsing
```python
def parse_llm_response(self, llm_response: dict) -> dict:
    """Parse and validate LLM categorization response"""
    try:
        content = llm_response["choices"][0]["message"]["content"]
        categorization_data = json.loads(content)
        
        # Validate required fields and format
        validated_response = self.validate_categorization_format(categorization_data)
        return validated_response
        
    except (json.JSONDecodeError, KeyError, IndexError) as e:
        # Return safe default categorization for parsing errors
        return self.get_default_safe_categorization()
```

This Categorizer Service plan provides a comprehensive foundation for implementing the LLM-powered categorization service as an independent microservice that handles slow LLM backends gracefully while providing accurate and consistent prompt categorization for the filtering pipeline.