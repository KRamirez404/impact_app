from .auth_routes import auth_bp
from .campaign_routes import campaign_bp
from .collection_point_routes import collection_point_bp
from .donation_routes import donation_bp
from .rating_routes import rating_bp
from .support_routes import support_bp
from .tracking_routes import tracking_bp


def register_blueprints(app):
    app.register_blueprint(auth_bp)
    app.register_blueprint(campaign_bp)
    app.register_blueprint(donation_bp)
    app.register_blueprint(support_bp)
    app.register_blueprint(tracking_bp)
    app.register_blueprint(collection_point_bp)
    app.register_blueprint(rating_bp)

