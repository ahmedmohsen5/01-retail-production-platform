#!/usr/bin/env python3

import json
import sys

services = {
    "ui": {
        "dockerfile": "docker/ui/Dockerfile",
        "context": "application",
        "prefixes": [
            "application/ui/",
        ],
        "exact": [
            "docker/ui/Dockerfile",
            "application/cart/openapi.yml",
            "application/orders/openapi.yml",
            "application/catalog/openapi.yml",
            "application/checkout/openapi.yml",
            "application/recommendations/openapi.yml",
        ],
    },
    "catalog": {
        "dockerfile": "docker/catalog/Dockerfile",
        "context": "application",
        "prefixes": [
            "application/catalog/",
        ],
        "exact": [
            "docker/catalog/Dockerfile",
        ],
    },
    "cart": {
        "dockerfile": "docker/cart/Dockerfile",
        "context": "application",
        "prefixes": [
            "application/cart/src/",
        ],
        "exact": [
            "docker/cart/Dockerfile",
            "application/cart/pom.xml",
            "application/cart/ATTRIBUTION.md",
        ],
    },
    "orders": {
        "dockerfile": "docker/orders/Dockerfile",
        "context": "application",
        "prefixes": [
            "application/orders/src/",
        ],
        "exact": [
            "docker/orders/Dockerfile",
            "application/orders/pom.xml",
            "application/orders/ATTRIBUTION.md",
        ],
    },
    "checkout": {
        "dockerfile": "docker/checkout/Dockerfile",
        "context": "application",
        "prefixes": [
            "application/checkout/",
        ],
        "exact": [
            "docker/checkout/Dockerfile",
        ],
    },
}

force_all_exact = {
    "application/LICENSE",
    "application/.dockerignore",
    ".github/workflows/pr-validation.yml",
    ".github/scripts/select_container_builds.py",
    ".github/scripts/test_select_container_builds.py",
}

known_dockerfiles = {
    config["dockerfile"]
    for config in services.values()
}

def normalize(path: str) -> str:
    return path.strip().replace("\\", "/")

def matches_service(path: str , config: dict) -> bool:
    if path in config["exact"]:
        return True
    return any(path.startswith(prefix) for prefix in config["prefixes"] ) 

def select_services(paths: list[str]) -> list[str]:
    changed = [normalize(path) for path in paths if normalize(path)]

    force_all= any(path in force_all_exact for path in changed)

    if any(
        path.startswith("docker/") and path not in known_dockerfiles
        for path in changed
    ): force_all = True

    if force_all:
        return list(services)

    return [
        service for service , config in services.items()
        if any(matches_service(path, config) for path in changed)
    ]

def build_matrix(paths: list[str]) -> dict:
    return {
        "include": [
            {
                "service": service,
                "dockerfile": services[service]["dockerfile"],
                "context": services[service]["context"],
            }
            for service in select_services(paths)
        ]

    }

if __name__ == "__main__":
    matrix = build_matrix(sys.stdin)
    print(json.dumps(matrix , separators=("," , ":")))


