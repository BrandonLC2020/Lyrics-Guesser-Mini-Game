import random


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
