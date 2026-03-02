---
name: api-sync-expert
description: Synchronizes Python/Pydantic schemas with Flutter/Dart DTO models. Use when changing backend API responses or adding new endpoints that require frontend model updates.
---

# API Sync Expert

This skill ensures consistent data models between the FastAPI backend and Flutter frontend.

## Workflow

1.  **Detection**: Monitor changes in `backend/app/schemas/`.
2.  **Mapping**: Reference [mapping.md](references/mapping.md) for type and naming conversions.
3.  **Application**: Update the corresponding Dart files in `frontend/lib/networking/dto/`.
4.  **Verification**: Ensure all fields in the Dart `fromJson` factory match the Python Pydantic field names exactly as they appear in JSON.

## Guiding Principles

- **Snake to Camel**: Always convert `snake_case` Python fields to `camelCase` Dart properties.
- **Maintain JSON Keys**: Ensure the `json['snake_case_key']` mapping remains correct.
- **Nullability**: Respect Python's Optional/None types by using Dart's `?` nullable operator.
- **Default Values**: Match default values from Pydantic (e.g., `default_factory=list` maps to `?? []` in Dart).
