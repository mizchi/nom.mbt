///| Match end of input
pub fn[I : InputLen] eof(input : I) -> IResult[I, Unit] {
  if input.length() == 0 {
    Ok(((), input))
  } else {
    Err(Err::Error(ParseError::new(input, ErrorKind::Eof)))
  }
}

///| Ensure the parser consumes all input
pub fn[I : InputLen, O] all_consuming(parser : Parser[I, O]) -> Parser[I, O] {
  fn(input) {
    match parser(input) {
      Ok((value, rest)) =>
        if rest.length() == 0 {
          Ok((value, rest))
        } else {
          Err(Err::Error(ParseError::new(rest, ErrorKind::Eof)))
        }
      Err(err) => Err(err)
    }
  }
}
