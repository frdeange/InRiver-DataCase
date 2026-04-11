class DomainResolver:
    DOMAIN_MAP: dict[str, list[str]] = {
        "acme.com": ["db-acme"],
        "nova.com": ["db-nova"],
        "apex.com": ["db-apex"],
        "inriver.com": ["db-acme", "db-nova", "db-apex"],
    }

    def resolve(self, domain: str) -> list[str]:
        return self.DOMAIN_MAP.get(domain, [])
