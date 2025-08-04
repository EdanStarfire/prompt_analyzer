# Project Structure Plan (Microservice Architecture)

## 1. Overview
This document outlines the recommended project structure for the microservice-based Prompt Filtering System, emphasizing independent service development while maintaining shared resources and configuration.

## 2. Root Directory Layout
```
prompt_filtering_system/
├── config/                     # Unified configuration management
│   ├── system_config.json      # Base configuration for all services
│   ├── environments/           # Environment-specific overrides
│   │   ├── development.json
│   │   ├── testing.json
│   │   ├── staging.json
│   │   └── production.json
│   ├── secrets/               # Sensitive configuration (gitignored)
│   │   ├── development_secrets.json
│   │   ├── testing_secrets.json
│   │   └── production_secrets.json
│   ├── schema/                # Configuration validation schemas
│   │   └── system_config_schema.json
│   └── examples/              # Example configurations
│       ├── minimal_development.json
│       ├── testing_environment.json
│       └── high_performance.json
├── shared/                    # Shared utilities and libraries
│   ├── __init__.py
│   ├── config_loader.py       # Configuration loading utility
│   ├── config_validator.py    # Configuration validation
│   ├── llm_client.py         # Shared LLM client interface
│   ├── error_handlers.py     # Standardized error handling
│   ├── request_models.py     # Shared Pydantic models
│   └── utils.py              # Common utility functions
├── services/                  # Independent microservices
│   ├── categorizer/          # Categorizer Service (Port 8002)
│   │   ├── pyproject.toml    # Service-specific dependencies
│   │   ├── main.py           # FastAPI application entry point
│   │   ├── api/              # API endpoints and routing
│   │   │   ├── __init__.py
│   │   │   ├── categorize.py # Categorization endpoints
│   │   │   └── health.py     # Health check endpoints
│   │   ├── core/             # Business logic
│   │   │   ├── __init__.py
│   │   │   ├── categorizer.py # Core categorization logic
│   │   │   └── models.py     # Data models and schemas
│   │   ├── tests/            # Service-specific tests
│   │   │   ├── __init__.py
│   │   │   ├── unit/         # Unit tests with mocks
│   │   │   │   ├── test_categorizer.py
│   │   │   │   └── test_api.py
│   │   │   ├── integration/  # Integration tests
│   │   │   │   ├── test_llm_integration.py
│   │   │   │   └── test_api_integration.py
│   │   │   └── fixtures/     # Test data and fixtures
│   │   │       ├── mock_llm_responses.json
│   │   │       └── sample_prompts.json
│   │   └── README.md         # Service-specific documentation
│   ├── filtering/            # Filtering Engine Service (Port 8003)
│   │   ├── pyproject.toml
│   │   ├── main.py
│   │   ├── api/
│   │   │   ├── __init__.py
│   │   │   ├── evaluate.py   # Filtering evaluation endpoints
│   │   │   └── health.py
│   │   ├── core/
│   │   │   ├── __init__.py
│   │   │   ├── filtering_engine.py # Core filtering logic
│   │   │   ├── rule_engine.py      # Rule evaluation logic
│   │   │   └── models.py
│   │   ├── tests/
│   │   │   ├── __init__.py
│   │   │   ├── unit/
│   │   │   │   ├── test_filtering_engine.py
│   │   │   │   ├── test_rule_engine.py
│   │   │   │   └── test_api.py
│   │   │   ├── integration/
│   │   │   │   ├── test_categorizer_integration.py
│   │   │   │   └── test_api_integration.py
│   │   │   └── fixtures/
│   │   │       ├── mock_categorization_data.json
│   │   │       └── filtering_test_cases.json
│   │   └── README.md
│   ├── proxy/                # Prompt Proxy Service (Port 8001)
│   │   ├── pyproject.toml
│   │   ├── main.py
│   │   ├── api/
│   │   │   ├── __init__.py
│   │   │   ├── chat_completions.py # OpenAI-compatible interface
│   │   │   ├── proxy.py           # Proxy endpoints
│   │   │   └── health.py
│   │   ├── core/
│   │   │   ├── __init__.py
│   │   │   ├── proxy_engine.py    # Pipeline orchestration
│   │   │   ├── openai_adapter.py  # OpenAI interface adaptation
│   │   │   └── models.py
│   │   ├── tests/
│   │   │   ├── __init__.py
│   │   │   ├── unit/
│   │   │   │   ├── test_proxy_engine.py
│   │   │   │   ├── test_openai_adapter.py
│   │   │   │   └── test_api.py
│   │   │   ├── integration/
│   │   │   │   ├── test_pipeline_integration.py
│   │   │   │   └── test_openai_compatibility.py
│   │   │   ├── staged/        # Progressive integration tests
│   │   │   │   ├── test_categorizer_integration.py
│   │   │   │   ├── test_filtering_integration.py
│   │   │   │   └── test_full_pipeline.py
│   │   │   └── fixtures/
│   │   │       ├── openai_request_examples.json
│   │   │       └── pipeline_test_scenarios.json
│   │   └── README.md
│   └── test_generator/       # Test Prompt Generator Service (Port 8004)
│       ├── pyproject.toml
│       ├── main.py
│       ├── api/
│       │   ├── __init__.py
│       │   ├── generate.py   # Prompt generation endpoints
│       │   └── health.py
│       ├── core/
│       │   ├── __init__.py
│       │   ├── prompt_generator.py # Core generation logic
│       │   ├── test_runner.py      # Pipeline testing logic
│       │   └── models.py
│       ├── tests/
│       │   ├── __init__.py
│       │   ├── unit/
│       │   │   ├── test_prompt_generator.py
│       │   │   ├── test_test_runner.py
│       │   │   └── test_api.py
│       │   ├── integration/
│       │   │   ├── test_llm_integration.py
│       │   │   └── test_pipeline_testing.py
│       │   └── fixtures/
│       │       ├── generation_parameters.json
│       │       └── expected_prompt_types.json
│       └── README.md
├── tests/                     # System-wide integration tests
│   ├── __init__.py
│   ├── e2e/                  # End-to-end system tests
│   │   ├── test_complete_pipeline.py
│   │   ├── test_user_scenarios.py
│   │   └── test_performance.py
│   ├── staged/               # Cross-service integration tests
│   │   ├── test_categorizer_filtering.py
│   │   ├── test_proxy_pipeline.py
│   │   └── test_full_system.py
│   ├── fixtures/             # Shared test data
│   │   ├── system_test_scenarios.json
│   │   └── performance_test_data.json
│   └── conftest.py           # Shared pytest configuration
├── docs/                     # Documentation
│   ├── api/                  # API documentation
│   │   ├── categorizer_api.md
│   │   ├── filtering_api.md
│   │   ├── proxy_api.md
│   │   └── test_generator_api.md
│   ├── deployment/           # Service execution guides
│   │   ├── development_setup.md
│   │   └── service_dependencies.md
│   ├── testing/              # Testing documentation
│   │   ├── testing_strategy.md
│   │   ├── unit_testing_guide.md
│   │   └── integration_testing_guide.md
│   └── configuration_reference.md
├── scripts/                  # Utility scripts
│   ├── setup_development.sh # Development environment setup
│   ├── run_all_tests.sh     # Test execution scripts
│   ├── start_services.sh    # Service startup script
│   └── validate_config.py   # Configuration validation script
├── logs/                    # Log files (gitignored)
│   ├── categorizer.log
│   ├── filtering.log
│   ├── proxy.log
│   └── test_generator.log
├── .gitignore              # Git ignore configuration
├── start_all_services.sh   # Multi-service startup script
├── README.md               # Project overview and setup
└── requirements-dev.txt    # Development dependencies (for tooling)
```

## 3. Service-Specific Structure Details

### 3.1 Individual Service Components
Each service (`services/{service_name}/`) contains:

**Core Components**:
- `pyproject.toml`: UV-managed dependencies and project metadata
- `main.py`: FastAPI application entry point
- `api/`: REST API endpoints and routing logic
- `core/`: Business logic implementation
- `tests/`: Comprehensive test suite (unit, integration, fixtures)
- `README.md`: Service-specific documentation with execution instructions

**Testing Structure**:
- `tests/unit/`: Unit tests with mocked dependencies
- `tests/integration/`: Integration tests with real external services
- `tests/staged/`: Progressive integration tests (proxy service only)
- `tests/fixtures/`: Service-specific test data and mock responses

### 3.2 Service Independence Requirements
- **Separate virtual environments**: Each service uses `uv` for dependency management
- **Independent execution**: Services can run standalone via `uv run main.py`
- **Self-contained testing**: All tests can run without other services
- **Clear API contracts**: Well-defined interfaces for inter-service communication

## 4. Shared Resources

### 4.1 Configuration Management
- **Unified config**: `config/system_config.json` for all services
- **Environment overrides**: Service-specific environment configurations
- **Schema validation**: JSON schema validation for configuration files
- **Secrets management**: Separate files for sensitive configuration

### 4.2 Shared Utilities (`shared/`)
- **Configuration loading**: Standardized config access patterns
- **LLM client**: Shared interface for LLM communication
- **Error handling**: Consistent error formats and handling
- **Request models**: Shared Pydantic models for API contracts
- **Utilities**: Common helper functions

### 4.3 System-Wide Testing (`tests/`)
- **End-to-end tests**: Complete system validation
- **Staged integration**: Progressive service combination testing
- **Shared fixtures**: Common test data for cross-service testing
- **Performance tests**: System-wide performance validation

## 5. Development Workflow

### 5.1 Service Development Process
1. **Initialize service**: `cd services/{service_name} && uv init`
2. **Add dependencies**: `uv add fastapi uvicorn pytest`
3. **Implement TDD**: Write tests first, then implementation
4. **Run service**: `uv run uvicorn main:app --host 0.0.0.0 --port {port}`
5. **Test service**: `uv run pytest tests/`

### 5.2 Cross-Service Integration
1. **Start dependencies**: Ensure required services are running
2. **Run staged tests**: `uv run pytest tests/staged/`
3. **Validate integration**: Check API contracts and error handling
4. **Performance testing**: Validate response times and throughput

### 5.3 System Testing
1. **Start all services**: Use `start_all_services.sh` or individual startup commands
2. **Run E2E tests**: `pytest tests/e2e/`
3. **Performance validation**: Execute load and stress tests
4. **User scenario testing**: Validate complete user workflows

## 6. Configuration and Environment Setup

### 6.1 Development Environment
- All services use shared configuration from `config/system_config.json`
- Environment variables for service-specific overrides
- Local development ports (8001-8004) as defined in configuration
- Shared logging configuration for consistent log formats

### 6.2 Testing Environment
- Separate test configuration in `config/environments/testing.json`
- Mock external services for unit testing
- Real service integration for integration testing
- Isolated test databases and resources

### 6.3 Production Environment
- Service-specific configuration files split from unified config
- Environment variables for sensitive configuration
- Service discovery integration for inter-service communication
- Centralized logging and monitoring configuration

## 7. Service Execution

### 7.1 Direct Execution Strategy
- Each service runs via `uv run uvicorn main:app --port {port}`
- Dependencies managed through `uv` virtual environments
- Simple shell scripts for multi-service coordination
- Process-based service management for development and testing

### 7.2 Service Dependencies
- Clear startup order: Categorizer → Filtering → Proxy → Test Generator
- Health check endpoints for dependency validation
- Graceful degradation for service failures
- Circuit breaker patterns for resilience

## 8. Migration from Monolithic Structure

### 8.1 Gradual Migration
- Current structure can be migrated incrementally
- Services can be extracted one at a time
- Shared utilities provide compatibility during transition
- Configuration can be split gradually

### 8.2 Backward Compatibility
- Shared utilities maintain consistent interfaces
- Configuration changes are backward compatible
- API versioning supports gradual migration
- Testing ensures no functionality regression

This microservice project structure provides complete independence for service development while maintaining shared resources and clear integration points for system-wide functionality.