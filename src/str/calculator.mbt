///| Expect a specific char
fn expect_char(input : StringView, expected : Char) -> @nom.IResult[StringView, Char] {
  match input.get_char(0) {
    Some(ch) =>
      if ch == expected {
        let offset = ch.utf16_len()
        Ok((ch, input.view(start_offset=offset)))
      } else {
        Err(@nom.Err::Error(@nom.ParseError::new(input, @nom.ErrorKind::Char)))
      }
    None => Err(@nom.Err::Incomplete(@nom.Needed::Size(1)))
  }
}

///| Parse a factor: number or parenthesized expression
fn factor(input : StringView) -> @nom.IResult[StringView, Int] {
  match space0(input) {
    Ok((_, rest1)) =>
      match rest1.get_char(0) {
        Some('(') => {
          let after_open = rest1.view(start_offset=1)
          match space0(after_open) {
            Ok((_, rest2)) =>
              match expr(rest2) {
                Ok((value, rest3)) =>
                  match space0(rest3) {
                    Ok((_, rest4)) =>
                      match expect_char(rest4, ')') {
                        Ok((_, rest5)) =>
                          match space0(rest5) {
                            Ok((_, rest6)) => Ok((value, rest6))
                            Err(err) => Err(err)
                          }
                        Err(err) => Err(err)
                      }
                    Err(err) => Err(err)
                  }
                Err(err) => Err(err)
              }
            Err(err) => Err(err)
          }
        }
        Some(_) =>
          match int(rest1) {
            Ok((value, rest2)) =>
              match space0(rest2) {
                Ok((_, rest3)) => Ok((value, rest3))
                Err(err) => Err(err)
              }
            Err(err) => Err(err)
          }
        None => Err(@nom.Err::Incomplete(@nom.Needed::Size(1)))
      }
    Err(err) => Err(err)
  }
}

///| Parse a term with * and /
fn term(input : StringView) -> @nom.IResult[StringView, Int] {
  match factor(input) {
    Ok((value, rest)) => {
      let mut acc = value
      let mut rest2 = rest
      while true {
        match rest2.get_char(0) {
          Some(op) =>
            if op == '*' || op == '/' {
              let after_op = rest2.view(start_offset=op.utf16_len())
              match factor(after_op) {
                Ok((rhs, rest3)) => {
                  if op == '*' { acc = acc * rhs } else { acc = acc / rhs }
                  rest2 = rest3
                }
                Err(err) => return Err(err)
              }
            } else {
              return Ok((acc, rest2))
            }
          None => return Ok((acc, rest2))
        }
      }
      Ok((acc, rest2))
    }
    Err(err) => Err(err)
  }
}

///| Parse an expression with + and -
fn expr(input : StringView) -> @nom.IResult[StringView, Int] {
  match term(input) {
    Ok((value, rest)) => {
      let mut acc = value
      let mut rest2 = rest
      while true {
        match rest2.get_char(0) {
          Some(op) =>
            if op == '+' || op == '-' {
              let after_op = rest2.view(start_offset=op.utf16_len())
              match term(after_op) {
                Ok((rhs, rest3)) => {
                  if op == '+' { acc = acc + rhs } else { acc = acc - rhs }
                  rest2 = rest3
                }
                Err(err) => return Err(err)
              }
            } else {
              return Ok((acc, rest2))
            }
          None => return Ok((acc, rest2))
        }
      }
      Ok((acc, rest2))
    }
    Err(err) => Err(err)
  }
}

///| Public calculator parser
pub fn parse_calc(input : StringView) -> @nom.IResult[StringView, Int] {
  expr(input)
}
