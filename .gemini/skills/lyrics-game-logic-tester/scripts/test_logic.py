import argparse
import sys
import os

# Ensure the app can be imported
sys.path.append(os.path.join(os.getcwd(), "backend"))

try:
    from app.core.utils import mask_text, mask_text_with_blanks
    from thefuzz import fuzz
except ImportError as e:
    print(f"Error: {e}. Make sure to run from project root with PYTHONPATH including 'backend'.")
    sys.exit(1)

def main():
    parser = argparse.ArgumentParser(description="Test game masking and scoring logic.")
    parser.add_argument("--text", type=str, help="Text to mask or check.")
    parser.add_argument("--mode", choices=["mask", "blanks", "fuzz"], default="mask")
    parser.add_argument("--ratio", type=float, default=0.25)
    parser.add_argument("--guess", type=str, help="Guess for fuzz mode.")
    parser.add_argument("--answer", type=str, help="Answer for fuzz mode.")

    args = parser.parse_args()

    if args.mode == "mask":
        if not args.text:
            args.text = "Hello, world! This is a test of the masking logic."
        print(f"Original: {args.text}")
        print(f"Masked (ratio={args.ratio}):")
        print(mask_text(args.text, mask_ratio=args.ratio))

    elif args.mode == "blanks":
        if not args.text:
            args.text = "Hello, world! This is a test of the blanking logic."
        print(f"Original: {args.text}")
        masked, metadata, answers = mask_text_with_blanks(args.text, mask_ratio=args.ratio)
        print(f"Masked: {masked}")
        print(f"Metadata: {metadata}")
        print(f"Answers: {answers}")

    elif args.mode == "fuzz":
        if not args.guess or not args.answer:
            print("Error: --guess and --answer required for fuzz mode.")
            return
        score = fuzz.ratio(args.guess.lower(), args.answer.lower())
        print(f"Guess: '{args.guess}', Answer: '{args.answer}'")
        print(f"Score: {score} (Threshold > 80 is CORRECT)")

if __name__ == "__main__":
    main()
