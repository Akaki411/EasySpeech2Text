from api.base import BaseController


class GoogleController(BaseController):
    name = "Gemini"
    base_url = "https://generativelanguage.googleapis.com/v1beta"

    def _headers(self, api_key: str) -> dict:
        return {"Content-Type": "application/json"}

    def list_models(self, api_key: str) -> list:
        result = self._request("GET", f"{self.base_url}/models?key={api_key}", api_key)
        models = []
        for item in result.get("models", []):
            if "generateContent" in item.get("supportedGenerationMethods", []):
                models.append(item["name"].split("/")[-1])
        return sorted(models)

    def chat(self, api_key: str, model: str, prompt: str) -> str:
        url = f"{self.base_url}/models/{model}:generateContent?key={api_key}"
        payload = {"contents": [{"parts": [{"text": prompt}]}]}
        result = self._request("POST", url, api_key, payload)
        parts = result.get("candidates", [])[0]["content"]["parts"]
        return "".join(part.get("text", "") for part in parts).strip()
