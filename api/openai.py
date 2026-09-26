from api.base import OpenAICompatibleController


class OpenAIController(OpenAICompatibleController):
    name = "ChatGPT"
    base_url = "https://api.openai.com/v1"
    model_prefixes = ("gpt", "o1", "o3", "o4", "chatgpt")
