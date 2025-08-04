# Testing Strategy Plan

## 1. Overview
This document outlines a comprehensive Test-Driven Development (TDD) approach for the microservice architecture, with a 4-level testing pyramid that ensures each service can be independently tested while supporting progressive integration validation.

## 2. Testing Philosophy

### 2.1 TDD-First Approach
- **Write tests before implementation** for all components
- Tests define the contract and expected behavior
- Implementation must satisfy tests (not vice versa)
- Refactor only after tests pass

### 2.2 Independent Service Testing
- Each service maintains its own test suite and fixtures
- Services can be fully tested without requiring other services to be running
- Integration tests use real external dependencies (LLM, other services)
- No shared test data between services

## 3. Four-Level Testing Pyramid

### 3.1 Level 1: Unit Tests (Foundation)
**Purpose**: Test individual functions and classes in isolation
**Approach**: Mock all external dependencies
**Execution**: `uv run pytest tests/unit/`

**Requirements for each service**:
- Mock LLM responses for predictable testing
- Mock REST API calls to other services
- Test all business logic paths
- Test error handling and edge cases
- Independent test fixtures per service

**Example Structure**:
```
tests/
├── unit/
│   ├── test_categorization_logic.py  # Core logic only
│   ├── test_filtering_rules.py       # Business rules
│   ├── test_api_endpoints.py         # FastAPI endpoints with mocked deps
│   └── fixtures/
│       ├── mock_llm_responses.json
│       └── sample_prompts.json
```

### 3.2 Level 2: Component Integration Tests
**Purpose**: Test service with real external dependencies
**Approach**: Real LLM calls, real database, mocked inter-service calls
**Execution**: `uv run pytest tests/integration/`

**Requirements for each service**:
- Real LLM backend integration (categorizer, test generator)
- Real configuration file loading
- Real error scenarios from external services
- Performance and timeout testing

**Example Structure**:
```
tests/
├── integration/
│   ├── test_llm_integration.py       # Real LLM calls
│   ├── test_config_loading.py        # Real config files
│   ├── test_error_scenarios.py       # Network failures, timeouts
│   └── fixtures/
│       ├── integration_prompts.json
│       └── test_configs/
```

### 3.3 Level 3: Progressive Staged Integration
**Purpose**: Test service-to-service communication progressively
**Approach**: Real services in specific combinations
**Execution**: `uv run pytest tests/staged/`

**Staging Progression**:
1. **Stage 1**: Categorizer + Filtering Engine
   - Categorizer outputs → Filtering Engine inputs
   - Test data flow and API contracts
   
2. **Stage 2**: Categorizer + Filtering + Proxy (no LLM)
   - Full pipeline without final LLM call
   - Test orchestration and error propagation
   
3. **Stage 3**: Full pipeline + Test Generator
   - Complete system with generated test cases
   - Validate end-to-end functionality

**Example Structure**:
```
tests/
├── staged/
│   ├── test_categorizer_filtering.py    # Stage 1
│   ├── test_proxy_pipeline.py           # Stage 2  
│   ├── test_full_system.py              # Stage 3
│   └── fixtures/
│       ├── staged_test_scenarios.json
│       └── pipeline_test_data.json
```

### 3.4 Level 4: End-to-End Integration Tests
**Purpose**: Test complete system as users would experience it
**Approach**: All services running, real data flows
**Execution**: `uv run pytest tests/e2e/`

**Requirements**:
- All services must be running
- Real prompts through complete pipeline
- Performance and load testing
- User scenario validation
- Full error handling validation

**Example Structure**:
```
tests/
├── e2e/
│   ├── test_user_scenarios.py       # Complete user workflows
│   ├── test_performance.py          # Load and performance tests
│   ├── test_error_recovery.py       # System-wide error scenarios
│   └── fixtures/
│       ├── user_test_scenarios.json
│       └── load_test_data.json
```

## 4. Service-Specific Testing Requirements

### 4.1 Categorizer Service (Port 8002)
**Unit Tests**:
- Mock LLM responses for categorization logic
- Test prompt parsing and preparation
- Test categorization result formatting
- Test error handling for invalid prompts

**Integration Tests**:
- Real LLM calls with actual prompts
- Test timeout and connection error handling
- Test different prompt types and edge cases
- Performance testing with various prompt sizes

### 4.2 Filtering Engine Service (Port 8003)
**Unit Tests**:
- Mock categorization data for filtering logic
- Test filtering rule evaluation
- Test configuration loading and validation
- Test decision logic for allow/block outcomes

**Integration Tests**:
- Real calls to Categorizer Service
- Test with various categorization results
- Test configuration file changes
- Test error scenarios from upstream service

### 4.3 Prompt Proxy Service (Port 8001)
**Unit Tests**:
- Mock downstream service responses
- Test OpenAI-compatible interface formatting
- Test bypass mode functionality
- Test request routing and orchestration logic

**Integration Tests**:
- Real calls to Categorizer and Filtering services
- Test full pipeline orchestration
- Test error propagation from downstream services
- Performance testing of complete pipeline

### 4.4 Test Prompt Generator Service (Port 8004)
**Unit Tests**:
- Mock LLM responses for prompt generation
- Test generation parameters and controls
- Test prompt complexity variations
- Test output formatting

**Integration Tests**:
- Real LLM calls for prompt generation
- Real calls to Proxy service for testing generated prompts
- Test feedback loop and validation
- Test generation of edge cases and adversarial prompts

## 5. Test Data Management

### 5.1 Independent Test Fixtures
- Each service maintains its own test data
- No shared fixtures between services
- Fixtures designed for service-specific needs
- Version-controlled test data for consistency

### 5.2 Test Data Categories
- **Valid Cases**: Expected inputs and outputs
- **Edge Cases**: Boundary conditions and limits
- **Error Cases**: Invalid inputs and failure scenarios
- **Adversarial Cases**: Intentionally dangerous inputs designed to test security boundaries and filtering effectiveness
- **Functional Cases**: Complex scenarios for functionality validation

## 6. Test Execution Strategy

### 6.1 Development Workflow
1. **Red**: Write failing test that defines required functionality
2. **Green**: Implement minimal code to make test pass
3. **Refactor**: Improve code while keeping tests passing
4. **Integrate**: Run higher-level tests to ensure compatibility

### 6.2 Team-Specific Testing Commands

**Development Teams (Component-Level)**:
```bash
# Unit tests only (fast feedback loop)
uv run pytest tests/unit/ -v

# Component integration tests (with external LLM/config)
uv run pytest tests/integration/ -v

# Service health check
uv run python -c "import requests; print(requests.get('http://localhost:{port}/health').json())"

# Coverage reporting
uv run pytest tests/unit/ tests/integration/ --cov=src --cov-report=html
```

**QA Team (System-Level)**:
```bash
# Staged integration tests (QA environment)
pytest tests/staged/ -v --env=qa

# Full end-to-end tests (all services running)
pytest tests/e2e/ -v --env=qa

# Functional complexity tests
pytest tests/functional/ -v --env=qa

# Adversarial and security tests
pytest tests/security/ -v --env=qa
```

### 6.3 Test Configuration
Each service includes `pytest.ini` configuration:
```ini
[tool:pytest]
testpaths = tests
python_files = test_*.py
python_classes = Test*
python_functions = test_*
addopts = 
    -v
    --tb=short
    --strict-markers
markers =
    unit: Unit tests with mocked dependencies
    integration: Integration tests with real dependencies
    staged: Progressive service integration tests
    e2e: End-to-end system tests
    slow: Tests that take longer to execute
```

## 7. QA-Managed Integration Testing

### 7.1 Team Submission Process
- **Development Teams**: Focus on unit tests and component-level testing
- **Service Readiness**: Teams submit services only after all unit tests pass
- **QA Team Role**: Centralized integration testing and cross-service validation
- **Feedback Loop**: QA provides detailed integration test results back to component teams

### 7.2 Service Submission Criteria
**Before submitting to QA, each team must ensure**:
- All unit tests pass (`uv run pytest tests/unit/ -v`)
- Service runs independently (`uv run uvicorn main:app --port {service_port}`)
- Health check endpoint responds correctly
- Configuration loading works properly
- Basic smoke tests pass

### 7.3 QA Integration Testing Environment
- **QA Environment**: Dedicated testing environment managed by QA team
- **Service Deployment**: QA deploys submitted services for integration testing
- **Test Execution**: QA runs progressive staged integration tests
- **Environment Management**: QA handles service startup, configuration, and coordination

### 7.4 QA Testing Workflow
1. **Service Intake**: QA receives service submissions from development teams
2. **Environment Setup**: QA deploys services in testing environment
3. **Integration Testing**: QA executes staged integration test suites
4. **Results Analysis**: QA analyzes test results and identifies issues
5. **Feedback Delivery**: QA provides detailed feedback to component teams
6. **Iteration**: Teams fix issues and resubmit for QA validation

### 7.5 Test Isolation and Management
- **Independent Test Runs**: Each integration test can run independently
- **Environment Reset**: QA manages clean environment state between test runs
- **Service Orchestration**: QA handles service startup order and dependencies
- **Configuration Management**: QA maintains test-specific configurations

## 8. Quality Metrics and Coverage

### 8.1 Coverage Requirements
- **Unit Tests**: Minimum 90% code coverage
- **Integration Tests**: All API endpoints covered
- **Staged Tests**: All service interactions covered
- **E2E Tests**: All user scenarios covered

### 8.2 Performance Benchmarks
- Response time targets for each service
- Throughput requirements for pipeline
- Memory and CPU usage monitoring
- Timeout and retry behavior validation

## 9. Continuous Testing

### 9.1 Pre-commit Testing
- Unit tests must pass before commits
- Linting and formatting checks
- Type checking validation

### 9.2 QA Integration Testing Schedule
- **Daily Integration Runs**: QA runs integration tests on latest submitted services
- **On-Demand Testing**: QA tests specific service combinations upon request
- **Release Validation**: Complete E2E testing before any release milestones
- **Functional Regression**: Weekly functionality baseline validation
- **Security Testing**: Regular adversarial testing with updated threat scenarios

### 9.3 Feedback and Communication
- **Daily Reports**: QA provides daily integration test status to all teams
- **Issue Tracking**: Detailed issue reports with reproduction steps
- **Team Notifications**: Immediate notification of integration failures
- **Success Metrics**: Progress tracking and service readiness indicators

## 10. Service Handoff Process

### 10.1 Development Team Responsibilities
- Complete unit test coverage (>90%)
- Service runs independently with health checks
- Component integration tests pass (real external dependencies)
- Documentation includes API contracts and configuration requirements
- Service deployment instructions for QA team

### 10.2 QA Team Responsibilities
- Deploy and manage integration testing environment
- Execute comprehensive staged integration tests
- Provide detailed feedback on integration failures
- Coordinate cross-service testing scenarios
- Validate performance and security requirements

### 10.3 Handoff Documentation
**Each team provides QA with**:
- Service deployment instructions (`README.md`)
- Configuration requirements and examples
- Health check endpoint documentation
- Expected API behavior and contracts
- Known limitations or dependencies

This QA-managed approach ensures robust integration testing without requiring Docker infrastructure, while maintaining clear separation between component development and system integration validation.