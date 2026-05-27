import torch
from transformers import AutoTokenizer, AutoModelForCausalLM


class LLMNormalizer:
    MODEL_ID = "Qwen/Qwen2.5-1.5B-Instruct"

    NORMALIZE_PROMPT = """Ты — редактор текста. Тебе дан сырой текст, полученный из системы распознавания речи (Whisper ASR).
    Задача: нормализуй текст — исправь артефакты распознавания, расставь знаки препинания, исправь очевидные ошибки, убери повторы слов и паразитические звуки. Сохрани смысл и стиль оригинала. Не добавляй ничего от себя.
    Верни только нормализованный текст, без пояснений и комментариев.
    Текст для нормализации:
    {text}"""

    def __init__(self):
        self._model = None
        self._tokenizer = None

    @property
    def is_loaded(self) -> bool:
        return self._model is not None

    def load(self):
        self._tokenizer = AutoTokenizer.from_pretrained(
            self.MODEL_ID,
            trust_remote_code=True,
        )

        dtype = torch.float16 if torch.cuda.is_available() else torch.float32
        self._model = AutoModelForCausalLM.from_pretrained(
            self.MODEL_ID,
            torch_dtype=dtype,
            device_map="auto",
            trust_remote_code=True,
            low_cpu_mem_usage=True,
        )
        self._model.eval()

    def unload(self):
        self._model = None
        self._tokenizer = None
        if torch.cuda.is_available():
            torch.cuda.empty_cache()

    def normalize(self, text: str, max_new_tokens: int = 2048) -> str:
        if not self.is_loaded:
            raise RuntimeError("LLM не загружена. Вызовите load() перед использованием.")

        prompt = self.NORMALIZE_PROMPT.format(text=text)
        messages = [{"role": "user", "content": prompt}]

        input_ids = self._tokenizer.apply_chat_template(
            messages,
            add_generation_prompt=True,
            return_tensors="pt",
        ).to(self._model.device)

        with torch.no_grad():
            output_ids = self._model.generate(
                input_ids,
                max_new_tokens=max_new_tokens,
                do_sample=False,
                pad_token_id=self._tokenizer.eos_token_id,
            )

        new_tokens = output_ids[0][input_ids.shape[-1]:]
        raw_output = self._tokenizer.decode(new_tokens, skip_special_tokens=True)

        if "<think>" in raw_output and "</think>" in raw_output:
            start = raw_output.rfind("</think>")
            raw_output = raw_output[start + len("</think>"):].strip()

        return raw_output.strip()