from api.base import BaseController


class AnthropicController(BaseController):
    name = "Claude"
    base_url = "https://api.anthropic.com/v1"
    version = "2023-06-01"

    def _headers(self, api_key: str) -> dict:
        return {
            "x-api-key": api_key,
            "anthropic-version": self.version,
            "Content-Type": "application/json",
        }

    def list_models(self, api_key: str) -> list:
        result = self._request("GET", f"{self.base_url}/models", api_key)
        return sorted(item["id"] for item in result.get("data", []))

    def chat(self, api_key: str, model: str, prompt: str) -> str:
        payload = {
            "model": model,
            "max_tokens": 4096,
            "messages": [{"role": "user", "content": prompt}],
        }
        result = self._request("POST", f"{self.base_url}/messages", api_key, payload)
        return "".join(block.get("text", "") for block in result.get("content", [])).strip()
