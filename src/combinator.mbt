///| Map the output of a parser
pub fn[I, O, O2] map(
  parser : Parser[I, O],
  f : (O) -> O2,
) -> Parser[I, O2] {
  fn(input) {
    match parser(input) {
      Ok((value, rest)) => Ok((f(value), rest))
      Err(err) => Err(err)
    }
  }
}

///| Map the output, returning a constant value on success
pub fn[I, O, O2] value(
  v : O2,
  parser : Parser[I, O],
) -> Parser[I, O2] {
  map(parser, (_) => v)
}

///| Optional parser (never fails)
pub fn[I, O] opt(parser : Parser[I, O]) -> Parser[I, O?] {
  fn(input) {
    match parser(input) {
      Ok((value, rest)) => Ok((Some(value), rest))
      Err(Err::Error(_)) => Ok((None, input))
      Err(Err::Failure(err)) => Err(Err::Failure(err))
      Err(Err::Incomplete(needed)) => Err(Err::Incomplete(needed))
    }
  }
}

///| Convert recoverable errors into failures (like nom::combinator::cut)
pub fn[I, O] cut(parser : Parser[I, O]) -> Parser[I, O] {
  fn(input) {
    match parser(input) {
      Ok(result) => Ok(result)
      Err(Err::Error(err)) => Err(Err::Failure(err))
      Err(Err::Failure(err)) => Err(Err::Failure(err))
      Err(Err::Incomplete(needed)) => Err(Err::Incomplete(needed))
    }
  }
}

///| Attach context labels to errors
pub fn[I, O] context(label : String, parser : Parser[I, O]) -> Parser[I, O] {
  fn(input) {
    match parser(input) {
      Ok(result) => Ok(result)
      Err(Err::Error(err)) => Err(Err::Error(err.with_context(label)))
      Err(Err::Failure(err)) => Err(Err::Failure(err.with_context(label)))
      Err(Err::Incomplete(needed)) => Err(Err::Incomplete(needed))
    }
  }
}

///| Map errors
pub fn[I, O] map_err(
  parser : Parser[I, O],
  f : (ParseError[I]) -> ParseError[I],
) -> Parser[I, O] {
  fn(input) {
    match parser(input) {
      Ok(result) => Ok(result)
      Err(Err::Error(err)) => Err(Err::Error(f(err)))
      Err(Err::Failure(err)) => Err(Err::Failure(f(err)))
      Err(Err::Incomplete(needed)) => Err(Err::Incomplete(needed))
    }
  }
}

///| Convert streaming Incomplete into a normal error (for complete parsing)
pub fn[I, O] complete(parser : Parser[I, O]) -> Parser[I, O] {
  fn(input) {
    match parser(input) {
      Ok(result) => Ok(result)
      Err(Err::Incomplete(_)) => Err(Err::Error(ParseError::new(input, ErrorKind::Eof)))
      Err(err) => Err(err)
    }
  }
}

///| Map the output with a fallible function
pub fn[I, O, O2, E2] map_res(
  parser : Parser[I, O],
  f : (O) -> Result[O2, E2],
  kind : ErrorKind,
) -> Parser[I, O2] {
  fn(input) {
    match parser(input) {
      Ok((value, rest)) =>
        match f(value) {
          Ok(next) => Ok((next, rest))
          Err(_) => Err(Err::Error(ParseError::new(input, kind)))
        }
      Err(err) => Err(err)
    }
  }
}
