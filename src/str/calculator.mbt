///| Token parser: skip surrounding whitespace
fn[O] token(parser : @nom.Parser[StringView, O]) -> @nom.Parser[StringView, O] {
  @nom.delimited(space0, parser, space0)
}

///| Parse a parenthesized expression
fn parens(parser : @nom.Parser[StringView, Int]) -> @nom.Parser[StringView, Int] {
  @nom.delimited(
    token(char('(')),
    parser,
    token(char(')')),
  )
}

///| Parse a factor: number or parenthesized expression
fn factor(input : StringView) -> @nom.IResult[StringView, Int] {
  let parser = @nom.alt([
    parens(expr),
    int,
  ])
  token(parser)(input)
}

///| Parse a term with * and /
fn term(input : StringView) -> @nom.IResult[StringView, Int] {
  match factor(input) {
    Ok((value, rest)) =>
      match @nom.many0(
        @nom.complete(@nom.pair(token(one_of("*/"[:])), factor)),
      )(rest) {
        Ok((items, rest2)) => {
          let mut acc = value
          for _, item in items {
            let op = item.0
            let rhs = item.1
            if op == '*' {
              acc = acc * rhs
            } else {
              acc = acc / rhs
            }
          }
          Ok((acc, rest2))
        }
        Err(err) => Err(err)
      }
    Err(err) => Err(err)
  }
}

///| Parse an expression with + and -
fn expr(input : StringView) -> @nom.IResult[StringView, Int] {
  match term(input) {
    Ok((value, rest)) =>
      match @nom.many0(
        @nom.complete(@nom.pair(token(one_of("+-"[:])), term)),
      )(rest) {
        Ok((items, rest2)) => {
          let mut acc = value
          for _, item in items {
            let op = item.0
            let rhs = item.1
            if op == '+' {
              acc = acc + rhs
            } else {
              acc = acc - rhs
            }
          }
          Ok((acc, rest2))
        }
        Err(err) => Err(err)
      }
    Err(err) => Err(err)
  }
}

///| Public calculator parser
pub fn parse_calc(input : StringView) -> @nom.IResult[StringView, Int] {
  expr(input)
}
