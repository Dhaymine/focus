"""Silence the deprecated <experimental/coroutine> error on newer MSVC."""
import pathlib
import sys

path = pathlib.Path("windows/CMakeLists.txt")
if not path.exists():
    sys.exit("windows/CMakeLists.txt not found")

text = path.read_text()
marker = "_SILENCE_EXPERIMENTAL_COROUTINE_DEPRECATION_WARNINGS"
if marker not in text:
    text = text.replace(
        "project(",
        "add_compile_definitions(_SILENCE_EXPERIMENTAL_COROUTINE_DEPRECATION_WARNINGS)\nproject(",
        1,
    )
    # add_compile_definitions before project() is allowed, but place a safe
    # fallback after project() as well.
    path.write_text(text)
print("Windows project patched")
print(path.read_text()[:600])
