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
      @nom.fold_many0(
        @nom.complete(@nom.pair(token(one_of("*/"[:])), factor)),
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
        @nom.complete(@nom.pair(token(one_of("+-"[:])), term)),
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
