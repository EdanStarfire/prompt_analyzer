# Project Structure Plan

## 1. Overview
This document outlines the recommended project structure for the Prompt Filtering System.

## 2. Directory Layout
```
prompt_filtering_system/
├── config/                # Configuration files
│   ├── filtering_criteria.json
│   └── ...
├── src/                   # Source code
│   ├── __init__.py
│   ├── app.py             # Main Flask application
│   ├── components/        # Core components
│   │   ├── __init__.py
│   │   ├── prompt_proxy.py
│   │   ├── categorizer_llm.py
│   │   ├── filtering_engine.py
│   │   └── test_prompt_generator.py
│   ├── utils/             # Utility functions
│   │   ├── __init__.py
│   │   └── llm_client.py  # LLM API client
│   └── tests/             # Unit and integration tests
│       ├── __init__.py
│       ├── test_prompt_proxy.py
│       ├── test_categorizer_llm.py
│       ├── test_filtering_engine.py
│       └── test_test_prompt_generator.py
├── .gitignore             # Git ignore file
├── requirements.txt       # Python dependencies
└── README.md              # Project documentation
```

## 3. File Descriptions

### Configuration Files (config/)
- `filtering_criteria.json`: JSON configuration for filtering rules

### Source Code (src/)
- `__init__.py`: Package initializers
- `app.py`: Main Flask application entry point
- `components/`: Core system components
  - `prompt_proxy.py`: Prompt handling and routing logic
  - `categorizer_llm.py`: LLM integration for instruction categorization
  - `filtering_engine.py`: Filtering logic implementation
  - `test_prompt_generator.py`: Test prompt generation service

### Utilities (utils/)
- `llm_client.py`: Client for interacting with OpenAI-compatible LLMs

### Tests (tests/)
- Unit and integration tests for all components

## 4. Execution
All dependencies should be managed via `uv` and executed using `uv run`. Testing should use `uv run pytest`.

## 5. Todo List
- [ ] Create directory structure
- [ ] Add initial files with basic content
- [ ] Set up Git repository
- [ ] Configure `.gitignore`