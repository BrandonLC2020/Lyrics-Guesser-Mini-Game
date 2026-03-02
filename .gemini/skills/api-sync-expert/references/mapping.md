# API Sync Expert Mapping

## Type Conversions

| Python (Pydantic) | Dart (Dio/JSON) | Example |
| :--- | :--- | :--- |
| `str` | `String` | `game_token` -> `gameToken` |
| `int` | `int` | `hint_length` -> `hintLength` |
| `float` | `double` | `match_score` -> `matchScore` |
| `bool` | `bool` | `is_correct` -> `isCorrect` |
| `list[T]` | `List<T>` | `rounds` -> `rounds` |
| `dict[str, T]` | `Map<String, T>` | |
| `T \| None` | `T?` | `album_cover_url` -> `albumCoverUrl` |
| `Union[T, U]` | `dynamic` or custom wrapper | |

## Field Naming Convention

- **Backend (Python)**: `snake_case`
- **Frontend (Dart)**: `camelCase`
- **JSON keys**: Always `snake_case` (use `json['field_name']` in Dart factory)

## Workflow

1.  Identify change in `backend/app/schemas/`.
2.  Locate corresponding file in `frontend/lib/networking/dto/`.
3.  Update Dart class fields, constructor, and `fromJson` factory.
4.  If a new schema is created, create a new `.dart` file following the existing patterns.
