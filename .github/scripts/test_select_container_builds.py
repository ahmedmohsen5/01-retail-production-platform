import unittest

from select_container_builds import build_matrix

def selected(paths):
    matrix = build_matrix(paths)
    return [entry["service"] for entry in matrix["include"]]

class ContainerBuildSelectionTests(unittest.TestCase):
    def test_catalog_source_builds_catalog_only(self):
        self.assertEqual(
            selected(["application/catalog/main.go"]),
            ["catalog"],
        )

    def test_orders_openapi_builds_ui_only(self):
        self.assertEqual(
            selected(["application/orders/openapi.yml"]),
            ["ui"],
        )

    def test_cart_dockerfile_builds_cart_only(self):
        self.assertEqual(
            selected(["docker/cart/Dockerfile"]),
            ["cart"],
        )

    def test_shared_license_builds_all_services(self):
        self.assertEqual(
            selected(["application/LICENSE"]),
            ["ui", "catalog", "cart", "orders", "checkout"],
        )

    def test_pipeline_change_builds_all_services(self):
        self.assertEqual(
            selected([".github/workflows/pr-validation.yml"]),
            ["ui", "catalog", "cart", "orders", "checkout"],
        )

    def test_documentation_change_builds_nothing(self):
        self.assertEqual(
            selected(["docs/architecture.md"]),
            [],
        )


if __name__ == "__main__":
    unittest.main(verbosity=2)