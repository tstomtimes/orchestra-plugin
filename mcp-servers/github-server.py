#!/usr/bin/env python3
"""
GitHub MCP Server
Provides GitHub API integration for PR management, repo access, and issue tracking.
"""

import os
import json
import sys
from typing import Any, Dict, List, Optional
import requests
from datetime import datetime


class GitHubMCPServer:
    """MCP Server for GitHub API integration"""

    def __init__(self):
        self.token = os.getenv("GITHUB_TOKEN")
        if not self.token:
            raise ValueError("GITHUB_TOKEN environment variable is required")

        self.base_url = "https://api.github.com"
        self.headers = {
            "Authorization": f"Bearer {self.token}",
            "Accept": "application/vnd.github+json",
            "X-GitHub-Api-Version": "2022-11-28"
        }

    def _request(self, method: str, endpoint: str, data: Optional[Dict] = None) -> Dict[str, Any]:
        """Make a request to GitHub API"""
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

    def list_pull_requests(self, owner: str, repo: str, state: str = "open") -> List[Dict]:
        """List pull requests for a repository"""
        endpoint = f"repos/{owner}/{repo}/pulls?state={state}"
        result = self._request("GET", endpoint)

        if isinstance(result, dict) and "error" in result:
            return result

        return [{
            "number": pr["number"],
            "title": pr["title"],
            "state": pr["state"],
            "author": pr["user"]["login"],
            "created_at": pr["created_at"],
            "updated_at": pr["updated_at"],
            "url": pr["html_url"],
            "draft": pr.get("draft", False),
            "mergeable": pr.get("mergeable"),
            "mergeable_state": pr.get("mergeable_state")
        } for pr in result]

    def get_pull_request(self, owner: str, repo: str, pr_number: int) -> Dict:
        """Get details of a specific pull request"""
        endpoint = f"repos/{owner}/{repo}/pulls/{pr_number}"
        result = self._request("GET", endpoint)

        if "error" in result:
            return result

        return {
            "number": result["number"],
            "title": result["title"],
            "body": result["body"],
            "state": result["state"],
            "author": result["user"]["login"],
            "created_at": result["created_at"],
            "updated_at": result["updated_at"],
            "merged": result.get("merged", False),
            "mergeable": result.get("mergeable"),
            "mergeable_state": result.get("mergeable_state"),
            "url": result["html_url"],
            "head": result["head"]["ref"],
            "base": result["base"]["ref"],
            "commits": result.get("commits", 0),
            "additions": result.get("additions", 0),
            "deletions": result.get("deletions", 0),
            "changed_files": result.get("changed_files", 0)
        }

    def create_pull_request(self, owner: str, repo: str, title: str, head: str, base: str, body: str = "") -> Dict:
        """Create a new pull request"""
        endpoint = f"repos/{owner}/{repo}/pulls"
        data = {
            "title": title,
            "head": head,
            "base": base,
            "body": body
        }
        result = self._request("POST", endpoint, data)

        if "error" in result:
            return result

        return {
            "number": result["number"],
            "url": result["html_url"],
            "state": result["state"]
        }

    def list_pr_checks(self, owner: str, repo: str, pr_number: int) -> Dict:
        """Get CI/CD check status for a pull request"""
        # First get the PR to find the head SHA
        pr = self.get_pull_request(owner, repo, pr_number)
        if "error" in pr:
            return pr

        # Get the latest commit from PR
        endpoint = f"repos/{owner}/{repo}/pulls/{pr_number}/commits"
        commits = self._request("GET", endpoint)

        if isinstance(commits, dict) and "error" in commits:
            return commits

        if not commits:
            return {"error": "No commits found"}

        latest_commit_sha = commits[-1]["sha"]

        # Get check runs for the commit
        endpoint = f"repos/{owner}/{repo}/commits/{latest_commit_sha}/check-runs"
        result = self._request("GET", endpoint)

        if "error" in result:
            return result

        checks = []
        for check in result.get("check_runs", []):
            checks.append({
                "name": check["name"],
                "status": check["status"],
                "conclusion": check.get("conclusion"),
                "started_at": check.get("started_at"),
                "completed_at": check.get("completed_at"),
                "url": check["html_url"]
            })

        return {
            "commit_sha": latest_commit_sha,
            "total_count": result.get("total_count", 0),
            "checks": checks
        }

    def merge_pull_request(self, owner: str, repo: str, pr_number: int, merge_method: str = "merge") -> Dict:
        """Merge a pull request"""
        endpoint = f"repos/{owner}/{repo}/pulls/{pr_number}/merge"
        data = {"merge_method": merge_method}
        result = self._request("PUT", endpoint, data)

        return result

    def list_issues(self, owner: str, repo: str, state: str = "open") -> List[Dict]:
        """List issues for a repository"""
        endpoint = f"repos/{owner}/{repo}/issues?state={state}"
        result = self._request("GET", endpoint)

        if isinstance(result, dict) and "error" in result:
            return result

        # Filter out pull requests (GitHub API returns PRs as issues)
        issues = [issue for issue in result if "pull_request" not in issue]

        return [{
            "number": issue["number"],
            "title": issue["title"],
            "state": issue["state"],
            "author": issue["user"]["login"],
            "created_at": issue["created_at"],
            "updated_at": issue["updated_at"],
            "url": issue["html_url"],
            "labels": [label["name"] for label in issue.get("labels", [])]
        } for issue in issues]

    def get_repo_status(self, owner: str, repo: str) -> Dict:
        """Get repository status and information"""
        endpoint = f"repos/{owner}/{repo}"
        result = self._request("GET", endpoint)

        if "error" in result:
            return result

        return {
            "name": result["name"],
            "full_name": result["full_name"],
            "description": result.get("description"),
            "private": result["private"],
            "default_branch": result["default_branch"],
            "url": result["html_url"],
            "stars": result["stargazers_count"],
            "forks": result["forks_count"],
            "open_issues": result["open_issues_count"],
            "language": result.get("language"),
            "created_at": result["created_at"],
            "updated_at": result["updated_at"]
        }


def handle_command(server: GitHubMCPServer, command: str, params: Dict[str, Any]) -> Dict[str, Any]:
    """Handle MCP commands"""

    if command == "list_prs":
        return {
            "success": True,
            "data": server.list_pull_requests(
                params["owner"],
                params["repo"],
                params.get("state", "open")
            )
        }

    elif command == "get_pr":
        return {
            "success": True,
            "data": server.get_pull_request(
                params["owner"],
                params["repo"],
                params["pr_number"]
            )
        }

    elif command == "create_pr":
        return {
            "success": True,
            "data": server.create_pull_request(
                params["owner"],
                params["repo"],
                params["title"],
                params["head"],
                params["base"],
                params.get("body", "")
            )
        }

    elif command == "list_pr_checks":
        return {
            "success": True,
            "data": server.list_pr_checks(
                params["owner"],
                params["repo"],
                params["pr_number"]
            )
        }

    elif command == "merge_pr":
        return {
            "success": True,
            "data": server.merge_pull_request(
                params["owner"],
                params["repo"],
                params["pr_number"],
                params.get("merge_method", "merge")
            )
        }

    elif command == "list_issues":
        return {
            "success": True,
            "data": server.list_issues(
                params["owner"],
                params["repo"],
                params.get("state", "open")
            )
        }

    elif command == "get_repo_status":
        return {
            "success": True,
            "data": server.get_repo_status(
                params["owner"],
                params["repo"]
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
        server = GitHubMCPServer()

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
