"""Pure business-logic functions."""


def add(a: float, b: float) -> float:
    return a + b


def divide(a: float, b: float) -> float:
    if b == 0:
        raise ValueError("division by zero")
    return a / b


def word_count(text: str) -> int:
    return len(text.split())
