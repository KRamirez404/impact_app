from flask import Blueprint, jsonify

transfer_disabled_bp = Blueprint("transfer_disabled_bp", __name__, url_prefix="/api")


def _disabled():
    return (
        jsonify(
            {
                "error": "El módulo de transferencias no está disponible",
                "code": "transfer_feature_disabled",
            }
        ),
        503,
    )


@transfer_disabled_bp.route("/campaigns/<int:campaign_id>/bank-account", methods=["GET", "POST"])
def disabled_bank_account(campaign_id):
    return _disabled()


@transfer_disabled_bp.route("/transfers", methods=["GET", "POST"])
@transfer_disabled_bp.route("/transfers/<path:subpath>", methods=["GET", "POST"])
def disabled_transfers(subpath=None):
    return _disabled()


@transfer_disabled_bp.route("/support/transfers", methods=["GET", "POST"])
@transfer_disabled_bp.route("/support/transfers/<path:subpath>", methods=["GET", "POST"])
def disabled_support_transfers(subpath=None):
    return _disabled()


@transfer_disabled_bp.route("/financial/bank-accounts", methods=["GET", "POST"])
@transfer_disabled_bp.route("/financial/bank-accounts/<path:subpath>", methods=["GET", "POST"])
def disabled_bank_accounts(subpath=None):
    return _disabled()
