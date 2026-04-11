class UserDatabase:
    MOCK_USERS: dict[str, dict] = {
        "alice@acme.com": {
            "id": 1,
            "email": "alice@acme.com",
            "full_name": "Alice Johnson",
            "password_hash": "$2b$12$hxpXvAGW3iONuS2cX9Eft.0IssclhTYom1esha5xIb8OdXN7g2HhG",
        },
        "bob@nova.com": {
            "id": 2,
            "email": "bob@nova.com",
            "full_name": "Bob Smith",
            "password_hash": "$2b$12$ubuSzS3JCJbKJL5Kcn98G.X5zhZ2/ykvbN0.e8lp.l9DE/A5hRpcG",
        },
        "carol@apex.com": {
            "id": 3,
            "email": "carol@apex.com",
            "full_name": "Carol Martinez",
            "password_hash": "$2b$12$5qm4MzrmNhu03UZzLGjWnuwweKpCLnp8Z9WVmGiqAgmlAMueXws3q",
        },
        "admin@inriver.com": {
            "id": 4,
            "email": "admin@inriver.com",
            "full_name": "Admin User",
            "password_hash": "$2b$12$v4Crz8c9FymN/EIk6tGII.HvC40o/K.T1TdixCbFLRygHibFANsNe",
        },
    }

    def get_user_by_email(self, email: str) -> dict | None:
        return self.MOCK_USERS.get(email)
