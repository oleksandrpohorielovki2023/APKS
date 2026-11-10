"""Command-line interface: ``python -m lab1 <command> ...``."""

import argparse
import sys

from lab1.core import add, divide, word_count


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog="lab1")
    sub = parser.add_subparsers(dest="command", required=True)
    for name in ("add", "div"):
        p = sub.add_parser(name)
        p.add_argument("a", type=float)
        p.add_argument("b", type=float)
    sub.add_parser("wc").add_argument("text")

    args = parser.parse_args(argv)
    try:
        if args.command == "add":
            print(add(args.a, args.b))
        elif args.command == "div":
            print(divide(args.a, args.b))
        else:
            print(word_count(args.text))
    except ValueError as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
