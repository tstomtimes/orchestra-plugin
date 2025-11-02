#!/usr/bin/env python3
"""
Vercel MCP Server
Provides Vercel API integration for deployment management.
"""

import os
import json
import sys
from typing import Any, Dict, List, Optional
import requests
from datetime import datetime


class VercelMCPServer:
    """MCP Server for Vercel API integration"""

    def __init__(self):
        self.token = os.getenv("VERCEL_TOKEN")
        self.team_id = os.getenv("VERCEL_TEAM_ID")  # Optional

        if not self.token:
            raise ValueError("VERCEL_TOKEN environment variable is required")

        self.base_url = "https://api.vercel.com"
        self.headers = {
            "Authorization": f"Bearer {self.token}",
            "Content-Type": "application/json"
        }

    def _request(self, method: str, endpoint: str, data: Optional[Dict] = None, params: Optional[Dict] = None) -> Dict[str, Any]:
        """Make a request to Vercel API"""
        url = f"{self.base_url}/{endpoint.lstrip('/')}"

        # Add team ID to params if available
        if self.team_id:
            if params is None:
                params = {}
            params["teamId"] = self.team_id

        try:
            response = requests.request(
                method=method,
                url=url,
                headers=self.headers,
                json=data,
                params=params,
                timeout=30
            )
            response.raise_for_status()
            return response.json() if response.text else {}
        except requests.exceptions.RequestException as e:
            return {"error": str(e), "status_code": getattr(e.response, "status_code", None)}

    def list_deployments(self, project_name: Optional[str] = None, limit: int = 20) -> List[Dict]:
        """List deployments"""
        params = {"limit": limit}
        if project_name:
            params["projectId"] = project_name

        result = self._request("GET", "v6/deployments", params=params)

        if "error" in result:
            return result

        deployments = result.get("deployments", [])
        return [{
            "uid": d["uid"],
            "name": d["name"],
            "url": f"https://{d['url']}",
            "created": d["created"],
            "state": d.get("state", "READY"),
            "ready_state": d.get("readyState", "READY"),
            "type": d.get("type", "LAMBDAS"),
            "creator": d.get("creator", {}).get("username", "unknown"),
            "target": d.get("target"),
            "alias_assigned": d.get("aliasAssigned"),
            "alias_error": d.get("aliasError")
        } for d in deployments]

    def get_deployment(self, deployment_id: str) -> Dict:
        """Get details of a specific deployment"""
        result = self._request("GET", f"v13/deployments/{deployment_id}")

        if "error" in result:
            return result

        return {
            "uid": result["uid"],
            "name": result["name"],
            "url": f"https://{result['url']}",
            "created": result["created"],
            "state": result.get("state", "READY"),
            "ready_state": result.get("readyState", "READY"),
            "type": result.get("type", "LAMBDAS"),
            "creator": result.get("creator", {}).get("username", "unknown"),
            "build_command": result.get("build", {}).get("env", {}).get("VERCEL_BUILD_COMMAND"),
            "framework": result.get("framework"),
            "target": result.get("target"),
            "project_id": result.get("projectId"),
            "alias_assigned": result.get("aliasAssigned")
        }

    def list_projects(self, limit: int = 20) -> List[Dict]:
        """List projects"""
        params = {"limit": limit}
        result = self._request("GET", "v9/projects", params=params)

        if "error" in result:
            return result

        projects = result.get("projects", [])
        return [{
            "id": p["id"],
            "name": p["name"],
            "account_id": p.get("accountId"),
            "created_at": p.get("createdAt"),
            "framework": p.get("framework"),
            "dev_command": p.get("devCommand"),
            "build_command": p.get("buildCommand"),
            "output_directory": p.get("outputDirectory"),
            "production_deployment": p.get("link", {}).get("type") == "production" if p.get("link") else None
        } for p in projects]

    def get_project(self, project_id: str) -> Dict:
        """Get details of a specific project"""
        result = self._request("GET", f"v9/projects/{project_id}")

        if "error" in result:
            return result

        return {
            "id": result["id"],
            "name": result["name"],
            "account_id": result.get("accountId"),
            "created_at": result.get("createdAt"),
            "framework": result.get("framework"),
            "dev_command": result.get("devCommand"),
            "build_command": result.get("buildCommand"),
            "install_command": result.get("installCommand"),
            "output_directory": result.get("outputDirectory"),
            "public_source": result.get("publicSource"),
            "root_directory": result.get("rootDirectory"),
            "serverless_function_region": result.get("serverlessFunctionRegion"),
            "env": result.get("env", [])
        }

    def get_deployment_logs(self, deployment_id: str, limit: int = 100) -> List[Dict]:
        """Get logs for a deployment"""
        params = {"limit": limit}
        result = self._request("GET", f"v2/deployments/{deployment_id}/events", params=params)

        if "error" in result:
            return result

        # Handle both list and dict responses
        if isinstance(result, list):
            return result
        return result.get("events", [])

    def cancel_deployment(self, deployment_id: str) -> Dict:
        """Cancel a deployment"""
        result = self._request("PATCH", f"v12/deployments/{deployment_id}/cancel")

        if "error" in result:
            return result

        return {
            "success": True,
            "message": f"Deployment {deployment_id} cancelled",
            "state": result.get("state")
        }

    def delete_deployment(self, deployment_id: str) -> Dict:
        """Delete a deployment"""
        result = self._request("DELETE", f"v13/deployments/{deployment_id}")

        if "error" in result:
            return result

        return {
            "success": True,
            "message": f"Deployment {deployment_id} deleted",
            "state": result.get("state", "DELETED")
        }

    def list_domains(self, limit: int = 20) -> List[Dict]:
        """List domains"""
        params = {"limit": limit}
        result = self._request("GET", "v5/domains", params=params)

        if "error" in result:
            return result

        domains = result.get("domains", [])
        return [{
            "name": d["name"],
            "created_at": d.get("createdAt"),
            "verified": d.get("verified", False),
            "service_type": d.get("serviceType"),
            "intended_nameservers": d.get("intendedNameservers", [])
        } for d in domains]

    def get_project_env_vars(self, project_id: str) -> List[Dict]:
        """Get environment variables for a project"""
        result = self._request("GET", f"v9/projects/{project_id}/env")

        if "error" in result:
            return result

        envs = result.get("envs", [])
        return [{
            "id": env["id"],
            "key": env["key"],
            "type": env.get("type", "encrypted"),
            "target": env.get("target", []),
            "created_at": env.get("createdAt"),
            "updated_at": env.get("updatedAt")
        } for env in envs]

    def get_deployment_checks(self, deployment_id: str) -> Dict:
        """Get deployment checks status"""
        result = self._request("GET", f"v1/deployments/{deployment_id}/checks")

        if "error" in result:
            return result

        checks = result.get("checks", [])
        return {
            "total": len(checks),
            "passed": sum(1 for c in checks if c.get("conclusion") == "succeeded"),
            "failed": sum(1 for c in checks if c.get("conclusion") == "failed"),
            "pending": sum(1 for c in checks if c.get("status") == "running"),
            "checks": [{
                "name": c["name"],
                "status": c.get("status"),
                "conclusion": c.get("conclusion"),
                "output": c.get("output", {})
            } for c in checks]
        }


def handle_command(server: VercelMCPServer, command: str, params: Dict[str, Any]) -> Dict[str, Any]:
    """Handle MCP commands"""

    if command == "list_deployments":
        return {
            "success": True,
            "data": server.list_deployments(
                params.get("project_name"),
                params.get("limit", 20)
            )
        }

    elif command == "get_deployment":
        return {
            "success": True,
            "data": server.get_deployment(params["deployment_id"])
        }

    elif command == "list_projects":
        return {
            "success": True,
            "data": server.list_projects(params.get("limit", 20))
        }

    elif command == "get_project":
        return {
            "success": True,
            "data": server.get_project(params["project_id"])
        }

    elif command == "get_deployment_logs":
        return {
            "success": True,
            "data": server.get_deployment_logs(
                params["deployment_id"],
                params.get("limit", 100)
            )
        }

    elif command == "cancel_deployment":
        return {
            "success": True,
            "data": server.cancel_deployment(params["deployment_id"])
        }

    elif command == "delete_deployment":
        return {
            "success": True,
            "data": server.delete_deployment(params["deployment_id"])
        }

    elif command == "list_domains":
        return {
            "success": True,
            "data": server.list_domains(params.get("limit", 20))
        }

    elif command == "get_project_env_vars":
        return {
            "success": True,
            "data": server.get_project_env_vars(params["project_id"])
        }

    elif command == "get_deployment_checks":
        return {
            "success": True,
            "data": server.get_deployment_checks(params["deployment_id"])
        }

    else:
        return {
            "success": False,
            "error": f"Unknown command: {command}"
        }


def main():
    """Main entry point for MCP server"""
    try:
        server = VercelMCPServer()

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
