# Filtering Engine Service Plan (Microservice Architecture)

## 1. Overview
The Filtering Engine Service evaluates categorized prompts against predefined filtering criteria and makes decisions to allow, block, or review prompts. It operates as an independent FastAPI service that receives categorization results from the Categorizer Service and applies configurable filtering rules.

## 2. Service Architecture
- **Port**: 8003 (Filtering decisions service)
- **Framework**: FastAPI with async/await support
- **Dependencies**: Categorizer Service (8002) for input data
- **Phase**: 2 (Business Logic service - depends on Phase 1)

## 3. Core Functionality

### 3.1 Filtering Rule Engine
- **Rule Evaluation**: Apply configurable filtering criteria to categorization results
- **Decision Logic**: Generate allow/block/review decisions with confidence scores
- **Rule Types**: Category-based, confidence-based, and composite rules
- **Configuration Management**: JSON-based filtering criteria with runtime updates

### 3.2 Decision Making
- **Primary Decisions**: allow, block, review
- **Reasoning**: Detailed explanation of decision rationale
- **Risk Assessment**: Identify and score risk factors
- **Rule Matching**: Track which rules triggered the decision

## 4. Implementation Requirements

### 4.1 FastAPI Application Structure
```
services/filtering/
├── pyproject.toml              # UV-managed dependencies
├── main.py                     # FastAPI application entry point
├── api/                        # API endpoints and routing
│   ├── __init__.py
│   ├── evaluate.py             # Filtering evaluation endpoints
│   └── health.py               # Health check endpoints
├── core/                       # Business logic
│   ├── __init__.py
│   ├── filtering_engine.py     # Core filtering logic
│   ├── rule_engine.py          # Rule evaluation logic
│   └── models.py               # Pydantic models and schemas
├── tests/                      # Comprehensive test suite
│   ├── __init__.py
│   ├── unit/                   # Unit tests with mocked data
│   ├── integration/            # Integration tests with Categorizer
│   └── fixtures/               # Test data and mock responses
└── README.md                   # Service documentation
```

### 4.2 Key Dependencies (pyproject.toml)
```toml
[project]
name = "filtering-engine-service"
version = "1.0.0"
requires-python = ">=3.11"
dependencies = [
    "fastapi>=0.104.0",
    "uvicorn>=0.24.0",
    "httpx>=0.25.0",          # HTTP client for Categorizer calls
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

### 5.1 Evaluate Prompt
**Endpoint**: `POST /evaluate`
**Purpose**: Evaluate categorized prompt against filtering criteria

**Request Processing Flow**:
1. Validate categorization result format
2. Load current filtering configuration
3. Apply filtering rules to categorization data
4. Generate decision with reasoning
5. Log decision and rationale
6. Return structured evaluation result

### 5.2 Health Check
**Endpoint**: `GET /health`
**Purpose**: Service health and dependency status

## 6. Service Communication

### 6.1 Categorizer Service Integration
```python
# Example: Validate upstream categorization data
async def validate_categorization_input(self, categorization_result: dict) -> bool:
    """Validate input from Categorizer Service"""
    required_fields = ["categories", "primary_category", "overall_confidence"]
    return all(field in categorization_result for field in required_fields)
```

### 6.2 Configuration Loading
```python
# Configuration access pattern
from shared.config_loader import ConfigLoader

config = ConfigLoader("filtering")
filtering_config = config.get_filtering_config()

# Access filtering rules and criteria
filtering_rules = filtering_config["rules"]
default_mode = filtering_config["default_mode"]
```

## 7. Filtering Rule Engine

### 7.1 Rule Types
```python
# Category-based rules
{
    "name": "block_harmful_content",
    "type": "category_match",
    "category": "harmful_content",
    "action": "block",
    "enabled": true
}

# Confidence-based rules
{
    "name": "high_confidence_block",
    "type": "category_confidence",
    "category": "explicit_content",
    "threshold": 0.8,
    "action": "block",
    "enabled": true
}

# Composite rules
{
    "name": "multiple_risk_factors",
    "type": "composite",
    "conditions": [
        {"category": "personal_information", "confidence": ">0.6"},
        {"category": "harmful_content", "confidence": ">0.4"}
    ],
    "action": "review",
    "enabled": true
}
```

### 7.2 Decision Logic
```python
async def evaluate_filtering_rules(self, categorization_result: dict) -> dict:
    """Apply filtering rules and generate decision"""
    triggered_rules = []
    risk_factors = []
    
    for rule in self.filtering_rules:
        if self.evaluate_rule(rule, categorization_result):
            triggered_rules.append(rule)
            
    decision = self.determine_final_decision(triggered_rules)
    reasoning = self.generate_reasoning(triggered_rules, risk_factors)
    
    return {
        "decision": decision,
        "confidence": self.calculate_decision_confidence(triggered_rules),
        "reasoning": reasoning,
        "metadata": {
            "rules_evaluated": len(self.filtering_rules),
            "rules_triggered": len(triggered_rules),
            "processing_time_ms": processing_time
        }
    }
```

## 8. Testing Strategy

### 8.1 Unit Tests (`tests/unit/`)
- **Mock categorization data** for filtering logic testing
- **Test filtering rule evaluation** with various scenarios
- **Test configuration loading** and validation
- **Test decision logic** for allow/block/review outcomes
- **Test error handling** for invalid categorization data

**Key Test Files**:
- `test_filtering_engine.py`: Core filtering logic
- `test_rule_engine.py`: Rule evaluation logic
- `test_api.py`: FastAPI endpoint behavior

### 8.2 Integration Tests (`tests/integration/`)
- **Real calls to Categorizer Service** for end-to-end testing
- **Test with various categorization results** from real service
- **Test configuration file changes** and runtime updates
- **Test error scenarios** from upstream service failures

**Key Test Files**:
- `test_categorizer_integration.py`: Integration with Categorizer Service
- `test_api_integration.py`: API integration testing

## 9. Performance Requirements

### 9.1 Response Time Targets
- **Filtering Evaluation**: < 100ms (pure logic, no LLM calls)
- **Configuration Updates**: < 50ms
- **Health Checks**: < 50ms
- **Error Responses**: < 100ms

### 9.2 Throughput Requirements
- **Concurrent Requests**: Support 100+ concurrent evaluations
- **Request Rate**: Handle 50+ requests/second sustained
- **Resource Usage**: < 256MB memory under normal load

## 10. Configuration Management

### 10.1 Filtering Configuration Access
```python
# Access filtering-specific configuration
filtering_config = config.get_filtering_config()

# Runtime configuration updates
async def update_filtering_rules(self, new_rules: list) -> bool:
    """Update filtering rules at runtime"""
    validated_rules = self.validate_rules(new_rules)
    if validated_rules:
        self.filtering_rules = validated_rules
        return True
    return False
```

### 10.2 Rule Configuration Examples
```json
{
  "filtering": {
    "default_mode": "standard",
    "modes": {
      "strict": {
        "confidence_threshold": 0.6,
        "blocked_categories": ["harmful_content", "explicit_content", "personal_information"],
        "allow_borderline": false
      },
      "standard": {
        "confidence_threshold": 0.8,
        "blocked_categories": ["harmful_content", "explicit_content"],
        "allow_borderline": true
      }
    }
  }
}
```

## 11. Error Handling Strategy

### 11.1 Input Validation Errors
- **Invalid categorization format**: Return structured error with format requirements
- **Missing required fields**: Detailed error messages for missing data
- **Configuration errors**: Clear guidance for configuration fixes

### 11.2 Service Communication Errors
- **Categorizer Service unavailable**: Graceful degradation with default rules
- **Configuration loading failures**: Fallback to default filtering criteria
- **Rule evaluation errors**: Safe defaults with error logging

## 12. Development Workflow

### 12.1 TDD Development Process
1. **Write unit tests** for core filtering logic
2. **Implement rule engine** to pass unit tests
3. **Write integration tests** for Categorizer Service communication
4. **Implement FastAPI endpoints** and service integration
5. **Test configuration management** and runtime updates

### 12.2 Testing Commands
```bash
# Unit tests (fast feedback)
cd services/filtering
uv run pytest tests/unit/ -v

# Integration tests (requires Categorizer Service)
uv run pytest tests/integration/ -v

# All tests
uv run pytest -v

# Run service for development
uv run uvicorn main:app --host 0.0.0.0 --port 8003 --reload
```

## 13. Deployment Considerations

### 13.1 Service Dependencies
- **Required Services**: Categorizer Service (8002) for evaluation data
- **Configuration**: Unified configuration file access
- **Startup Order**: Must start after Categorizer Service is available
- **Health Checks**: Validate Categorizer Service connectivity

### 13.2 Service Execution
```bash
# Install dependencies
cd services/filtering
uv init
uv add fastapi uvicorn httpx pydantic pydantic-settings structlog

# Run service for development
uv run uvicorn main:app --host 0.0.0.0 --port 8003 --reload

# Run service for production
uv run uvicorn main:app --host 0.0.0.0 --port 8003
```

## 14. Service Handoff Process

### 14.1 Development Team Deliverables
- Complete unit test coverage (>90%) for filtering logic
- Service runs independently with health checks
- Integration tests pass with Categorizer Service
- Configuration schema documented with examples
- Service execution instructions for QA team

### 14.2 QA Integration Requirements
- Service must respond to health checks before integration testing
- Categorizer Service must be running for integration tests
- Configuration examples provided for various filtering scenarios
- Error scenarios documented for QA validation

This Filtering Engine Service plan provides a comprehensive foundation for implementing the rule-based filtering decision service as an independent microservice that integrates seamlessly with the Categorizer Service while maintaining clear separation of concerns.