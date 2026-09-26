import json
import urllib.request
import urllib.error


class APIError(Exception):
    pass


class BaseController:
    name = ""
    base_url = ""
    timeout = 30

    def _headers(self, api_key: str) -> dict:
        return {
            "Authorization": f"Bearer {api_key}",
            "Content-Type": "application/json",
        }

    def _request(self, method: str, url: str, api_key: str, payload=None):
        data = json.dumps(payload).encode("utf-8") if payload is not None else None
        request = urllib.request.Request(url, data=data, method=method, headers=self._headers(api_key))
        try:
            with urllib.request.urlopen(request, timeout=self.timeout) as response:
                return json.loads(response.read().decode("utf-8"))
        except urllib.error.HTTPError as error:
            detail = error.read().decode("utf-8", errors="ignore")
            raise APIError(f"{error.code} {detail}".strip())
        except urllib.error.URLError as error:
            raise APIError(str(error.reason))

    def list_models(self, api_key: str) -> list:
        raise NotImplementedError

    def chat(self, api_key: str, model: str, prompt: str) -> str:
        raise NotImplementedError


class OpenAICompatibleController(BaseController):
    model_prefixes = None

    def list_models(self, api_key: str) -> list:
        result = self._request("GET", f"{self.base_url}/models", api_key)
        models = [item["id"] for item in result.get("data", [])]
        if self.model_prefixes:
            models = [model for model in models if model.startswith(self.model_prefixes)]
        return sorted(models)

    def chat(self, api_key: str, model: str, prompt: str) -> str:
        payload = {
            "model": model,
            "messages": [{"role": "user", "content": prompt}],
            "temperature": 0,
        }
        result = self._request("POST", f"{self.base_url}/chat/completions", api_key, payload)
        return result["choices"][0]["message"]["content"].strip()
