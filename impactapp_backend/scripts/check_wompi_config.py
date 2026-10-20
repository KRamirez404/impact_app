import os
import sys
from pathlib import Path

from flask import Flask

ROOT = Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))


def _load_dotenv(path: Path) -> None:
    if not path.exists():
        return
    for raw in path.read_text().splitlines():
        line = raw.strip()
        if not line or line.startswith("#"):
            continue
        if line.startswith("export "):
            line = line[7:].strip()
        if "=" not in line:
            continue
        key, value = line.split("=", 1)
        value = value.strip()
        if len(value) >= 2 and value[0] == value[-1] and value[0] in "\"'":
            value = value[1:-1]
        os.environ.setdefault(key.strip(), value)


_load_dotenv(ROOT.parent / ".env")
_load_dotenv(ROOT / ".env")

from config import Config  # noqa: E402
from services import wompi_service  # noqa: E402


def main() -> int:
    app = Flask(__name__)
    app.config.from_object(Config)
    with app.app_context():
        status = wompi_service.configuration_status()
    print(f"ambiente={status['environment']}")
    print(f"configurado={'si' if status['ok'] else 'no'}")
    if status["missing"]:
        print("faltan=" + ",".join(status["missing"]))
    if status["issues"]:
        print("problemas=" + ",".join(status["issues"]))
    return 0 if status["ok"] else 1


if __name__ == "__main__":
    sys.exit(main())
