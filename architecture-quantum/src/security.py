import re
from dataclasses import dataclass
from typing import List


_INJECTION_PATTERNS: List[re.Pattern] = [
    re.compile(r"ignore\s+all\s+instructions", re.IGNORECASE),
    re.compile(r"\boutput\s*:", re.IGNORECASE),
    re.compile(r"\bsystem\s*:", re.IGNORECASE),
    re.compile(r"\bdeveloper\s*:", re.IGNORECASE),
    re.compile(r"суперпарол", re.IGNORECASE),
    re.compile(r"\broot\b", re.IGNORECASE),
    re.compile(r"swordfish", re.IGNORECASE),
]


def looks_malicious(text: str) -> bool:
    return any(p.search(text) for p in _INJECTION_PATTERNS)


def sanitize_chunk(text: str) -> str:
    s = text
    s = re.sub(r"(?i)ignore\s+all\s+instructions\.?\s*", "", s)
    s = re.sub(r"(?i)\boutput\s*:\s*", "", s)
    return s.strip()


@dataclass(frozen=True)
class DefenseConfig:
    pre_prompt: bool
    chunk_filter: bool
    sanitize: bool

    @classmethod
    def from_level(cls, level: str) -> "DefenseConfig":
        level = (level or "").strip().lower()
        if level == "none":
            return cls(pre_prompt=False, chunk_filter=False, sanitize=False)
        if level == "pre":
            return cls(pre_prompt=True, chunk_filter=False, sanitize=False)
        if level == "filter":
            return cls(pre_prompt=False, chunk_filter=True, sanitize=False)
        if level == "sanitize":
            return cls(pre_prompt=False, chunk_filter=False, sanitize=True)
        if level == "all":
            return cls(pre_prompt=True, chunk_filter=True, sanitize=True)
        raise ValueError(f"Unknown defense level: {level}")
