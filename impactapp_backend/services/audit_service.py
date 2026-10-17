from models import AUDITORIA, db


def registrar(
    *,
    id_usuario: int | None = None,
    accion: str,
    descripcion: str | None = None,
    entidad: str | None = None,
    id_entidad: int | None = None,
    direccion_ip: str | None = None,
    confirmar: bool = True,
) -> AUDITORIA:
    registro = AUDITORIA(
        id_usuario=id_usuario,
        accion=accion,
        descripcion=descripcion,
        entidad=entidad,
        id_entidad=id_entidad,
        direccion_ip=direccion_ip,
    )
    db.session.add(registro)
    if confirmar:
        db.session.commit()
    return registro
