import argparse
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from app import app  # noqa: E402
from services.notification_service import enviar_pendientes  # noqa: E402


def main(argv=None) -> int:
    parser = argparse.ArgumentParser(
        description="Reintenta el envío de notificaciones por correo pendientes."
    )
    parser.add_argument("--limit", type=int, default=50)
    args = parser.parse_args(argv)
    with app.app_context():
        result = enviar_pendientes(limit=args.limit)
    print(f"procesadas={result['procesadas']}")
    print(f"enviadas={result['enviadas']}")
    print(f"fallidas={result['fallidas']}")
    return 0 if result["fallidas"] == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
