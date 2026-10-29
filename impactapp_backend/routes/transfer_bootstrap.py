def register_transfer_blueprints(app):
    from services.transfer_config import configuration_status

    if not app.config.get("TRANSFERENCIAS_ENABLED", False):
        return
    try:
        status = configuration_status()
    except Exception:
        app.logger.exception("No fue posible verificar el esquema de transferencias")
        from .transfer_disabled_routes import transfer_disabled_bp

        app.register_blueprint(transfer_disabled_bp)
        return
    if not status["ok"]:
        app.logger.warning(
            "Transferencias no disponibles (faltan=%s, problemas=%s)",
            ",".join(status["missing"]) or "ninguna",
            ",".join(status["issues"]) or "ninguno",
        )
        from .transfer_disabled_routes import transfer_disabled_bp

        app.register_blueprint(transfer_disabled_bp)
        return
    from .transfer_routes import transfer_bp

    app.register_blueprint(transfer_bp)
