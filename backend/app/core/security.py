from itsdangerous import URLSafeSerializer

from .config import SECRET_KEY

_serializer = URLSafeSerializer(SECRET_KEY)


def create_game_token(payload: dict) -> str:
    return _serializer.dumps(payload)


def decode_game_token(token: str) -> dict:
    return _serializer.loads(token)
