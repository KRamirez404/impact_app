from decimal import Decimal

from models import CAMPAÑA, DONACION, SOPORTE, db


def recalculate_campaign_progress(campania: CAMPAÑA):
    if (campania.meta_monetaria or 0) <= 0:
        campania.porcentaje_avance = Decimal("0.00")
        db.session.commit()
        return

    total = db.session.query(db.func.sum(DONACION.monto_estimado)).filter(
        DONACION.id_campania == campania.id_campania, DONACION.tipo == "economica"
    ).scalar() or Decimal("0.00")

    progress = (Decimal(total) / Decimal(campania.meta_monetaria)) * Decimal("100")
    campania.porcentaje_avance = min(progress.quantize(Decimal("0.01")), Decimal("100.00"))
    db.session.commit()


def update_campaign_status_based_on_support(campania: CAMPAÑA):
    validated_count = SOPORTE.query.filter_by(
        id_campania=campania.id_campania, validado=True
    ).count()
    if validated_count >= 1 and campania.estado == "en_verificacion":
        campania.estado = "activa"
        db.session.commit()

