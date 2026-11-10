import pytest

from lab1.__main__ import main
from lab1.core import add, divide, word_count


def test_add():
    assert add(2, 3) == 5


def test_divide():
    assert divide(9, 3) == 3


def test_divide_by_zero():
    with pytest.raises(ValueError):
        divide(1, 0)


@pytest.mark.parametrize("text, expected", [("", 0), ("one", 1), ("a  b\tc", 3)])
def test_word_count(text, expected):
    assert word_count(text) == expected


def test_cli_add(capsys):
    assert main(["add", "2", "3"]) == 0
    assert capsys.readouterr().out.strip() == "5.0"


def test_cli_div_by_zero(capsys):
    assert main(["div", "1", "0"]) == 1
    assert "division by zero" in capsys.readouterr().err
