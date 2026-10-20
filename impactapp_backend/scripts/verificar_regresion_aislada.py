import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile


def main():
    origen = Path(__file__).resolve().parents[1]
    with tempfile.TemporaryDirectory(prefix="impactapp-regresion-") as temporal:
        raiz = Path(temporal)
        backend = raiz / "backend"
        backend.mkdir()
        for nombre in ("models", "routes", "services", "tests"):
            shutil.copytree(
                origen / nombre, backend / nombre,
                ignore=shutil.ignore_patterns("__pycache__", ".pytest_cache"),
            )
        for nombre in ("app.py", "config.py"):
            shutil.copy2(origen / nombre, backend / nombre)
        entorno = {
            "PATH": os.environ.get("PATH", "/usr/bin:/bin"),
            "HOME": temporal,
            "TMPDIR": temporal,
            "TEST_DATABASE_URL": f"sqlite:///{raiz / 'regresion.db'}",
            "JWT_SECRET_KEY": "clave-ficticia-regresion-aislada-sin-servicios-externos",
            "PYTEST_DISABLE_PLUGIN_AUTOLOAD": "1",
            "PYTHONDONTWRITEBYTECODE": "1",
            "FINANCIAL_ASSIGNMENTS_ENABLED": "0",
        }
        inicio = """
import os, socket, sys
sys.path.insert(0, os.getcwd())
def denegar(*args, **kwargs):
    raise AssertionError('Red externa deshabilitada para regresión aislada')
socket.socket.connect = denegar
socket.create_connection = denegar
import pytest
sys.exit(pytest.main(['-p', 'no:cacheprovider', '-q', 'tests']))
"""
        resultado = subprocess.run(
            [sys.executable, "-I", "-B", "-c", inicio], cwd=backend, env=entorno,
        )
        return resultado.returncode


if __name__ == "__main__":
    sys.exit(main())
