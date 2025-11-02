#!/usr/bin/env python3
"""
Shopify App MCP Server
Provides Shopify Admin API integration for app development.
Supports REST and GraphQL APIs for building Shopify apps.
"""

import os
import json
import sys
from typing import Any, Dict, List, Optional
import requests
from datetime import datetime


class ShopifyAppMCPServer:
    """MCP Server for Shopify App development"""

    def __init__(self):
        self.token = os.getenv("SHOPIFY_ADMIN_TOKEN")
        self.shop_domain = os.getenv("SHOP_DOMAIN")

        if not self.token:
            raise ValueError("SHOPIFY_ADMIN_TOKEN environment variable is required")
        if not self.shop_domain:
            raise ValueError("SHOP_DOMAIN environment variable is required")

        self.base_url = f"https://{self.shop_domain}.myshopify.com/admin/api/2024-10"
        self.graphql_url = f"https://{self.shop_domain}.myshopify.com/admin/api/2024-10/graphql.json"
        self.headers = {
            "X-Shopify-Access-Token": self.token,
            "Content-Type": "application/json"
        }

    def _request(self, method: str, endpoint: str, data: Optional[Dict] = None) -> Dict[str, Any]:
        """Make a REST API request"""
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

    def _graphql(self, query: str, variables: Optional[Dict] = None) -> Dict[str, Any]:
        """Make a GraphQL API request"""
        data = {"query": query}
        if variables:
            data["variables"] = variables

        try:
            response = requests.post(
                self.graphql_url,
                headers=self.headers,
                json=data,
                timeout=30
            )
            response.raise_for_status()
            result = response.json()

            if "errors" in result:
                return {"error": result["errors"]}

            return result.get("data", {})
        except requests.exceptions.RequestException as e:
            return {"error": str(e), "status_code": getattr(e.response, "status_code", None)}

    # Product Management
    def list_products(self, limit: int = 50, status: str = "active") -> List[Dict]:
        """List products"""
        endpoint = f"products.json?limit={limit}&status={status}"
        result = self._request("GET", endpoint)

        if "error" in result:
            return result

        products = result.get("products", [])
        return [{
            "id": p["id"],
            "title": p["title"],
            "handle": p["handle"],
            "status": p["status"],
            "vendor": p.get("vendor"),
            "product_type": p.get("product_type"),
            "created_at": p["created_at"],
            "updated_at": p["updated_at"],
            "published_at": p.get("published_at"),
            "variants_count": len(p.get("variants", []))
        } for p in products]

    def get_product(self, product_id: int) -> Dict:
        """Get product details"""
        result = self._request("GET", f"products/{product_id}.json")

        if "error" in result:
            return result

        return result.get("product", {})

    def create_product(self, title: str, body_html: str = "", vendor: str = "", product_type: str = "") -> Dict:
        """Create a new product"""
        data = {
            "product": {
                "title": title,
                "body_html": body_html,
                "vendor": vendor,
                "product_type": product_type
            }
        }
        result = self._request("POST", "products.json", data)

        if "error" in result:
            return result

        return result.get("product", {})

    def update_product(self, product_id: int, updates: Dict) -> Dict:
        """Update a product"""
        data = {"product": updates}
        result = self._request("PUT", f"products/{product_id}.json", data)

        if "error" in result:
            return result

        return result.get("product", {})

    # Order Management
    def list_orders(self, limit: int = 50, status: str = "any") -> List[Dict]:
        """List orders"""
        endpoint = f"orders.json?limit={limit}&status={status}"
        result = self._request("GET", endpoint)

        if "error" in result:
            return result

        orders = result.get("orders", [])
        return [{
            "id": o["id"],
            "order_number": o["order_number"],
            "email": o.get("email"),
            "total_price": o["total_price"],
            "subtotal_price": o.get("subtotal_price"),
            "total_tax": o.get("total_tax"),
            "financial_status": o.get("financial_status"),
            "fulfillment_status": o.get("fulfillment_status"),
            "created_at": o["created_at"],
            "updated_at": o["updated_at"],
            "line_items_count": len(o.get("line_items", []))
        } for o in orders]

    def get_order(self, order_id: int) -> Dict:
        """Get order details"""
        result = self._request("GET", f"orders/{order_id}.json")

        if "error" in result:
            return result

        return result.get("order", {})

    # Customer Management
    def list_customers(self, limit: int = 50) -> List[Dict]:
        """List customers"""
        endpoint = f"customers.json?limit={limit}"
        result = self._request("GET", endpoint)

        if "error" in result:
            return result

        customers = result.get("customers", [])
        return [{
            "id": c["id"],
            "email": c.get("email"),
            "first_name": c.get("first_name"),
            "last_name": c.get("last_name"),
            "orders_count": c.get("orders_count", 0),
            "total_spent": c.get("total_spent"),
            "created_at": c["created_at"],
            "updated_at": c["updated_at"],
            "verified_email": c.get("verified_email", False),
            "state": c.get("state")
        } for c in customers]

    def get_customer(self, customer_id: int) -> Dict:
        """Get customer details"""
        result = self._request("GET", f"customers/{customer_id}.json")

        if "error" in result:
            return result

        return result.get("customer", {})

    # Inventory Management
    def get_inventory_levels(self, location_id: Optional[int] = None, limit: int = 50) -> List[Dict]:
        """Get inventory levels"""
        endpoint = f"inventory_levels.json?limit={limit}"
        if location_id:
            endpoint += f"&location_ids={location_id}"

        result = self._request("GET", endpoint)

        if "error" in result:
            return result

        levels = result.get("inventory_levels", [])
        return [{
            "inventory_item_id": l["inventory_item_id"],
            "location_id": l["location_id"],
            "available": l.get("available"),
            "updated_at": l["updated_at"]
        } for l in levels]

    def update_inventory_level(self, inventory_item_id: int, location_id: int, available: int) -> Dict:
        """Update inventory level"""
        data = {
            "location_id": location_id,
            "inventory_item_id": inventory_item_id,
            "available": available
        }
        result = self._request("POST", "inventory_levels/set.json", data)

        if "error" in result:
            return result

        return result.get("inventory_level", {})

    # Collection Management
    def list_collections(self, limit: int = 50) -> List[Dict]:
        """List smart and custom collections"""
        # Get custom collections
        custom = self._request("GET", f"custom_collections.json?limit={limit}")
        smart = self._request("GET", f"smart_collections.json?limit={limit}")

        collections = []

        if not isinstance(custom, dict) or "error" not in custom:
            for c in custom.get("custom_collections", []):
                collections.append({
                    "id": c["id"],
                    "title": c["title"],
                    "handle": c["handle"],
                    "type": "custom",
                    "published_at": c.get("published_at"),
                    "updated_at": c["updated_at"]
                })

        if not isinstance(smart, dict) or "error" not in smart:
            for c in smart.get("smart_collections", []):
                collections.append({
                    "id": c["id"],
                    "title": c["title"],
                    "handle": c["handle"],
                    "type": "smart",
                    "published_at": c.get("published_at"),
                    "updated_at": c["updated_at"]
                })

        return collections

    # Webhook Management
    def list_webhooks(self) -> List[Dict]:
        """List webhooks"""
        result = self._request("GET", "webhooks.json")

        if "error" in result:
            return result

        webhooks = result.get("webhooks", [])
        return [{
            "id": w["id"],
            "topic": w["topic"],
            "address": w["address"],
            "format": w.get("format", "json"),
            "created_at": w["created_at"],
            "updated_at": w["updated_at"]
        } for w in webhooks]

    def create_webhook(self, topic: str, address: str, format: str = "json") -> Dict:
        """Create a webhook"""
        data = {
            "webhook": {
                "topic": topic,
                "address": address,
                "format": format
            }
        }
        result = self._request("POST", "webhooks.json", data)

        if "error" in result:
            return result

        return result.get("webhook", {})

    def delete_webhook(self, webhook_id: int) -> Dict:
        """Delete a webhook"""
        result = self._request("DELETE", f"webhooks/{webhook_id}.json")

        if "error" in result:
            return result

        return {"success": True, "message": f"Webhook {webhook_id} deleted"}

    # GraphQL Queries
    def graphql_query(self, query: str, variables: Optional[Dict] = None) -> Dict:
        """Execute a custom GraphQL query"""
        return self._graphql(query, variables)

    def get_shop_metafields(self) -> List[Dict]:
        """Get shop metafields using GraphQL"""
        query = """
        {
          shop {
            metafields(first: 50) {
              edges {
                node {
                  id
                  namespace
                  key
                  value
                  type
                  createdAt
                  updatedAt
                }
              }
            }
          }
        }
        """
        result = self._graphql(query)

        if "error" in result:
            return result

        edges = result.get("shop", {}).get("metafields", {}).get("edges", [])
        return [edge["node"] for edge in edges]

    def get_app_installations(self) -> List[Dict]:
        """Get app installations using GraphQL"""
        query = """
        {
          currentAppInstallation {
            id
            app {
              title
              handle
            }
            activeSubscriptions {
              id
              name
              status
              createdAt
            }
          }
        }
        """
        result = self._graphql(query)

        if "error" in result:
            return result

        return result.get("currentAppInstallation", {})

    # Analytics
    def get_shop_analytics(self, start_date: str, end_date: str) -> Dict:
        """Get shop analytics for a date range"""
        # This would typically use the Analytics API or Reports API
        # For now, using orders as a proxy for analytics
        endpoint = f"orders.json?created_at_min={start_date}&created_at_max={end_date}&status=any&limit=250"
        result = self._request("GET", endpoint)

        if "error" in result:
            return result

        orders = result.get("orders", [])

        total_sales = sum(float(o.get("total_price", 0)) for o in orders)
        total_orders = len(orders)
        total_items = sum(len(o.get("line_items", [])) for o in orders)

        return {
            "period": {"start": start_date, "end": end_date},
            "total_orders": total_orders,
            "total_sales": total_sales,
            "total_items": total_items,
            "average_order_value": total_sales / total_orders if total_orders > 0 else 0
        }


def handle_command(server: ShopifyAppMCPServer, command: str, params: Dict[str, Any]) -> Dict[str, Any]:
    """Handle MCP commands"""

    # Product commands
    if command == "list_products":
        return {
            "success": True,
            "data": server.list_products(
                params.get("limit", 50),
                params.get("status", "active")
            )
        }

    elif command == "get_product":
        return {
            "success": True,
            "data": server.get_product(params["product_id"])
        }

    elif command == "create_product":
        return {
            "success": True,
            "data": server.create_product(
                params["title"],
                params.get("body_html", ""),
                params.get("vendor", ""),
                params.get("product_type", "")
            )
        }

    elif command == "update_product":
        return {
            "success": True,
            "data": server.update_product(
                params["product_id"],
                params["updates"]
            )
        }

    # Order commands
    elif command == "list_orders":
        return {
            "success": True,
            "data": server.list_orders(
                params.get("limit", 50),
                params.get("status", "any")
            )
        }

    elif command == "get_order":
        return {
            "success": True,
            "data": server.get_order(params["order_id"])
        }

    # Customer commands
    elif command == "list_customers":
        return {
            "success": True,
            "data": server.list_customers(params.get("limit", 50))
        }

    elif command == "get_customer":
        return {
            "success": True,
            "data": server.get_customer(params["customer_id"])
        }

    # Inventory commands
    elif command == "get_inventory_levels":
        return {
            "success": True,
            "data": server.get_inventory_levels(
                params.get("location_id"),
                params.get("limit", 50)
            )
        }

    elif command == "update_inventory_level":
        return {
            "success": True,
            "data": server.update_inventory_level(
                params["inventory_item_id"],
                params["location_id"],
                params["available"]
            )
        }

    # Collection commands
    elif command == "list_collections":
        return {
            "success": True,
            "data": server.list_collections(params.get("limit", 50))
        }

    # Webhook commands
    elif command == "list_webhooks":
        return {
            "success": True,
            "data": server.list_webhooks()
        }

    elif command == "create_webhook":
        return {
            "success": True,
            "data": server.create_webhook(
                params["topic"],
                params["address"],
                params.get("format", "json")
            )
        }

    elif command == "delete_webhook":
        return {
            "success": True,
            "data": server.delete_webhook(params["webhook_id"])
        }

    # GraphQL commands
    elif command == "graphql_query":
        return {
            "success": True,
            "data": server.graphql_query(
                params["query"],
                params.get("variables")
            )
        }

    elif command == "get_shop_metafields":
        return {
            "success": True,
            "data": server.get_shop_metafields()
        }

    elif command == "get_app_installations":
        return {
            "success": True,
            "data": server.get_app_installations()
        }

    # Analytics commands
    elif command == "get_shop_analytics":
        return {
            "success": True,
            "data": server.get_shop_analytics(
                params["start_date"],
                params["end_date"]
            )
        }

    else:
        return {
            "success": False,
            "error": f"Unknown command: {command}"
        }


def main():
    """Main entry point for MCP server"""
    try:
        server = ShopifyAppMCPServer()

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
