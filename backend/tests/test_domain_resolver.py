from app.auth.domain_resolver import DomainResolver


def test_acme_domain():
    resolver = DomainResolver()
    assert resolver.resolve("acme.com") == ["db-acme"]


def test_nova_domain():
    resolver = DomainResolver()
    assert resolver.resolve("nova.com") == ["db-nova"]


def test_admin_domain():
    resolver = DomainResolver()
    result = resolver.resolve("inriver.com")
    assert set(result) == {"db-acme", "db-nova", "db-apex"}


def test_unknown_domain():
    resolver = DomainResolver()
    assert resolver.resolve("unknown.com") == []
