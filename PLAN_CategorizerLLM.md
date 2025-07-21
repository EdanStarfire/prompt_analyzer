# Categorizer LLM Component Plan

## 1. Overview
The Categorizer LLM is responsible for analyzing prompts and categorizing the instructions contained within them. It uses a dedicated language model to perform this classification.

## 2. Implementation Requirements
- Integrate with OpenAI-compatible LLM endpoint
- Develop API endpoints for categorization service
- Configure independently to allow future switching of LLM providers
- Implement instruction categorization logic

## 3. Dependencies
- Flask framework for API endpoints
- OpenAI-compatible LLM at `http://172.28.16.136:1234/v1`
- Model: `mistralai/devstral-small-2507`

## 4. Interfaces
### Categorization Interface
```python
def categorize_prompt(prompt: str) -> dict:
    """
    Categorize instructions within a prompt using LLM.

    Args:
        prompt: The input prompt string

    Returns:
        dict: Categorization results with instruction types and confidence scores
    """
```

## 5. Testing Requirements
- Unit tests for categorization logic
- Integration tests with actual LLM endpoint
- Error handling and edge case testing (empty prompts, invalid responses)

## 6. Execution
All dependencies should be managed via `uv` and executed using `uv run`. Testing should use `uv run pytest`.

## 7. Todo List
- [ ] Create Flask application structure for categorizer service
- [ ] Implement LLM integration with OpenAI endpoint
- [ ] Develop categorization API endpoint
- [ ] Write unit tests using pytest
- [ ] Write integration tests with actual LLM

## 8. Commit Strategy
- Create commits for significant completions:
  - After creating Flask application structure
  - After implementing LLM integration
  - After completing unit tests
  - After successful integration testing