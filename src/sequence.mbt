///| Parse two parsers in sequence
pub fn[I, O1, O2] pair(
  first : Parser[I, O1],
  second : Parser[I, O2],
) -> Parser[I, (O1, O2)] {
  fn(input) {
    match first(input) {
      Ok((value1, rest1)) =>
        match second(rest1) {
          Ok((value2, rest2)) => Ok(((value1, value2), rest2))
          Err(err) => Err(err)
        }
      Err(err) => Err(err)
    }
  }
}

///| Parse second after first, returning the second
pub fn[I, O1, O2] preceded(
  first : Parser[I, O1],
  second : Parser[I, O2],
) -> Parser[I, O2] {
  map(pair(first, second), (p) => p.1)
}

///| Parse second after first, returning the first
pub fn[I, O1, O2] terminated(
  first : Parser[I, O1],
  second : Parser[I, O2],
) -> Parser[I, O1] {
  map(pair(first, second), (p) => p.0)
}

///| Parse with start/end delimiters
pub fn[I, O1, O2, O3] delimited(
  open : Parser[I, O1],
  inner : Parser[I, O2],
  close : Parser[I, O3],
) -> Parser[I, O2] {
  preceded(open, terminated(inner, close))
}
