import argparse
import sys
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from app import app  # noqa: E402
from services.notification_service import enviar_pendientes  # noqa: E402


def _excluidas(valores):
    resultado = []
    for valor in valores or ():
        for parte in str(valor).split(","):
            if parte.strip():
                resultado.append(parte.strip())
    return resultado


def _imprimir(resultado, prefijo=""):
    print(f"{prefijo}procesadas={resultado['procesadas']}", flush=True)
    print(f"{prefijo}enviadas={resultado['enviadas']}", flush=True)
    print(f"{prefijo}fallidas={resultado['fallidas']}", flush=True)


def main(argv=None) -> int:
    parser = argparse.ArgumentParser(
        description="Reintenta el envío de notificaciones por correo pendientes."
    )
    parser.add_argument("--limit", type=int, default=50)
    parser.add_argument(
        "--exclude-id",
        action="append",
        default=[],
        help="ID de notificación a omitir (repetible o separado por comas).",
    )
    parser.add_argument(
        "--loop",
        action="store_true",
        help="Ejecuta el procesamiento periódicamente como worker externo.",
    )
    parser.add_argument("--interval", type=int, default=60)
    args = parser.parse_args(argv)

    if args.loop:
        intervalo = max(5, args.interval)
        try:
            while True:
                with app.app_context():
                    resultado = enviar_pendientes(
                        limit=args.limit,
                        exclude_ids=_excluidas(args.exclude_id),
                    )
                _imprimir(resultado, prefijo="[worker] ")
                time.sleep(intervalo)
        except KeyboardInterrupt:
            return 0

    with app.app_context():
        result = enviar_pendientes(
            limit=args.limit,
            exclude_ids=_excluidas(args.exclude_id),
        )
    _imprimir(result)
    return 0 if result["fallidas"] == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
