import pytest

from app import app
from services import wompi_service

SANDBOX_KEYS = {
    "WOMPI_PUBLIC_KEY": "pub_test_" + "a" * 32,
    "WOMPI_PRIVATE_KEY": "prv_test_" + "b" * 32,
    "WOMPI_INTEGRITY_SECRET": "test_integrity_" + "c" * 32,
    "WOMPI_EVENTS_SECRET": "test_events_" + "d" * 32,
}
PRODUCTION_KEYS = {
    "WOMPI_PUBLIC_KEY": "pub_prod_" + "a" * 32,
    "WOMPI_PRIVATE_KEY": "prv_prod_" + "b" * 32,
    "WOMPI_INTEGRITY_SECRET": "prod_integrity_" + "c" * 32,
    "WOMPI_EVENTS_SECRET": "prod_events_" + "d" * 32,
}


@pytest.fixture()
def wompi_sandbox_config():
    original = dict(app.config)
    app.config.update(
        **SANDBOX_KEYS,
        WOMPI_ENV="sandbox",
        WOMPI_ALLOW_PRODUCTION=False,
        WOMPI_CURRENCY="COP",
        WOMPI_CHECKOUT_URL=wompi_service.OFFICIAL_CHECKOUT_URL,
        WOMPI_API_URL=wompi_service.SANDBOX_API_URL,
        WOMPI_MIN_AMOUNT=1000,
    )
    yield app.config
    app.config.clear()
    app.config.update(original)


def test_sandbox_completo_y_consistente(wompi_sandbox_config):
    with app.app_context():
        status = wompi_service.configuration_status()
        assert status == {
            "ok": True,
            "environment": "sandbox",
            "event_environment": "test",
            "missing": [],
            "issues": [],
        }
        assert wompi_service.is_configured() is True
        assert wompi_service.configured_environment() == "sandbox"
        wompi_service.ensure_configured()


def test_faltantes_se_reportan_sin_valores(wompi_sandbox_config):
    app.config["WOMPI_PUBLIC_KEY"] = ""
    app.config["WOMPI_EVENTS_SECRET"] = ""
    with app.app_context():
        status = wompi_service.configuration_status()
        assert status["ok"] is False
        assert status["missing"] == ["WOMPI_PUBLIC_KEY", "WOMPI_EVENTS_SECRET"]
        assert all(value not in str(status) for value in SANDBOX_KEYS.values())


@pytest.mark.parametrize(
    "campo,valor,problema",
    [
        ("WOMPI_PUBLIC_KEY", "pub_prod_" + "a" * 32, "prefijo_wompi_public_key"),
        ("WOMPI_PRIVATE_KEY", "prv_prod_" + "b" * 32, "prefijo_wompi_private_key"),
        ("WOMPI_INTEGRITY_SECRET", "prod_integrity_" + "c" * 32, "prefijo_wompi_integrity_secret"),
        ("WOMPI_EVENTS_SECRET", "prod_events_" + "d" * 32, "prefijo_wompi_events_secret"),
        ("WOMPI_API_URL", wompi_service.PRODUCTION_API_URL, "url_api"),
        ("WOMPI_CHECKOUT_URL", "https://example.invalid/p/", "url_checkout"),
        ("WOMPI_CURRENCY", "USD", "moneda_invalida"),
    ],
)
def test_configuracion_mixta_o_invalida_se_rechaza(
    wompi_sandbox_config, campo, valor, problema
):
    app.config[campo] = valor
    with app.app_context():
        status = wompi_service.configuration_status()
        assert status["ok"] is False
        assert problema in status["issues"]


def test_produccion_bloqueada_por_defecto(wompi_sandbox_config):
    app.config.update(
        **PRODUCTION_KEYS,
        WOMPI_ENV="prod",
        WOMPI_API_URL=wompi_service.PRODUCTION_API_URL,
        WOMPI_ALLOW_PRODUCTION=False,
    )
    with app.app_context():
        status = wompi_service.configuration_status()
        assert status["ok"] is False
        assert "produccion_bloqueada" in status["issues"]


def test_produccion_solo_si_se_autoriza_expresamente(wompi_sandbox_config):
    app.config.update(
        **PRODUCTION_KEYS,
        WOMPI_ENV="production",
        WOMPI_API_URL=wompi_service.PRODUCTION_API_URL,
        WOMPI_ALLOW_PRODUCTION=True,
    )
    with app.app_context():
        status = wompi_service.configuration_status()
        assert status["ok"] is True
        assert status["environment"] == "production"


def test_ambiente_test_es_equivalente_a_sandbox(wompi_sandbox_config):
    app.config["WOMPI_ENV"] = "test"
    with app.app_context():
        assert wompi_service.configuration_status()["ok"] is True
        assert wompi_service.configured_environment() == "sandbox"


def test_ensure_configured_falla_antes_de_usar_red(wompi_sandbox_config, monkeypatch):
    app.config["WOMPI_PRIVATE_KEY"] = ""
    with app.app_context():
        with pytest.raises(wompi_service.WompiConfigurationError) as error:
            wompi_service.fetch_transaction("1234-1234-1234")
        assert error.value.missing == ["WOMPI_PRIVATE_KEY"]
        assert "1234-1234-1234" not in str(error.value)
        with pytest.raises(wompi_service.WompiConfigurationError):
            wompi_service.build_checkout_url(reference="REF", amount=50000)
