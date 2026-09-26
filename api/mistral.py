from api.base import OpenAICompatibleController


class MistralController(OpenAICompatibleController):
    name = "Mistral"
    base_url = "https://api.mistral.ai/v1"
