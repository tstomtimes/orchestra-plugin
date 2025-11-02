#!/usr/bin/env python3
"""
Shopify MCP Server
Provides Shopify Admin API integration for theme development and management.
"""

import os
import json
import sys
from typing import Any, Dict, List, Optional
import requests
from datetime import datetime


class ShopifyMCPServer:
    """MCP Server for Shopify Admin API integration"""

    def __init__(self):
        self.token = os.getenv("SHOPIFY_ADMIN_TOKEN")
        self.shop_domain = os.getenv("SHOP_DOMAIN")

        if not self.token:
            raise ValueError("SHOPIFY_ADMIN_TOKEN environment variable is required")
        if not self.shop_domain:
            raise ValueError("SHOP_DOMAIN environment variable is required")

        self.base_url = f"https://{self.shop_domain}.myshopify.com/admin/api/2024-10"
        self.headers = {
            "X-Shopify-Access-Token": self.token,
            "Content-Type": "application/json"
        }

    def _request(self, method: str, endpoint: str, data: Optional[Dict] = None) -> Dict[str, Any]:
        """Make a request to Shopify Admin API"""
        url = f"{self.base_url}/{endpoint.lstrip('/')}"

        try:
            response = requests.request(
                method=method,
                url=url,
                headers=self.headers,
                json=data,
                timeout=30
            )
            response.raise_for_status()
            return response.json() if response.text else {}
        except requests.exceptions.RequestException as e:
            return {"error": str(e), "status_code": getattr(e.response, "status_code", None)}

    def list_themes(self) -> List[Dict]:
        """List all themes in the shop"""
        result = self._request("GET", "themes.json")

        if "error" in result:
            return result

        themes = result.get("themes", [])
        return [{
            "id": theme["id"],
            "name": theme["name"],
            "role": theme["role"],
            "created_at": theme["created_at"],
            "updated_at": theme["updated_at"],
            "theme_store_id": theme.get("theme_store_id"),
            "previewable": theme.get("previewable", True),
            "processing": theme.get("processing", False)
        } for theme in themes]

    def get_theme(self, theme_id: int) -> Dict:
        """Get details of a specific theme"""
        result = self._request("GET", f"themes/{theme_id}.json")

        if "error" in result:
            return result

        theme = result.get("theme", {})
        return {
            "id": theme["id"],
            "name": theme["name"],
            "role": theme["role"],
            "created_at": theme["created_at"],
            "updated_at": theme["updated_at"],
            "theme_store_id": theme.get("theme_store_id"),
            "previewable": theme.get("previewable", True),
            "processing": theme.get("processing", False),
            "admin_graphql_api_id": theme.get("admin_graphql_api_id")
        }

    def list_theme_assets(self, theme_id: int, asset_type: Optional[str] = None) -> List[Dict]:
        """List assets for a theme"""
        endpoint = f"themes/{theme_id}/assets.json"

        result = self._request("GET", endpoint)

        if "error" in result:
            return result

        assets = result.get("assets", [])

        # Filter by asset type if specified
        if asset_type:
            assets = [a for a in assets if a["key"].startswith(asset_type)]

        return [{
            "key": asset["key"],
            "public_url": asset.get("public_url"),
            "created_at": asset["created_at"],
            "updated_at": asset["updated_at"],
            "content_type": asset["content_type"],
            "size": asset.get("size", 0),
            "theme_id": asset["theme_id"]
        } for asset in assets]

    def get_theme_asset(self, theme_id: int, asset_key: str) -> Dict:
        """Get a specific theme asset"""
        endpoint = f"themes/{theme_id}/assets.json?asset[key]={asset_key}"

        result = self._request("GET", endpoint)

        if "error" in result:
            return result

        asset = result.get("asset", {})
        return {
            "key": asset["key"],
            "value": asset.get("value"),
            "attachment": asset.get("attachment"),
            "public_url": asset.get("public_url"),
            "created_at": asset["created_at"],
            "updated_at": asset["updated_at"],
            "content_type": asset["content_type"],
            "size": asset.get("size", 0),
            "theme_id": asset["theme_id"]
        }

    def update_theme_asset(self, theme_id: int, asset_key: str, value: Optional[str] = None, attachment: Optional[str] = None) -> Dict:
        """Update or create a theme asset"""
        endpoint = f"themes/{theme_id}/assets.json"

        asset_data = {"key": asset_key}
        if value is not None:
            asset_data["value"] = value
        if attachment is not None:
            asset_data["attachment"] = attachment

        data = {"asset": asset_data}
        result = self._request("PUT", endpoint, data)

        if "error" in result:
            return result

        asset = result.get("asset", {})
        return {
            "key": asset["key"],
            "public_url": asset.get("public_url"),
            "updated_at": asset["updated_at"]
        }

    def delete_theme_asset(self, theme_id: int, asset_key: str) -> Dict:
        """Delete a theme asset"""
        endpoint = f"themes/{theme_id}/assets.json?asset[key]={asset_key}"
        result = self._request("DELETE", endpoint)

        if "error" in result:
            return result

        return {"success": True, "message": f"Asset {asset_key} deleted"}

    def publish_theme(self, theme_id: int) -> Dict:
        """Publish a theme (set as main theme)"""
        endpoint = f"themes/{theme_id}.json"
        data = {"theme": {"id": theme_id, "role": "main"}}
        result = self._request("PUT", endpoint, data)

        if "error" in result:
            return result

        return {
            "success": True,
            "message": f"Theme {theme_id} is now published",
            "theme": result.get("theme", {})
        }

    def duplicate_theme(self, theme_id: int, new_name: Optional[str] = None) -> Dict:
        """Duplicate an existing theme"""
        # Get source theme
        source_theme = self.get_theme(theme_id)
        if "error" in source_theme:
            return source_theme

        # Create new theme
        endpoint = "themes.json"
        theme_name = new_name or f"{source_theme['name']} (Copy)"
        data = {
            "theme": {
                "name": theme_name,
                "src": f"https://{self.shop_domain}.myshopify.com/admin/themes/{theme_id}/download",
                "role": "unpublished"
            }
        }

        result = self._request("POST", endpoint, data)

        if "error" in result:
            return result

        return result.get("theme", {})

    def validate_theme(self, theme_id: int) -> Dict:
        """Validate theme structure and assets"""
        # Get theme assets
        assets = self.list_theme_assets(theme_id)

        if isinstance(assets, dict) and "error" in assets:
            return assets

        # Check for required files
        required_files = [
            "layout/theme.liquid",
            "templates/index.json",
            "templates/product.json",
            "templates/collection.json",
            "config/settings_schema.json"
        ]

        asset_keys = [asset["key"] for asset in assets]
        missing_files = [f for f in required_files if f not in asset_keys]

        # Categorize assets
        templates = [a for a in assets if a["key"].startswith("templates/")]
        sections = [a for a in assets if a["key"].startswith("sections/")]
        snippets = [a for a in assets if a["key"].startswith("snippets/")]
        assets_files = [a for a in assets if a["key"].startswith("assets/")]
        config = [a for a in assets if a["key"].startswith("config/")]
        layout = [a for a in assets if a["key"].startswith("layout/")]

        return {
            "valid": len(missing_files) == 0,
            "missing_files": missing_files,
            "summary": {
                "total_assets": len(assets),
                "templates": len(templates),
                "sections": len(sections),
                "snippets": len(snippets),
                "assets": len(assets_files),
                "config": len(config),
                "layout": len(layout)
            }
        }

    def get_shop_info(self) -> Dict:
        """Get shop information"""
        result = self._request("GET", "shop.json")

        if "error" in result:
            return result

        shop = result.get("shop", {})
        return {
            "name": shop.get("name"),
            "email": shop.get("email"),
            "domain": shop.get("domain"),
            "myshopify_domain": shop.get("myshopify_domain"),
            "plan_name": shop.get("plan_name"),
            "primary_locale": shop.get("primary_locale"),
            "currency": shop.get("currency"),
            "timezone": shop.get("iana_timezone"),
            "shop_owner": shop.get("shop_owner")
        }


def handle_command(server: ShopifyMCPServer, command: str, params: Dict[str, Any]) -> Dict[str, Any]:
    """Handle MCP commands"""

    if command == "list_themes":
        return {
            "success": True,
            "data": server.list_themes()
        }

    elif command == "get_theme":
        return {
            "success": True,
            "data": server.get_theme(params["theme_id"])
        }

    elif command == "list_theme_assets":
        return {
            "success": True,
            "data": server.list_theme_assets(
                params["theme_id"],
                params.get("asset_type")
            )
        }

    elif command == "get_theme_asset":
        return {
            "success": True,
            "data": server.get_theme_asset(
                params["theme_id"],
                params["asset_key"]
            )
        }

    elif command == "update_theme_asset":
        return {
            "success": True,
            "data": server.update_theme_asset(
                params["theme_id"],
                params["asset_key"],
                params.get("value"),
                params.get("attachment")
            )
        }

    elif command == "delete_theme_asset":
        return {
            "success": True,
            "data": server.delete_theme_asset(
                params["theme_id"],
                params["asset_key"]
            )
        }

    elif command == "publish_theme":
        return {
            "success": True,
            "data": server.publish_theme(params["theme_id"])
        }

    elif command == "duplicate_theme":
        return {
            "success": True,
            "data": server.duplicate_theme(
                params["theme_id"],
                params.get("new_name")
            )
        }

    elif command == "validate_theme":
        return {
            "success": True,
            "data": server.validate_theme(params["theme_id"])
        }

    elif command == "get_shop_info":
        return {
            "success": True,
            "data": server.get_shop_info()
        }

    else:
        return {
            "success": False,
            "error": f"Unknown command: {command}"
        }


def main():
    """Main entry point for MCP server"""
    try:
        server = ShopifyMCPServer()

        # Read command from stdin
        if len(sys.argv) > 1:
            input_data = json.loads(sys.argv[1])
        else:
            input_data = json.loads(sys.stdin.read())

        command = input_data.get("command")
        params = input_data.get("params", {})

        result = handle_command(server, command, params)
        print(json.dumps(result, indent=2))

    except Exception as e:
        error_result = {
            "success": False,
            "error": str(e)
        }
        print(json.dumps(error_result, indent=2))
        sys.exit(1)


if __name__ == "__main__":
    main()
