///|
/// Parse two parsers in sequence
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

///|
/// Parse second after first, returning the second
pub fn[I, O1, O2] preceded(
  first : Parser[I, O1],
  second : Parser[I, O2],
) -> Parser[I, O2] {
  fn(input) {
    match first(input) {
      Ok((_, rest1)) =>
        match second(rest1) {
          Ok((value, rest2)) => Ok((value, rest2))
          Err(err) => Err(err)
        }
      Err(err) => Err(err)
    }
  }
}

///|
/// Parse second after first, returning the first
pub fn[I, O1, O2] terminated(
  first : Parser[I, O1],
  second : Parser[I, O2],
) -> Parser[I, O1] {
  fn(input) {
    match first(input) {
      Ok((value, rest1)) =>
        match second(rest1) {
          Ok((_, rest2)) => Ok((value, rest2))
          Err(err) => Err(err)
        }
      Err(err) => Err(err)
    }
  }
}

///|
/// Parse with start/end delimiters
pub fn[I, O1, O2, O3] delimited(
  open : Parser[I, O1],
  inner : Parser[I, O2],
  close : Parser[I, O3],
) -> Parser[I, O2] {
  fn(input) {
    match open(input) {
      Ok((_, rest1)) =>
        match inner(rest1) {
          Ok((value, rest2)) =>
            match close(rest2) {
              Ok((_, rest3)) => Ok((value, rest3))
              Err(err) => Err(err)
            }
          Err(err) => Err(err)
        }
      Err(err) => Err(err)
    }
  }
}
