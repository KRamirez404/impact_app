import argparse
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from app import app  # noqa: E402
from routes.wompi_routes import reconcile_pending_donations  # noqa: E402


def main(argv=None) -> int:
    parser = argparse.ArgumentParser(
        description="Concilia donaciones económicas pendientes contra Wompi."
    )
    parser.add_argument("--limit", type=int, default=50)
    parser.add_argument("--min-age-minutes", type=int, default=10)
    parser.add_argument("--max-age-hours", type=int, default=72)
    args = parser.parse_args(argv)
    with app.app_context():
        result = reconcile_pending_donations(
            limit=args.limit,
            min_age_minutes=args.min_age_minutes,
            max_age_hours=args.max_age_hours,
        )
    print(f"revisadas={result['revisadas']}")
    print(f"verificadas={result['verificadas']}")
    print(f"sin_transaccion={result['sin_transaccion']}")
    print(f"sin_cambio={result['sin_cambio']}")
    print(f"errores={result['errores']}")
    if result["detenido_por"]:
        print(f"detenido_por={result['detenido_por']}")
    return 0 if result["errores"] == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
