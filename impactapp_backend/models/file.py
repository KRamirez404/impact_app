from . import db


class ARCHIVO(db.Model):
    __tablename__ = "ARCHIVO"

    id_archivo = db.Column(db.Integer, primary_key=True)
    ruta = db.Column(db.String(255), unique=True, nullable=False)
    id_usuario = db.Column(
        db.Integer, db.ForeignKey("USUARIO.id_usuario"), nullable=False
    )

    usuario = db.relationship("USUARIO", backref="archivos")

    def to_dict(self):
        return {
            "id_archivo": self.id_archivo,
            "ruta": self.ruta,
            "id_usuario": self.id_usuario,
        }
