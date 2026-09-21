import argparse
import json
import os
import sys
import urllib.error
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))


def _environment_from_config() -> str:
    from flask import current_app

    from services import wompi_service

    value = current_app.config.get("WOMPI_ENV", "sandbox")
    return wompi_service.ENVIRONMENT_MAP.get(str(value).lower(), "test")


def _resolve_secret(args) -> str:
    secret = args.secret or os.getenv("WOMPI_EVENTS_SECRET")
    if not secret:
        raise SystemExit("Falta WOMPI_EVENTS_SECRET (defínelo en .env o usa --secret).")
    return secret


def _guard_environment(args) -> None:
    from flask import current_app

    environment = str(current_app.config.get("WOMPI_ENV", "sandbox")).lower()
    if environment in ("prod", "production") and not args.force:
        raise SystemExit(
            "WOMPI_ENV=prod: negándose a simular un pago en producción. "
            "Usa --force si es realmente intencional."
        )


def _create_donation(args):
    from flask import current_app

    from models import CAMPAÑA, DONACION, USUARIO, db
    from services import wompi_service
    from services.donation_integrity import compute_donation_checksum

    donante = USUARIO.query.filter_by(correo=args.donante_correo).first()
    if not donante:
        raise SystemExit(f"No existe un usuario con correo {args.donante_correo}.")
    campaign = db.session.get(CAMPAÑA, args.campaign_id)
    if not campaign:
        raise SystemExit(f"No existe la campaña {args.campaign_id}.")

    donation = DONACION(
        id_campania=campaign.id_campania,
        id_donante=donante.id_usuario,
        tipo="economica",
        monto_estimado=args.amount,
        descripcion="[SIMULADA] Donación de prueba local",
        estado_pago="pendiente",
    )
    db.session.add(donation)
    db.session.flush()
    donation.referencia_pago = wompi_service.generate_reference(donation.id_donacion)
    donation.checksum = compute_donation_checksum(
        donation, current_app.config["JWT_SECRET_KEY"]
    )
    db.session.commit()
    return donation


def _get_by_reference(reference: str):
    from models import DONACION

    return DONACION.query.filter_by(referencia_pago=reference).first()


def _resolve_donation(args):
    from models import DONACION, db

    if args.reference:
        return _get_by_reference(args.reference)
    if args.donation_id:
        return db.session.get(DONACION, args.donation_id)
    return (
        DONACION.query.filter_by(tipo="economica", estado_pago="pendiente")
        .order_by(DONACION.id_donacion.desc())
        .first()
    )


def _send_event(url: str, payload: dict) -> tuple[int, str]:
    data = json.dumps(payload).encode("utf-8")
    request = urllib.request.Request(
        url,
        data=data,
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    try:
        with urllib.request.urlopen(request, timeout=15) as response:
            return response.status, response.read().decode("utf-8")
    except urllib.error.HTTPError as error:
        return error.code, error.read().decode("utf-8")


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Simula eventos transaction.updated de Wompi firmados con WOMPI_EVENTS_SECRET."
    )
    parser.add_argument("command", choices=["create", "notify", "run"])
    parser.add_argument("--campaign-id", type=int, default=1)
    parser.add_argument("--donante-correo")
    parser.add_argument("--amount", type=float, default=50000)
    parser.add_argument("--donation-id", type=int)
    parser.add_argument("--reference")
    parser.add_argument("--latest", action="store_true")
    parser.add_argument("--status", default="APPROVED")
    parser.add_argument("--tx-id")
    parser.add_argument(
        "--url", default="http://localhost:5000/api/webhooks/wompi"
    )
    parser.add_argument("--secret")
    parser.add_argument("--environment")
    parser.add_argument("--force", action="store_true")
    args = parser.parse_args()

    from app import app
    from models import db

    with app.app_context():
        _guard_environment(args)
        secret = _resolve_secret(args)
        donation = None

        if args.command in ("create", "run"):
            if not args.donante_correo:
                raise SystemExit("Indica --donante-correo para crear la donación.")
            donation = _create_donation(args)
            print(
                f"[create] id={donation.id_donacion} "
                f"referencia={donation.referencia_pago} "
                f"monto={float(donation.monto_estimado):.0f} "
                f"estado={donation.estado_pago}"
            )
            if args.command == "create":
                return

        if donation is None:
            donation = _resolve_donation(args)
        if not donation:
            raise SystemExit(
                "No se encontró la donación (usa --donation-id/--reference o crea una)."
            )

        payload = wompi_service_build_event(args, donation, secret)
        status_code, body = _send_event(args.url, payload)
        print(
            f"[notify] status={args.status.upper()} donacion={donation.id_donacion} "
            f"-> HTTP {status_code} {body}"
        )

        db.session.expire_all()
        refreshed = _get_by_reference(donation.referencia_pago)
        if refreshed:
            print(
                f"[estado] id={refreshed.id_donacion} "
                f"estado_pago={refreshed.estado_pago} "
                f"tx={refreshed.wompi_transaction_id}"
            )


def wompi_service_build_event(args, donation, secret):
    from services import wompi_service

    environment = args.environment or _environment_from_config()
    return wompi_service.build_event(
        reference=donation.referencia_pago,
        status=args.status,
        amount_in_cents=wompi_service.amount_to_cents(donation.monto_estimado),
        secret=secret,
        transaction_id=args.tx_id,
        environment=environment,
    )


if __name__ == "__main__":
    main()
