import hashlib
import hmac


def _amount_canonical(value) -> str:
    try:
        return f"{float(value or 0):.2f}"
    except (TypeError, ValueError):
        return str(value or 0)


def donation_canonical(d) -> str:
    return "|".join(
        [
            str(d.id_donacion or ""),
            str(d.id_campania or ""),
            str(d.id_donante or ""),
            str(d.id_punto or ""),
            str(d.tipo or ""),
            _amount_canonical(d.monto_estimado),
            (d.descripcion or ""),
            d.fecha_donacion.isoformat() if d.fecha_donacion else "",
        ]
    )


def compute_donation_checksum(d, secret: str) -> str:
    return hashlib.sha256(f"{donation_canonical(d)}::{secret}".encode("utf-8")).hexdigest()


def donation_is_intact(d, secret: str) -> bool:
    if not d.checksum:
        return True
    expected = compute_donation_checksum(d, secret)
    return hmac.compare_digest(expected, d.checksum)
