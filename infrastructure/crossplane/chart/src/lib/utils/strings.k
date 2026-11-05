import regex

dash_name: (str) -> str = lambda name: str {
  dashed_name = regex.replace(name, "/", "-")
}
