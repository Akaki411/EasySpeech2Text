from api.base import OpenAICompatibleController


class DeepSeekController(OpenAICompatibleController):
    name = "DeepSeek"
    base_url = "https://api.deepseek.com/v1"
