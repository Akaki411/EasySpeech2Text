from api.base import OpenAICompatibleController


class MoonshotController(OpenAICompatibleController):
    name = "Kimi"
    base_url = "https://api.moonshot.cn/v1"
