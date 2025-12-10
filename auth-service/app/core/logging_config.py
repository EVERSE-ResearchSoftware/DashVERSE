"""
Logging configuration with automatic secret masking.

This module provides structured logging with automatic masking of sensitive
fields to prevent accidental secret exposure in logs.
"""

import logging
import re
from typing import Any, Dict


# Patterns to detect and mask sensitive fields
SENSITIVE_PATTERNS = [
    (re.compile(r'("password"\s*:\s*")([^"]+)"'), r'\1***MASKED***"'),
    (re.compile(r'("hashed_password"\s*:\s*")([^"]+)"'), r'\1***MASKED***"'),
    (re.compile(r'("jwt_secret"\s*:\s*")([^"]+)"'), r'\1***MASKED***"'),
    (re.compile(r'("secret"\s*:\s*")([^"]+)"'), r'\1***MASKED***"'),
    (re.compile(r'("token"\s*:\s*")([^"]+)"'), r'\1***MASKED***"'),
    (re.compile(r'("api_key"\s*:\s*")([^"]+)"'), r'\1***MASKED***"'),
    (re.compile(r'("database_url"\s*:\s*"[^:]+://[^:]+:)([^@]+)(@[^"]+")'), r'\1***MASKED***\3'),
]


class SecretMaskingFilter(logging.Filter):
    """
    Logging filter that automatically masks sensitive information.

    This filter intercepts log messages and applies regex patterns to mask
    sensitive fields like passwords, tokens, and secrets before they are written
    to log files or console.
    """

    def filter(self, record: logging.LogRecord) -> bool:
        """
        Mask sensitive information in the log record.

        Args:
            record: The log record to filter

        Returns:
            bool: Always returns True to allow the record to be logged
        """
        # Mask the main message
        if isinstance(record.msg, str):
            record.msg = self.mask_secrets(record.msg)

        # Mask any string arguments
        if record.args:
            if isinstance(record.args, dict):
                record.args = {k: self.mask_if_string(v) for k, v in record.args.items()}
            elif isinstance(record.args, tuple):
                record.args = tuple(self.mask_if_string(arg) for arg in record.args)

        return True

    @staticmethod
    def mask_secrets(text: str) -> str:
        """
        Apply all sensitive patterns to mask secrets in text.

        Args:
            text: The text to mask

        Returns:
            str: Text with secrets replaced by ***MASKED***
        """
        for pattern, replacement in SENSITIVE_PATTERNS:
            text = pattern.sub(replacement, text)
        return text

    @classmethod
    def mask_if_string(cls, value: Any) -> Any:
        """
        Mask value if it's a string, otherwise return as-is.

        Args:
            value: The value to potentially mask

        Returns:
            The masked value if string, otherwise the original value
        """
        if isinstance(value, str):
            return cls.mask_secrets(value)
        return value


def configure_logging(level: str = "INFO") -> None:
    """Configure application logging with secret masking."""
    # Create formatter
    formatter = logging.Formatter(
        fmt='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
        datefmt='%Y-%m-%d %H:%M:%S'
    )

    # Create console handler
    console_handler = logging.StreamHandler()
    console_handler.setLevel(level)
    console_handler.setFormatter(formatter)

    # Add secret masking filter
    secret_filter = SecretMaskingFilter()
    console_handler.addFilter(secret_filter)

    # Configure root logger
    root_logger = logging.getLogger()
    root_logger.setLevel(level)
    root_logger.addHandler(console_handler)

    # Configure uvicorn logger to use the same handler
    uvicorn_logger = logging.getLogger("uvicorn")
    uvicorn_logger.handlers = []
    uvicorn_logger.addHandler(console_handler)
    uvicorn_logger.setLevel(level)
    uvicorn_logger.propagate = False

    # Configure uvicorn access logger
    uvicorn_access = logging.getLogger("uvicorn.access")
    uvicorn_access.handlers = []
    uvicorn_access.addHandler(console_handler)
    uvicorn_access.setLevel(level)
    uvicorn_access.propagate = False


def mask_dict_secrets(data: Dict[str, Any]) -> Dict[str, Any]:
    sensitive_keys = {
        "password",
        "hashed_password",
        "jwt_secret",
        "secret",
        "token",
        "api_key",
        "database_url",
    }

    masked_data = {}
    for key, value in data.items():
        if key.lower() in sensitive_keys:
            masked_data[key] = "***MASKED***"
        elif isinstance(value, dict):
            masked_data[key] = mask_dict_secrets(value)
        elif key.lower() == "database_url" and isinstance(value, str):
            # Mask password in connection strings
            masked_data[key] = re.sub(
                r'://([^:]+):([^@]+)@',
                r'://\1:***MASKED***@',
                value
            )
        else:
            masked_data[key] = value

    return masked_data
