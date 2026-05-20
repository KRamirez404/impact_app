from flask_sqlalchemy import SQLAlchemy

db = SQLAlchemy()

from .user import USUARIO  # noqa: E402,F401
from .city import CIUDAD  # noqa: E402,F401
from .category import CATEGORIA  # noqa: E402,F401
from .campaign import CAMPAÑA  # noqa: E402,F401
from .donation import DONACION  # noqa: E402,F401
from .rating import VALORACION  # noqa: E402,F401
from .support import SOPORTE  # noqa: E402,F401
from .tracking import SEGUIMIENTO  # noqa: E402,F401
from .collection_point import PUNTO_RECOLECCION  # noqa: E402,F401
from .reaction import REACCION  # noqa: E402,F401
