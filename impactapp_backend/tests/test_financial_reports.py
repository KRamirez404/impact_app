from io import BytesIO
from conftest import app, get_support_token, get_token, register_user
from models import CAMPAÑA, DONACION, INFORME_FINANCIERO, NOTIFICACION_EMAIL, db

PDF_BYTES = b"%PDF-1.4\n1 0 obj\n<<>>\nendobj\ntrailer\n<<>>\n%%EOF"


def _create_test_campaign(client, organizer_email):
    register_user(client, rol="organizador", correo=organizer_email)
    token = get_token(client, organizer_email)
    headers = {"Authorization": f"Bearer {token}"}
    res = client.post(
        "/api/campaigns",
        json={
            "titulo": "Campaña RF11 Test",
            "descripcion": "Descripción de prueba para informe financiero",
            "id_ciudad": 1,
            "id_categoria": 1,
            "tipo_ayuda_requerida": "economica",
            "meta_monetaria": 5000000,
            "fecha_fin": "2030-12-31",
        },
        headers=headers,
    )
    assert res.status_code == 201, res.get_json()
    campaign_id = res.get_json()["id_campania"]
    c = db.session.get(CAMPAÑA, campaign_id)
    c.estado = "activa"
    db.session.commit()
    return campaign_id, headers


def test_organizer_uploads_report_and_notifies_approved_donors(client, monkeypatch, tmp_path):
    monkeypatch.setitem(app.config, "UPLOAD_FOLDER", str(tmp_path))
    org_email = "org_rf11@test.co"
    donor_email = "donor_rf11@test.co"
    pending_donor = "pending_rf11@test.co"

    campaign_id, org_headers = _create_test_campaign(client, org_email)

    register_user(client, rol="donante", correo=donor_email)
    donor_token = get_token(client, donor_email)
    donor_headers = {"Authorization": f"Bearer {donor_token}"}

    register_user(client, rol="donante", correo=pending_donor)
    pending_token = get_token(client, pending_donor)
    pending_headers = {"Authorization": f"Bearer {pending_token}"}

    # Donación en especie (aprobada de inmediato)
    res_don = client.post(
        "/api/donations",
        json={
            "id_campania": campaign_id,
            "tipo": "alimentos",
            "descripcion": "Kit de víveres",
            "monto_estimado": 50000,
        },
        headers=donor_headers,
    )
    assert res_don.status_code == 201

    # Segunda donación del mismo donante para verificar que no se dupliquen correos
    client.post(
        "/api/donations",
        json={
            "id_campania": campaign_id,
            "tipo": "ropa",
            "descripcion": "Ropa de abrigo",
            "monto_estimado": 30000,
        },
        headers=donor_headers,
    )

    # Donación pendiente de otro usuario
    pending_user = register_user(client, rol="donante", correo="otro_pending@test.co")
    user_id = pending_user.get_json()["user"]["id_usuario"]
    db.session.add(
        DONACION(
            id_campania=campaign_id,
            id_donante=user_id,
            tipo="economica",
            monto_estimado=20000,
            estado_pago="pendiente",
        )
    )
    db.session.commit()

    # Cargar informe financiero
    response = client.post(
        f"/api/campaigns/{campaign_id}/financial-report",
        data={"file": (BytesIO(PDF_BYTES), "informe_financiero.pdf", "application/pdf")},
        headers=org_headers,
    )
    assert response.status_code == 201
    data = response.get_json()
    assert data["nombre_archivo"] == "informe_financiero.pdf"
    assert data["mime_type"] == "application/pdf"
    assert "ruta" in data

    report = INFORME_FINANCIERO.query.filter_by(id_campania=campaign_id).one()
    assert report.ruta == data["ruta"]

    # Debe haberse notificado al donante aprobado exactamente una vez
    notifications = NOTIFICACION_EMAIL.query.filter_by(
        tipo="informe_financiero", destinatario=donor_email
    ).all()
    assert len(notifications) == 1
    assert notifications[0].clave_evento.startswith(f"informe_financiero:{campaign_id}:")

    # El donante pendiente NO debe recibir notificación
    pending_notifs = NOTIFICACION_EMAIL.query.filter_by(
        tipo="informe_financiero", destinatario="otro_pending@test.co"
    ).all()
    assert len(pending_notifs) == 0


def test_financial_report_rejects_invalid_mime(client, monkeypatch, tmp_path):
    monkeypatch.setitem(app.config, "UPLOAD_FOLDER", str(tmp_path))
    campaign_id, org_headers = _create_test_campaign(client, "org_mime@test.co")

    res = client.post(
        f"/api/campaigns/{campaign_id}/financial-report",
        data={"file": (BytesIO(b"texto simple no pdf"), "archivo.txt", "text/plain")},
        headers=org_headers,
    )
    assert res.status_code == 400
    assert "PDF o DOCX" in res.get_json()["error"] or "formato" in res.get_json()["error"]


def test_financial_report_authorization(client, monkeypatch, tmp_path):
    monkeypatch.setitem(app.config, "UPLOAD_FOLDER", str(tmp_path))
    org_email = "org_auth@test.co"
    donor_email = "donor_auth@test.co"
    other_email = "other_auth@test.co"

    campaign_id, org_headers = _create_test_campaign(client, org_email)

    register_user(client, rol="donante", correo=donor_email)
    donor_token = get_token(client, donor_email)
    donor_headers = {"Authorization": f"Bearer {donor_token}"}

    register_user(client, rol="donante", correo=other_email)
    other_token = get_token(client, other_email)
    other_headers = {"Authorization": f"Bearer {other_token}"}

    # Otro usuario intenta cargar el informe -> 403
    res_forbidden = client.post(
        f"/api/campaigns/{campaign_id}/financial-report",
        data={"file": (BytesIO(PDF_BYTES), "informe.pdf", "application/pdf")},
        headers=other_headers,
    )
    assert res_forbidden.status_code == 403

    # Campaña inexistente -> 404
    res_not_found = client.post(
        "/api/campaigns/99999/financial-report",
        data={"file": (BytesIO(PDF_BYTES), "informe.pdf", "application/pdf")},
        headers=org_headers,
    )
    assert res_not_found.status_code == 404

    # Cargar informe legítimo por el organizador
    res_upload = client.post(
        f"/api/campaigns/{campaign_id}/financial-report",
        data={"file": (BytesIO(PDF_BYTES), "informe.pdf", "application/pdf")},
        headers=org_headers,
    )
    assert res_upload.status_code == 201

    # Donante con aporte consulta el informe -> 200
    client.post(
        "/api/donations",
        json={"id_campania": campaign_id, "tipo": "alimentos", "monto_estimado": 10000},
        headers=donor_headers,
    )
    res_get_donor = client.get(
        f"/api/campaigns/{campaign_id}/financial-report", headers=donor_headers
    )
    assert res_get_donor.status_code == 200
    assert res_get_donor.get_json()["nombre_archivo"] == "informe.pdf"

    # Organizador consulta su informe -> 200
    res_get_org = client.get(
        f"/api/campaigns/{campaign_id}/financial-report", headers=org_headers
    )
    assert res_get_org.status_code == 200

    # Soporte consulta el informe -> 200
    support_headers = {"Authorization": f"Bearer {get_support_token(client)}"}
    res_get_sup = client.get(
        f"/api/campaigns/{campaign_id}/financial-report", headers=support_headers
    )
    assert res_get_sup.status_code == 200

    # Usuario registrado que no ha donado intenta consultar -> 403
    res_get_other = client.get(
        f"/api/campaigns/{campaign_id}/financial-report", headers=other_headers
    )
    assert res_get_other.status_code == 403

    # Usuario anónimo intenta consultar -> 401
    res_anon = client.get(f"/api/campaigns/{campaign_id}/financial-report")
    assert res_anon.status_code == 401


def test_private_upload_file_protection(client, monkeypatch, tmp_path):
    monkeypatch.setitem(app.config, "UPLOAD_FOLDER", str(tmp_path))
    org_email = "org_file@test.co"
    donor_email = "donor_file@test.co"
    other_email = "other_file@test.co"

    campaign_id, org_headers = _create_test_campaign(client, org_email)

    register_user(client, rol="donante", correo=donor_email)
    donor_token = get_token(client, donor_email)
    donor_headers = {"Authorization": f"Bearer {donor_token}"}

    register_user(client, rol="donante", correo=other_email)
    other_token = get_token(client, other_email)
    other_headers = {"Authorization": f"Bearer {other_token}"}

    client.post(
        "/api/donations",
        json={"id_campania": campaign_id, "tipo": "alimentos", "monto_estimado": 10000},
        headers=donor_headers,
    )

    res_upload = client.post(
        f"/api/campaigns/{campaign_id}/financial-report",
        data={"file": (BytesIO(PDF_BYTES), "informe.pdf", "application/pdf")},
        headers=org_headers,
    )
    assert res_upload.status_code == 201
    file_ruta = res_upload.get_json()["ruta"]

    # Descarga anónima -> 401
    assert client.get(file_ruta).status_code == 401

    # Descarga por usuario no aportante -> 404
    assert client.get(file_ruta, headers=other_headers).status_code == 404

    # Descarga por donante aportante -> 200
    res_dl_donor = client.get(file_ruta, headers=donor_headers)
    assert res_dl_donor.status_code == 200
    assert res_dl_donor.data == PDF_BYTES

    # Descarga por organizador -> 200
    res_dl_org = client.get(file_ruta, headers=org_headers)
    assert res_dl_org.status_code == 200
    assert res_dl_org.data == PDF_BYTES


def test_notification_idempotency_and_email_failure_resilience(client, monkeypatch, tmp_path):
    monkeypatch.setitem(app.config, "UPLOAD_FOLDER", str(tmp_path))
    org_email = "org_idem@test.co"
    donor_email = "donor_idem@test.co"

    campaign_id, org_headers = _create_test_campaign(client, org_email)

    register_user(client, rol="donante", correo=donor_email)
    donor_token = get_token(client, donor_email)
    donor_headers = {"Authorization": f"Bearer {donor_token}"}

    client.post(
        "/api/donations",
        json={"id_campania": campaign_id, "tipo": "alimentos", "monto_estimado": 10000},
        headers=donor_headers,
    )

    # Simular fallo en proveedor de correo
    def _mock_fail_send(*args, **kwargs):
        raise ConnectionError("Fallo simulado de proveedor de correo")

    monkeypatch.setattr("services.notification_service.intentar_envio", _mock_fail_send)

    # La carga del informe NO debe fallar aunque el envío de correo falle
    res = client.post(
        f"/api/campaigns/{campaign_id}/financial-report",
        data={"file": (BytesIO(PDF_BYTES), "informe.pdf", "application/pdf")},
        headers=org_headers,
    )
    assert res.status_code == 201
    assert "ruta" in res.get_json()

    # El informe existe en BD
    assert INFORME_FINANCIERO.query.filter_by(id_campania=campaign_id).count() == 1
    notif = NOTIFICACION_EMAIL.query.filter_by(
        destinatario=donor_email, tipo="informe_financiero"
    ).first()
    assert notif is not None
    # La notificación quedó registrada con su clave idempotente
    assert notif.clave_evento.startswith(f"informe_financiero:{campaign_id}:")
