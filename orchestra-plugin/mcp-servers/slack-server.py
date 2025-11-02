#!/usr/bin/env python3
"""
Slack MCP Server
Provides Slack API integration for notifications and chat.
"""

import os
import json
import sys
from typing import Any, Dict, List, Optional
import requests
from datetime import datetime


class SlackMCPServer:
    """MCP Server for Slack API integration"""

    def __init__(self):
        self.token = os.getenv("SLACK_BOT_TOKEN")

        if not self.token:
            raise ValueError("SLACK_BOT_TOKEN environment variable is required")

        self.base_url = "https://slack.com/api"
        self.headers = {
            "Authorization": f"Bearer {self.token}",
            "Content-Type": "application/json"
        }

    def _request(self, method: str, endpoint: str, data: Optional[Dict] = None) -> Dict[str, Any]:
        """Make a request to Slack API"""
        url = f"{self.base_url}/{endpoint}"

        try:
            response = requests.request(
                method=method,
                url=url,
                headers=self.headers,
                json=data,
                timeout=30
            )
            response.raise_for_status()
            result = response.json()

            if not result.get("ok"):
                return {"error": result.get("error", "Unknown error")}

            return result
        except requests.exceptions.RequestException as e:
            return {"error": str(e), "status_code": getattr(e.response, "status_code", None)}

    def send_message(self, channel: str, text: str, blocks: Optional[List[Dict]] = None, thread_ts: Optional[str] = None) -> Dict:
        """Send a message to a channel"""
        data = {
            "channel": channel,
            "text": text
        }

        if blocks:
            data["blocks"] = blocks

        if thread_ts:
            data["thread_ts"] = thread_ts

        result = self._request("POST", "chat.postMessage", data)

        if "error" in result:
            return result

        return {
            "ok": result["ok"],
            "channel": result.get("channel"),
            "ts": result.get("ts"),
            "message": result.get("message", {})
        }

    def update_message(self, channel: str, ts: str, text: str, blocks: Optional[List[Dict]] = None) -> Dict:
        """Update an existing message"""
        data = {
            "channel": channel,
            "ts": ts,
            "text": text
        }

        if blocks:
            data["blocks"] = blocks

        result = self._request("POST", "chat.update", data)

        if "error" in result:
            return result

        return {
            "ok": result["ok"],
            "channel": result.get("channel"),
            "ts": result.get("ts"),
            "text": result.get("text")
        }

    def delete_message(self, channel: str, ts: str) -> Dict:
        """Delete a message"""
        data = {
            "channel": channel,
            "ts": ts
        }

        result = self._request("POST", "chat.delete", data)

        if "error" in result:
            return result

        return {
            "ok": result["ok"],
            "channel": result.get("channel"),
            "ts": result.get("ts")
        }

    def list_channels(self, limit: int = 100, exclude_archived: bool = True) -> List[Dict]:
        """List channels"""
        data = {
            "limit": limit,
            "exclude_archived": exclude_archived
        }

        result = self._request("POST", "conversations.list", data)

        if "error" in result:
            return result

        channels = result.get("channels", [])
        return [{
            "id": ch["id"],
            "name": ch["name"],
            "is_channel": ch.get("is_channel", False),
            "is_private": ch.get("is_private", False),
            "is_archived": ch.get("is_archived", False),
            "is_member": ch.get("is_member", False),
            "num_members": ch.get("num_members", 0),
            "topic": ch.get("topic", {}).get("value", ""),
            "purpose": ch.get("purpose", {}).get("value", "")
        } for ch in channels]

    def get_channel_info(self, channel: str) -> Dict:
        """Get channel information"""
        data = {"channel": channel}
        result = self._request("POST", "conversations.info", data)

        if "error" in result:
            return result

        ch = result.get("channel", {})
        return {
            "id": ch["id"],
            "name": ch["name"],
            "is_channel": ch.get("is_channel", False),
            "is_private": ch.get("is_private", False),
            "is_archived": ch.get("is_archived", False),
            "is_member": ch.get("is_member", False),
            "num_members": ch.get("num_members", 0),
            "topic": ch.get("topic", {}).get("value", ""),
            "purpose": ch.get("purpose", {}).get("value", ""),
            "created": ch.get("created")
        }

    def list_users(self, limit: int = 100) -> List[Dict]:
        """List users"""
        data = {"limit": limit}
        result = self._request("POST", "users.list", data)

        if "error" in result:
            return result

        members = result.get("members", [])
        return [{
            "id": user["id"],
            "name": user.get("name"),
            "real_name": user.get("real_name"),
            "display_name": user.get("profile", {}).get("display_name", ""),
            "email": user.get("profile", {}).get("email", ""),
            "is_bot": user.get("is_bot", False),
            "is_admin": user.get("is_admin", False),
            "is_owner": user.get("is_owner", False),
            "deleted": user.get("deleted", False)
        } for user in members]

    def get_user_info(self, user_id: str) -> Dict:
        """Get user information"""
        data = {"user": user_id}
        result = self._request("POST", "users.info", data)

        if "error" in result:
            return result

        user = result.get("user", {})
        return {
            "id": user["id"],
            "name": user.get("name"),
            "real_name": user.get("real_name"),
            "display_name": user.get("profile", {}).get("display_name", ""),
            "email": user.get("profile", {}).get("email", ""),
            "is_bot": user.get("is_bot", False),
            "is_admin": user.get("is_admin", False),
            "is_owner": user.get("is_owner", False),
            "timezone": user.get("tz")
        }

    def send_deployment_notification(self, channel: str, status: str, environment: str, commit: str, deployer: str, url: str) -> Dict:
        """Send a formatted deployment notification"""
        emoji = ":white_check_mark:" if status.lower() == "success" else ":x:"
        color = "good" if status.lower() == "success" else "danger"

        blocks = [
            {
                "type": "header",
                "text": {
                    "type": "plain_text",
                    "text": f"{emoji} Deployment {status}"
                }
            },
            {
                "type": "section",
                "fields": [
                    {
                        "type": "mrkdwn",
                        "text": f"*Environment:*\n{environment}"
                    },
                    {
                        "type": "mrkdwn",
                        "text": f"*Deployed by:*\n{deployer}"
                    },
                    {
                        "type": "mrkdwn",
                        "text": f"*Commit:*\n`{commit}`"
                    },
                    {
                        "type": "mrkdwn",
                        "text": f"*URL:*\n<{url}|View deployment>"
                    }
                ]
            }
        ]

        return self.send_message(channel, f"Deployment {status}", blocks)

    def send_alert(self, channel: str, title: str, message: str, severity: str = "warning") -> Dict:
        """Send a formatted alert"""
        emoji_map = {
            "info": ":information_source:",
            "warning": ":warning:",
            "error": ":x:",
            "success": ":white_check_mark:"
        }

        emoji = emoji_map.get(severity.lower(), ":bell:")

        blocks = [
            {
                "type": "header",
                "text": {
                    "type": "plain_text",
                    "text": f"{emoji} {title}"
                }
            },
            {
                "type": "section",
                "text": {
                    "type": "mrkdwn",
                    "text": message
                }
            }
        ]

        return self.send_message(channel, title, blocks)


def handle_command(server: SlackMCPServer, command: str, params: Dict[str, Any]) -> Dict[str, Any]:
    """Handle MCP commands"""

    if command == "send_message":
        return {
            "success": True,
            "data": server.send_message(
                params["channel"],
                params["text"],
                params.get("blocks"),
                params.get("thread_ts")
            )
        }

    elif command == "update_message":
        return {
            "success": True,
            "data": server.update_message(
                params["channel"],
                params["ts"],
                params["text"],
                params.get("blocks")
            )
        }

    elif command == "delete_message":
        return {
            "success": True,
            "data": server.delete_message(
                params["channel"],
                params["ts"]
            )
        }

    elif command == "list_channels":
        return {
            "success": True,
            "data": server.list_channels(
                params.get("limit", 100),
                params.get("exclude_archived", True)
            )
        }

    elif command == "get_channel_info":
        return {
            "success": True,
            "data": server.get_channel_info(params["channel"])
        }

    elif command == "list_users":
        return {
            "success": True,
            "data": server.list_users(params.get("limit", 100))
        }

    elif command == "get_user_info":
        return {
            "success": True,
            "data": server.get_user_info(params["user_id"])
        }

    elif command == "send_deployment_notification":
        return {
            "success": True,
            "data": server.send_deployment_notification(
                params["channel"],
                params["status"],
                params["environment"],
                params["commit"],
                params["deployer"],
                params["url"]
            )
        }

    elif command == "send_alert":
        return {
            "success": True,
            "data": server.send_alert(
                params["channel"],
                params["title"],
                params["message"],
                params.get("severity", "warning")
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
        server = SlackMCPServer()

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
