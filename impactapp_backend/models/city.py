from . import db


class CIUDAD(db.Model):
    __tablename__ = "CIUDAD"

    id_ciudad = db.Column(db.Integer, primary_key=True)
    nombre = db.Column(db.String(100), nullable=False)
    departamento = db.Column(db.String(100), nullable=False)

    def to_dict(self):
        return {
            "id_ciudad": self.id_ciudad,
            "nombre": self.nombre,
            "departamento": self.departamento,
        }

