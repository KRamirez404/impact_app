import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))


def main() -> None:
    from flask import current_app

    from app import app
    from models import DONACION, db
    from services.donation_integrity import compute_donation_checksum, donation_is_intact

    with app.app_context():
        secret = current_app.config["JWT_SECRET_KEY"]
        updated = 0
        for donation in DONACION.query.all():
            if not donation.checksum or not donation_is_intact(donation, secret):
                donation.checksum = compute_donation_checksum(donation, secret)
                updated += 1
        db.session.commit()
        print(f"checksums actualizados: {updated}")


if __name__ == "__main__":
    main()
