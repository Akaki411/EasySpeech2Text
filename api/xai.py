from api.base import OpenAICompatibleController


class XAIController(OpenAICompatibleController):
    name = "Grok"
    base_url = "https://api.x.ai/v1"
