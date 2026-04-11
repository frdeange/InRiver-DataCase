def test_user_can_access_own_database(test_app, test_user_token):
    resp = test_app.post(
        "/api/v1/query",
        json={"question": "Show all products", "database": "db-acme"},
        headers={"Authorization": f"Bearer {test_user_token}"},
    )
    assert resp.status_code == 200
    data = resp.json()
    assert data["database"] == "db-acme"


def test_user_cannot_access_other_database(test_app, test_user_token):
    resp = test_app.post(
        "/api/v1/query",
        json={"question": "Show all products", "database": "db-nova"},
        headers={"Authorization": f"Bearer {test_user_token}"},
    )
    assert resp.status_code == 403


def test_admin_can_access_all(test_app, admin_user_token):
    for db in ["db-acme", "db-nova", "db-apex"]:
        resp = test_app.post(
            "/api/v1/query",
            json={"question": "Show all products", "database": db},
            headers={"Authorization": f"Bearer {admin_user_token}"},
        )
        assert resp.status_code == 200
        assert resp.json()["database"] == db


def test_databases_endpoint_returns_authorized_only(test_app, test_user_token, admin_user_token):
    # Alice should see only db-acme
    resp = test_app.get(
        "/api/v1/databases",
        headers={"Authorization": f"Bearer {test_user_token}"},
    )
    assert resp.status_code == 200
    dbs = resp.json()
    assert len(dbs) == 1
    assert dbs[0]["name"] == "db-acme"
    assert dbs[0]["is_default"] is True

    # Admin should see all 3
    resp = test_app.get(
        "/api/v1/databases",
        headers={"Authorization": f"Bearer {admin_user_token}"},
    )
    assert resp.status_code == 200
    dbs = resp.json()
    assert len(dbs) == 3
    assert {d["name"] for d in dbs} == {"db-acme", "db-nova", "db-apex"}
