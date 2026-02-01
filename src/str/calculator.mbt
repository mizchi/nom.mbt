///| Token parser: skip surrounding whitespace
fn[O] token(parser : @nom.Parser[StringView, O]) -> @nom.Parser[StringView, O] {
  fn(input) {
    match space0(input) {
      Ok((_, rest1)) =>
        match parser(rest1) {
          Ok((value, rest2)) =>
            match space0(rest2) {
              Ok((_, rest3)) => Ok((value, rest3))
              Err(err) => Err(err)
            }
          Err(err) => Err(err)
        }
      Err(err) => Err(err)
    }
  }
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
  fn parse(input) {
    match parens(expr)(input) {
      Ok(result) => Ok(result)
      Err(@nom.Err::Failure(err)) => Err(@nom.Err::Failure(err))
      Err(@nom.Err::Error(_)) => int(input)
      Err(@nom.Err::Incomplete(needed)) =>
        match int(input) {
          Ok(result) => Ok(result)
          Err(@nom.Err::Failure(err)) => Err(@nom.Err::Failure(err))
          Err(@nom.Err::Error(_)) => Err(@nom.Err::Incomplete(needed))
          Err(@nom.Err::Incomplete(needed2)) => Err(@nom.Err::Incomplete(needed2))
        }
    }
  }
  token(parse)(input)
}

///| Parse a term with * and /
fn term(input : StringView) -> @nom.IResult[StringView, Int] {
  match factor(input) {
    Ok((value, rest)) =>
      @nom.fold_many0(
        @nom.complete(@nom.pair(token(one_of2('*', '/')), factor)),
        () => value,
        (acc, item) => {
          let op = item.0
          let rhs = item.1
          if op == '*' { acc * rhs } else { acc / rhs }
        },
      )(rest)
    Err(err) => Err(err)
  }
}

///| Parse an expression with + and -
fn expr(input : StringView) -> @nom.IResult[StringView, Int] {
  match term(input) {
    Ok((value, rest)) =>
      @nom.fold_many0(
        @nom.complete(@nom.pair(token(one_of2('+', '-')), term)),
        () => value,
        (acc, item) => {
          let op = item.0
          let rhs = item.1
          if op == '+' { acc + rhs } else { acc - rhs }
        },
      )(rest)
    Err(err) => Err(err)
  }
}

///| Public calculator parser
pub fn parse_calc(input : StringView) -> @nom.IResult[StringView, Int] {
  expr(input)
}
