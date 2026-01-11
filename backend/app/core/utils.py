import random
import re


def mask_text_with_blanks(text: str, mask_ratio: float = 0.25) -> tuple[str, list[dict], list[str]]:
    """
    Replaces selected words with [BLANK_n] placeholders.
    Returns the masked text, blank metadata (key/length), and answers list.
    """
    word_matches = list(re.finditer(r"\b[\w']+\b", text))
    eligible = [match for match in word_matches if len(match.group()) > 2]
    if not eligible:
        return text, [], []

    blanks_count = max(1, int(len(eligible) * mask_ratio))
    selected = random.sample(eligible, k=min(len(eligible), blanks_count))
    selected = sorted(selected, key=lambda match: match.start())

    masked_parts = []
    blanks_metadata = []
    answers = []
    cursor = 0

    for index, match in enumerate(selected, start=1):
        key = f"BLANK_{index}"
        masked_parts.append(text[cursor:match.start()])
        masked_parts.append(f"[{key}]")
        cursor = match.end()

        answer = match.group()
        answers.append(answer)
        blanks_metadata.append({"key": key, "length": len(answer)})

    masked_parts.append(text[cursor:])

    return "".join(masked_parts), blanks_metadata, answers


def mask_text(text: str, mask_ratio: float = 0.4) -> str:
    """
    Replaces random words with asterisks, keeping punctuation/newlines.
    mask_ratio: Percentage of words to hide (0.4 = 40%)
    """
    words = text.split()
    masked_output = []

    for word in words:
        # Don't mask very short words (<= 2 chars)
        # Randomly mask words based on the ratio
        if len(word) > 2 and random.random() < mask_ratio:
            masked_output.append("*" * len(word))
        else:
            masked_output.append(word)

    return " ".join(masked_output)
