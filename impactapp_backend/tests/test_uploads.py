import base64
from io import BytesIO
from zipfile import ZIP_DEFLATED, ZipFile

import pytest
from werkzeug.datastructures import FileStorage

from app import app
from conftest import get_token, register_user
from models import SOPORTE
from services.file_service import is_allowed_file, save_upload


PNG = base64.b64decode(
    "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+jRZkAAAAASUVORK5CYII="
)
PDF = (
    b"%PDF-1.4\n1 0 obj\n<< /Type /Catalog /Pages 2 0 R >>\nendobj\n"
    b"2 0 obj\n<< /Type /Pages /Kids [] /Count 0 >>\nendobj\n"
    b"trailer\n<< /Root 1 0 R >>\n%%EOF\n"
)


def _docx(compression=0):
    stream = BytesIO()
    with ZipFile(stream, "w", compression=compression) as archive:
        archive.writestr(
            "[Content_Types].xml",
            '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">'
            '<Override PartName="/word/document.xml" '
            'ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>'
            '</Types>',
        )
        archive.writestr(
            "word/document.xml",
            '<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">'
            '<w:body><w:p><w:r><w:t>Evidencia</w:t></w:r></w:p></w:body></w:document>',
        )
    return stream.getvalue()


def _corrupt_docx():
    content = bytearray(_docx(ZIP_DEFLATED))
    with ZipFile(BytesIO(content)) as archive:
        entry = archive.getinfo("[Content_Types].xml")
        offset = entry.header_offset + 30 + len(entry.filename.encode()) + len(entry.extra)
    content[offset:offset + 2] = b"\xff\xff"
    return bytes(content)


def _zip():
    stream = BytesIO()
    with ZipFile(stream, "w") as archive:
        archive.writestr("script.py", "print('no es un documento Word')")
    return stream.getvalue()


@pytest.mark.parametrize(
    "filename,content,mime",
    [
        ("evidencia.png", PNG, "image/png"),
        ("evidencia.PNG", PNG, "application/octet-stream"),
        ("documento.pdf", PDF, "application/pdf"),
        ("documento.pdf", PDF, "application/octet-stream"),
        ("informe.docx", _docx(), "application/octet-stream"),
    ],
    ids=["png", "png_mime_generico", "pdf", "pdf_mime_generico", "docx"],
)
def test_content_detection_accepts_allowed_files_and_preserves_stream(filename, content, mime):
    file = FileStorage(stream=BytesIO(content), filename=filename, content_type=mime)
    file.stream.seek(5)

    assert is_allowed_file(file)
    assert file.stream.tell() == 5


@pytest.mark.parametrize(
    "filename,content,mime",
    [
        ("documento.pdf", b"<script>alert(1)</script>", "application/pdf"),
        ("foto.jpg", b"#!/bin/sh\nexit 0\n", "image/jpeg"),
        ("foto.png", b"no es una imagen", "application/octet-stream"),
        ("foto.jpg", PNG, "image/jpeg"),
        ("documento.pdf", PNG, "application/pdf"),
        ("vacio.pdf", b"", "application/pdf"),
        ("script.html", PNG, "image/png"),
        ("foto", PNG, "image/png"),
        ("informe.docx", _zip(), "application/vnd.openxmlformats-officedocument.wordprocessingml.document"),
        ("corrupto.docx", _corrupt_docx(), "application/octet-stream"),
    ],
    ids=["script_pdf", "script_jpg", "texto_png", "png_jpg", "png_pdf", "vacio", "html", "sin_extension", "zip_docx", "docx_corrupto"],
)
def test_content_detection_rejects_disguised_files(filename, content, mime):
    file = FileStorage(stream=BytesIO(content), filename=filename, content_type=mime)

    assert not is_allowed_file(file)
    assert file.stream.tell() == 0


def test_save_upload_rejects_invalid_content_before_creating_directory(tmp_path):
    destination = tmp_path / "uploads"
    file = FileStorage(stream=BytesIO(b"<script>alert(1)</script>"), filename="foto.png")

    with pytest.raises(ValueError):
        save_upload(file, str(destination))

    assert not destination.exists()


def test_save_upload_preserves_entire_content_when_stream_was_read(tmp_path):
    file = FileStorage(stream=BytesIO(PNG), filename="foto.png")
    file.stream.seek(12)

    url = save_upload(file, str(tmp_path))

    assert (tmp_path / url.rsplit("/", 1)[1]).read_bytes() == PNG


@pytest.fixture()
def upload_context(client, monkeypatch, tmp_path):
    monkeypatch.setitem(app.config, "UPLOAD_FOLDER", str(tmp_path))
    correo = "organizador_archivos@test.co"
    register_user(client, rol="organizador", correo=correo)
    headers = {"Authorization": f"Bearer {get_token(client, correo)}"}
    response = client.post(
        "/api/campaigns",
        json={
            "titulo": "Campaña con evidencias",
            "descripcion": "Verificación de archivos",
            "id_ciudad": 1,
            "id_categoria": 1,
            "tipo_ayuda_requerida": "economica",
            "meta_monetaria": 500000,
            "fecha_fin": "2030-01-01",
        },
        headers=headers,
    )
    assert response.status_code == 201
    return headers, response.get_json()["id_campania"], tmp_path


@pytest.mark.parametrize("endpoint", ["/api/upload", "/api/supports"])
@pytest.mark.parametrize(
    "filename,content,mime",
    [
        ("falso.pdf", b"<script>alert(1)</script>", "application/pdf"),
        ("falso.png", b"no es una imagen", "application/octet-stream"),
        ("falso.jpg", PNG, "image/jpeg"),
        ("corrupto.docx", _corrupt_docx(), "application/octet-stream"),
    ],
    ids=["script_pdf", "texto_png", "extension_incorrecta", "docx_corrupto"],
)
def test_upload_endpoints_reject_invalid_content_without_persisting(
    client, upload_context, endpoint, filename, content, mime
):
    headers, campaign_id, upload_dir = upload_context
    response = client.post(
        endpoint,
        data={
            "id_campania": campaign_id,
            "tipo": "documento_oficial",
            "file": (BytesIO(content), filename, mime),
        },
        headers=headers,
    )

    assert response.status_code == 400
    assert "error" in response.get_json()
    assert not list(upload_dir.iterdir())
    with app.app_context():
        assert SOPORTE.query.filter_by(id_campania=campaign_id).count() == 0


@pytest.mark.parametrize("endpoint", ["/api/upload", "/api/supports"])
@pytest.mark.parametrize(
    "filename,content",
    [("foto.png", PNG), ("documento.pdf", PDF), ("informe.docx", _docx())],
    ids=["png", "pdf", "docx"],
)
def test_upload_endpoints_accept_real_content_and_save_all_bytes(
    client, upload_context, endpoint, filename, content
):
    headers, campaign_id, upload_dir = upload_context
    response = client.post(
        endpoint,
        data={
            "id_campania": campaign_id,
            "tipo": "documento_oficial",
            "file": (BytesIO(content), filename, "application/octet-stream"),
        },
        headers=headers,
    )

    assert response.status_code == 201
    body = response.get_json()
    url = body["url"] if endpoint == "/api/upload" else body["url_o_ruta"]
    assert (upload_dir / url.rsplit("/", 1)[1]).read_bytes() == content
