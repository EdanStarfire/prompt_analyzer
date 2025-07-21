# Test Prompt Generator Component Plan

## 1. Overview
The Test Prompt Generator creates complexity prompts using an LLM and runs them through the filtering service for testing purposes.

## 2. Implementation Requirements
- Develop LLM-powered tool for generating complexity prompts
- Create API endpoints for prompt generation service
- Run generated prompts through the filtering service as part of testing

## 3. Dependencies
- Flask framework for API endpoints
- OpenAI-compatible LLM at `http://172.28.16.136:1234/v1`
- Model: `mistralai/devstral-small-2507`
- Prompt Proxy component for testing

## 4. Interfaces
### Generation Interface
```python
def generate_test_prompt() -> dict:
    """
    Generate a complexity test prompt using LLM.

    Returns:
        dict: Generated prompt with metadata
    """
```

## 5. Testing Requirements
- Unit tests for prompt generation logic
- Integration tests with actual LLM endpoint
- End-to-end testing with filtering service

## 6. Execution
All dependencies should be managed via `uv` and executed using `uv run`. Testing should use `uv run pytest`.

## 7. Todo List
- [ ] Create Flask application structure for test prompt generator
- [ ] Implement LLM integration for prompt generation
- [ ] Develop generation API endpoint
- [ ] Write unit tests using pytest
- [ ] Write integration tests with actual LLM

## 8. Commit Strategy
- Create commits for significant completions:
  - After creating Flask application structure
  - After implementing LLM integration
  - After completing unit tests
  - After successful integration testing