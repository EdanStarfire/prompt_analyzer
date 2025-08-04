# Configuration Management Plan

## 1. Overview
This document defines the unified configuration strategy for all microservices, ensuring streamlined development and testing while maintaining flexibility for production deployment and service-specific customizations.

## 2. Configuration Philosophy

### 2.1 Unified Development Configuration
- Single configuration file for all services during development and testing
- Reduces complexity and coordination overhead between teams
- Simplifies environment setup and testing scenarios
- Clear separation between shared and service-specific configurations

### 2.2 Production Flexibility
- Configuration structure designed for easy splitting in production
- Service-specific overrides supported
- Environment-based configuration management
- Secrets and sensitive data handling

### 2.3 Configuration as Code
- Version-controlled configuration files
- Schema validation for all configuration sections
- Documentation and examples for all configuration options
- Change tracking and rollback capabilities

## 3. Unified Configuration Structure

### 3.1 Main Configuration File
**Location**: `config/system_config.json`
**Purpose**: Central configuration for all services and shared resources

```json
{
  "metadata": {
    "version": "1.0.0",
    "created": "2024-01-01T00:00:00Z",
    "description": "Unified configuration for Prompt Filtering System",
    "environment": "development"
  },
  "llm": {
    "endpoint": "http://172.28.16.136:1234/v1",
    "api_key": "-",
    "model": "mistralai/devstral-small-2507",
    "request_timeout_seconds": 300,
    "max_retries": 2,
    "retry_delay_seconds": 5
  },
  "services": {
    "categorizer": {
      "url": "http://localhost:8002",
      "timeout_seconds": 15,
      "max_retries": 2
    },
    "filtering": {
      "url": "http://localhost:8003", 
      "timeout_seconds": 10,
      "max_retries": 2
    },
    "proxy": {
      "url": "http://localhost:8001",
      "timeout_seconds": 360,
      "max_retries": 1
    },
    "test_generator": {
      "url": "http://localhost:8004",
      "timeout_seconds": 300,
      "max_retries": 2
    }
  },
  "categorization": {
    "confidence_threshold": 0.7,
    "categories": {
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
      },
      "explicit_content": {
        "description": "Adult or sexually explicit content",
        "examples": ["sexual content", "adult material", "intimate details"]
      },
      "personal_information": {
        "description": "Requests involving personal or private information",
        "examples": ["personal details", "private data", "confidential information"]
      }
    },
    "analysis_options": {
      "include_confidence_scores": true,
      "detailed_analysis": true,
      "context_window_size": 2048
    }
  },
  "filtering": {
    "default_mode": "standard",
    "modes": {
      "strict": {
        "description": "Strict filtering with low tolerance",
        "confidence_threshold": 0.6,
        "blocked_categories": ["harmful_content", "explicit_content", "personal_information"],
        "allow_borderline": false
      },
      "standard": {
        "description": "Balanced filtering approach",
        "confidence_threshold": 0.8,
        "blocked_categories": ["harmful_content", "explicit_content"],
        "allow_borderline": true
      },
      "permissive": {
        "description": "Minimal filtering for development",
        "confidence_threshold": 0.9,
        "blocked_categories": ["harmful_content"],
        "allow_borderline": true
      }
    },
    "rules": [
      {
        "name": "block_high_confidence_harmful",
        "type": "category_confidence",
        "category": "harmful_content",
        "threshold": 0.8,
        "action": "block",
        "enabled": true
      },
      {
        "name": "block_explicit_content",
        "type": "category_match",
        "category": "explicit_content",
        "action": "block",
        "enabled": true
      },
      {
        "name": "review_personal_information",
        "type": "category_confidence",
        "category": "personal_information",
        "threshold": 0.7,
        "action": "review",
        "enabled": false
      }
    ]
  },
  "logging": {
    "level": "INFO",
    "format": "json",
    "include_request_id": true,
    "log_requests": true,
    "log_responses": false,
    "log_sensitive_data": false,
    "files": {
      "categorizer": "logs/categorizer.log",
      "filtering": "logs/filtering.log",
      "proxy": "logs/proxy.log",
      "test_generator": "logs/test_generator.log"
    }
  },
  "testing": {
    "test_data_path": "tests/fixtures",
    "mock_llm_responses": true,
    "integration_test_timeout": 360,
    "performance_test_enabled": true,
    "load_test_concurrent_requests": 10
  },
  "development": {
    "debug_mode": true,
    "auto_reload": true,
    "cors_enabled": true,
    "detailed_error_responses": true,
    "mock_external_services": false
  }
}
```

### 3.2 Environment-Specific Overrides
**Location**: `config/environments/`
**Purpose**: Environment-specific configuration overrides

**Structure**:
```
config/
├── system_config.json           # Base configuration
├── environments/
│   ├── development.json         # Development overrides
│   ├── testing.json            # Testing environment overrides
│   ├── staging.json            # Staging environment overrides
│   └── production.json         # Production environment overrides
└── secrets/                    # Sensitive configuration (gitignored)
    ├── development_secrets.json
    ├── testing_secrets.json
    └── production_secrets.json
```

**Example Environment Override** (`config/environments/production.json`):
```json
{
  "metadata": {
    "environment": "production"
  },
  "llm": {
    "endpoint": "${LLM_ENDPOINT}",
    "api_key": "${LLM_API_KEY}",
    "request_timeout_seconds": 300
  },
  "services": {
    "categorizer": {
      "url": "https://categorizer.internal.company.com"
    },
    "filtering": {
      "url": "https://filtering.internal.company.com"
    },
    "proxy": {
      "url": "https://proxy.internal.company.com"
    }
  },
  "logging": {
    "level": "WARN",
    "log_requests": false,
    "log_responses": false,
    "files": {
      "categorizer": "/var/log/categorizer/app.log",
      "filtering": "/var/log/filtering/app.log",
      "proxy": "/var/log/proxy/app.log",
      "test_generator": "/var/log/test_generator/app.log"
    }
  },
  "development": {
    "debug_mode": false,
    "auto_reload": false,
    "detailed_error_responses": false
  }
}
```

## 4. Service-Specific Configuration Access

### 4.1 Configuration Loading Pattern
Each service loads configuration using a standard pattern:

```python
# config_loader.py (shared utility)
import json
import os
from typing import Dict, Any
from pathlib import Path

class ConfigLoader:
    def __init__(self, service_name: str):
        self.service_name = service_name
        self.config = self._load_config()
    
    def _load_config(self) -> Dict[str, Any]:
        # Load base configuration
        base_config_path = Path("config/system_config.json")
        with open(base_config_path) as f:
            config = json.load(f)
        
        # Apply environment-specific overrides
        environment = os.getenv("ENVIRONMENT", "development")
        env_config_path = Path(f"config/environments/{environment}.json")
        
        if env_config_path.exists():
            with open(env_config_path) as f:
                env_config = json.load(f)
                config = self._merge_configs(config, env_config)
        
        # Load secrets if available
        secrets_path = Path(f"config/secrets/{environment}_secrets.json")
        if secrets_path.exists():
            with open(secrets_path) as f:
                secrets = json.load(f)
                config = self._merge_configs(config, secrets)
        
        # Resolve environment variables
        config = self._resolve_env_vars(config)
        
        return config
    
    def get_service_config(self) -> Dict[str, Any]:
        """Get configuration relevant to this service"""
        return {
            "llm": self.config["llm"],
            "services": self.config["services"],
            "logging": self.config["logging"],
            "development": self.config["development"],
            f"{self.service_name}_specific": self.config.get(self.service_name, {})
        }
    
    def get_categorization_config(self) -> Dict[str, Any]:
        """Get categorization-specific configuration"""
        return self.config["categorization"]
    
    def get_filtering_config(self) -> Dict[str, Any]:
        """Get filtering-specific configuration"""
        return self.config["filtering"]
    
    def get_testing_config(self) -> Dict[str, Any]:
        """Get testing-specific configuration"""
        return self.config["testing"]
```

### 4.2 Service-Specific Usage Examples

**Categorizer Service**:
```python
# categorizer/main.py
from config_loader import ConfigLoader

config = ConfigLoader("categorizer")
service_config = config.get_service_config()
categorization_config = config.get_categorization_config()

# Access LLM configuration
llm_endpoint = service_config["llm"]["endpoint"]
llm_model = service_config["llm"]["model"]

# Access categorization settings
confidence_threshold = categorization_config["confidence_threshold"]
categories = categorization_config["categories"]
```

**Filtering Engine Service**:
```python
# filtering/main.py
from config_loader import ConfigLoader

config = ConfigLoader("filtering")
service_config = config.get_service_config()
filtering_config = config.get_filtering_config()

# Access service URLs
categorizer_url = service_config["services"]["categorizer"]["url"]

# Access filtering rules
filtering_rules = filtering_config["rules"]
default_mode = filtering_config["default_mode"]
```

## 5. Configuration Validation

### 5.1 JSON Schema Validation
**Location**: `config/schema/system_config_schema.json`
**Purpose**: Validate configuration structure and data types

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "type": "object",
  "required": ["metadata", "llm", "services", "categorization", "filtering"],
  "properties": {
    "metadata": {
      "type": "object",
      "required": ["version", "environment"],
      "properties": {
        "version": {"type": "string", "pattern": "^\\d+\\.\\d+\\.\\d+$"},
        "environment": {"type": "string", "enum": ["development", "testing", "staging", "production"]}
      }
    },
    "llm": {
      "type": "object",
      "required": ["endpoint", "model"],
      "properties": {
        "endpoint": {"type": "string", "format": "uri"},
        "model": {"type": "string", "minLength": 1},
        "request_timeout_seconds": {"type": "integer", "minimum": 1, "maximum": 600}
      }
    },
    "services": {
      "type": "object",
      "patternProperties": {
        "^(categorizer|filtering|proxy|test_generator)$": {
          "type": "object",
          "required": ["url"],
          "properties": {
            "url": {"type": "string", "format": "uri"},
            "timeout_seconds": {"type": "integer", "minimum": 1, "maximum": 600}
          }
        }
      }
    }
  }
}
```

### 5.2 Configuration Validation Utility
```python
# config_validator.py
import json
import jsonschema
from pathlib import Path

class ConfigValidator:
    def __init__(self, schema_path: str = "config/schema/system_config_schema.json"):
        with open(schema_path) as f:
            self.schema = json.load(f)
    
    def validate_config(self, config: dict) -> tuple[bool, str]:
        """Validate configuration against schema"""
        try:
            jsonschema.validate(config, self.schema)
            return True, "Configuration is valid"
        except jsonschema.ValidationError as e:
            return False, f"Configuration validation error: {e.message}"
    
    def validate_file(self, config_path: str) -> tuple[bool, str]:
        """Validate configuration file"""
        try:
            with open(config_path) as f:
                config = json.load(f)
            return self.validate_config(config)
        except json.JSONDecodeError as e:
            return False, f"JSON parsing error: {e.msg}"
        except FileNotFoundError:
            return False, f"Configuration file not found: {config_path}"
```

## 6. Configuration Management Best Practices

### 6.1 Development Workflow
1. **All changes to base configuration** require team coordination
2. **Environment-specific overrides** can be modified independently
3. **Schema validation** required before committing configuration changes
4. **Configuration documentation** updated with all changes

### 6.2 Security Considerations
- **Never commit secrets** to version control
- **Use environment variables** for sensitive configuration in production
- **Separate secrets files** with restricted access permissions
- **Audit configuration changes** through version control

### 6.3 Testing Configuration
- **Test configuration files** for different environments
- **Configuration validation tests** in CI/CD pipeline
- **Default test configurations** for development and testing
- **Configuration change impact testing**

## 7. Configuration Documentation

### 7.1 Configuration Reference
**Location**: `docs/configuration_reference.md`
**Purpose**: Complete documentation of all configuration options

### 7.2 Configuration Examples
**Location**: `config/examples/`
**Purpose**: Example configurations for different use cases

**Structure**:
```
config/examples/
├── minimal_development.json     # Minimal config for local development
├── testing_environment.json    # Configuration for automated testing
├── high_performance.json       # Optimized for performance testing
└── security_focused.json       # Security-focused configuration
```

## 8. Migration and Evolution

### 8.1 Configuration Versioning
- **Semantic versioning** for configuration schema
- **Migration scripts** for configuration updates
- **Backward compatibility** support during transitions
- **Deprecation notices** for configuration changes

### 8.2 Production Migration Strategy
- **Gradual migration** from unified to service-specific configs
- **Service-specific configuration splitting** tools
- **Configuration distribution mechanisms**
- **Rollback procedures** for configuration changes

This unified configuration management strategy streamlines development and testing while providing the flexibility needed for production deployment and service-specific customizations.