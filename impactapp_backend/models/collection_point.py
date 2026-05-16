from . import db


class PUNTO_RECOLECCION(db.Model):
    __tablename__ = "PUNTO_RECOLECCION"

    id_punto = db.Column(db.Integer, primary_key=True)
    id_campania = db.Column(
        db.Integer, db.ForeignKey("CAMPAÑA.id_campania"), nullable=False
    )
    id_ciudad = db.Column(db.Integer, db.ForeignKey("CIUDAD.id_ciudad"), nullable=False)
    nombre = db.Column(db.String(150), nullable=False)
    direccion = db.Column(db.String(255), nullable=False)
    horario = db.Column(db.String(150), nullable=False)
    contacto = db.Column(db.String(100), nullable=False)

    ciudad = db.relationship("CIUDAD", backref="puntos_recoleccion")

    def to_dict(self):
        return {
            "id_punto": self.id_punto,
            "id_campania": self.id_campania,
            "id_ciudad": self.id_ciudad,
            "nombre": self.nombre,
            "direccion": self.direccion,
            "horario": self.horario,
            "contacto": self.contacto,
        }

