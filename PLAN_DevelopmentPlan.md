# Prompt Filtering System Development Plan (Microservice Architecture)

## 1. Project Setup
- Git repository already configured in project directory
- Establish microservice project structure with independent service directories
- No CI/CD system initially; AI agents handle testing and validation
- All development and testing done using `uv` toolchain exclusively

## 2. Technology Stack
- **Framework**: FastAPI with async/await support for all services
- **Package Management**: `uv` exclusively (`uv init`, `uv add`, `uv run`)
- **Testing Framework**: pytest with `uv run pytest`
- **LLM Integration**:
  - OpenAI endpoint: `http://172.28.16.136:1234/v1`
  - API key: `-` (no authentication needed)
  - Model: `mistralai/devstral-small-2507`
- **Configuration**: Unified JSON configuration for all services
- **Communication**: REST APIs between independent services

## 3. Microservice Architecture
### 3.1 Independent Services
- **Categorizer Service** (Port 8002): LLM-powered prompt categorization
- **Filtering Engine Service** (Port 8003): Rule-based filtering decisions
- **Prompt Proxy Service** (Port 8001): OpenAI-compatible interface with pipeline orchestration
- **Test Prompt Generator Service** (Port 8004): Test prompt generation and validation

### 3.2 Service Communication
- Direct REST API calls between services
- Graceful error handling with full debug information propagation
- Unified configuration management across all services
- Request ID propagation for distributed tracing

### 3.3 Development Independence
- Each service can be developed, tested, and run independently
- Clear API contracts defined upfront minimize team coordination
- Services use mocked dependencies for unit testing
- Progressive integration testing validates service interactions

## 4. Test-Driven Development Framework
### 4.1 Four-Level Testing Pyramid
- **Level 1**: Unit tests with mocked dependencies (`uv run pytest tests/unit/`)
- **Level 2**: Component integration tests with real external services (`uv run pytest tests/integration/`)
- **Level 3**: Progressive staged integration tests (`uv run pytest tests/staged/`)
- **Level 4**: End-to-end system tests (`uv run pytest tests/e2e/`)

### 4.2 TDD Principles
- Write tests before implementation for all functionality
- Tests define contracts and expected behavior
- Implementation must satisfy tests (not vice versa)
- Independent test fixtures per service

## 5. Execution Strategy
### 5.1 Phase-by-Phase Development
- **Phase 1**: Categorizer Service (Foundation - 2-3 weeks)
- **Phase 2**: Filtering Engine Service (Business Logic - 2-3 weeks)
- **Phase 3**: Prompt Proxy Service (Orchestration - 3-4 weeks)
- **Phase 4**: Test Prompt Generator Service (Testing Utility - 2-3 weeks)

### 5.2 Team Coordination
- Each phase can be developed by independent teams
- API contracts defined upfront minimize coordination requirements
- Clear handoff points between phases
- Mock services enable parallel development

## 6. Configuration Management
- Unified `config/system_config.json` for all services
- Environment-specific configuration overrides
- JSON schema validation for configuration files
- Service-specific configuration access patterns

## 7. Quality Assurance
- TDD-first approach with comprehensive test coverage
- Progressive integration testing strategy
- Performance benchmarking for each service
- Error handling validation across service boundaries
- All testing executed via `uv run pytest` commands

## 8. Development Standards
### 8.1 UV Toolchain Usage
- **Project Initialization**: `uv init` for each service
- **Dependency Management**: `uv add package_name` (never pip/poetry)
- **Code Execution**: `uv run main.py` or `uv run uvicorn main:app`
- **Testing**: `uv run pytest` with appropriate test level flags
- **Virtual Environment**: Automatic via `uv` (no manual venv management)

### 8.2 Service Structure
- Each service maintains independent `pyproject.toml`
- Service-specific dependencies managed separately
- Independent Docker containers for deployment
- Consistent FastAPI patterns across all services

## 9. Documentation Requirements
- Comprehensive API documentation for each service
- Configuration schema documentation with examples
- Testing guides for each service and integration level
- Deployment and operational documentation
- User guides for the complete system

## 10. Implementation Guidelines
### 10.1 Service Development Process
1. **TDD Setup**: Write comprehensive unit tests first
2. **Core Implementation**: Implement service logic to pass tests
3. **API Integration**: Implement FastAPI endpoints
4. **Integration Testing**: Test with real external dependencies
5. **Documentation**: Complete API docs and usage examples

### 10.2 Cross-Service Integration
1. **API Contract Definition**: Define and document service interfaces
2. **Mock Implementation**: Create mocks for downstream services
3. **Progressive Testing**: Test service combinations systematically
4. **Error Handling**: Validate error propagation across services
5. **Performance Validation**: Ensure acceptable response times

This microservice architecture ensures independent development capabilities while maintaining system integrity through well-defined interfaces and comprehensive testing strategies.