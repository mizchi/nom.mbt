///| Try parsers in order, returning the first success
pub fn[I, O] alt(parsers : Array[Parser[I, O]]) -> Parser[I, O] {
  fn(input) {
    let mut last_err : Err[ParseError[I]]? = None
    let mut last_incomplete : Needed? = None
    for parser in parsers {
      match parser(input) {
        Ok(result) => return Ok(result)
        Err(Err::Failure(err)) => return Err(Err::Failure(err))
        Err(Err::Error(err)) => last_err = Some(Err::Error(err))
        Err(Err::Incomplete(needed)) => last_incomplete = Some(needed)
      }
    }
    match last_incomplete {
      Some(needed) => Err(Err::Incomplete(needed))
      None =>
        match last_err {
          Some(err) => Err(err)
          None => Err(Err::Error(ParseError::new(input, ErrorKind::Alt)))
        }
    }
  }
}
