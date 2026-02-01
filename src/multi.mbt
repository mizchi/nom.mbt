///| Parse zero or more, collecting results
pub fn[I : InputLen, O] many0(parser : Parser[I, O]) -> Parser[I, Array[O]] {
  fn(input) {
    let acc : Array[O] = []
    fn rec(rest : I, acc : Array[O]) -> IResult[I, Array[O]] {
      match parser(rest) {
        Ok((value, next)) => {
          if next.length() == rest.length() {
            Err(Err::Failure(ParseError::new(rest, ErrorKind::Many0)))
          } else {
            acc.push(value)
            rec(next, acc)
          }
        }
        Err(Err::Error(_)) => Ok((acc, rest))
        Err(Err::Failure(err)) => Err(Err::Failure(err))
        Err(Err::Incomplete(needed)) => Err(Err::Incomplete(needed))
      }
    }
    rec(input, acc)
  }
}

///| Parse zero or more, folding into an accumulator (no allocations)
pub fn[I : InputLen, O, R] fold_many0(
  parser : Parser[I, O],
  init : () -> R,
  fold : (R, O) -> R,
) -> Parser[I, R] {
  fn(input) {
    let acc = init()
    fn rec(rest : I, acc : R) -> IResult[I, R] {
      match parser(rest) {
        Ok((value, next)) => {
          if next.length() == rest.length() {
            Err(Err::Failure(ParseError::new(rest, ErrorKind::Many0)))
          } else {
            rec(next, fold(acc, value))
          }
        }
        Err(Err::Error(_)) => Ok((acc, rest))
        Err(Err::Failure(err)) => Err(Err::Failure(err))
        Err(Err::Incomplete(needed)) => Err(Err::Incomplete(needed))
      }
    }
    rec(input, acc)
  }
}

///| Parse one or more, folding into an accumulator (no allocations)
pub fn[I : InputLen, O, R] fold_many1(
  parser : Parser[I, O],
  init : (O) -> R,
  fold : (R, O) -> R,
) -> Parser[I, R] {
  fn(input) {
    match parser(input) {
      Ok((value, rest)) => {
        let acc = init(value)
        fn rec(rest : I, acc : R) -> IResult[I, R] {
          match parser(rest) {
            Ok((value, next)) => {
              if next.length() == rest.length() {
                Err(Err::Failure(ParseError::new(rest, ErrorKind::Many0)))
              } else {
                rec(next, fold(acc, value))
              }
            }
            Err(Err::Error(_)) => Ok((acc, rest))
            Err(Err::Failure(err)) => Err(Err::Failure(err))
            Err(Err::Incomplete(needed)) => Err(Err::Incomplete(needed))
          }
        }
        rec(rest, acc)
      }
      Err(err) => Err(err)
    }
  }
}

///| Parse one or more, collecting results
pub fn[I : InputLen, O] many1(parser : Parser[I, O]) -> Parser[I, Array[O]] {
  fn(input) {
    match parser(input) {
      Ok((value, rest)) =>
        match many0(parser)(rest) {
          Ok((items, rest2)) => {
            let result : Array[O] = [value]
            result.append(items[:])
            Ok((result, rest2))
          }
          Err(err) => Err(err)
        }
      Err(err) => Err(err)
    }
  }
}

///| Parse a separated list (zero or more)
pub fn[I : InputLen, O, S] separated_list0(
  sep : Parser[I, S],
  parser : Parser[I, O],
) -> Parser[I, Array[O]] {
  fn(input) {
    match parser(input) {
      Ok((value, rest)) => {
        let acc : Array[O] = [value]
        fn rec(rest : I, acc : Array[O]) -> IResult[I, Array[O]] {
          match pair(sep, parser)(rest) {
            Ok((( _sep, item), next)) => {
              if next.length() == rest.length() {
                Err(Err::Failure(ParseError::new(rest, ErrorKind::Many0)))
              } else {
                acc.push(item)
                rec(next, acc)
              }
            }
            Err(Err::Error(_)) => Ok((acc, rest))
            Err(Err::Failure(err)) => Err(Err::Failure(err))
            Err(Err::Incomplete(needed)) => Err(Err::Incomplete(needed))
          }
        }
        rec(rest, acc)
      }
      Err(Err::Error(_)) => Ok(([], input))
      Err(Err::Failure(err)) => Err(Err::Failure(err))
      Err(Err::Incomplete(needed)) => Err(Err::Incomplete(needed))
    }
  }
}

///| Parse a separated list (one or more)
pub fn[I : InputLen, O, S] separated_list1(
  sep : Parser[I, S],
  parser : Parser[I, O],
) -> Parser[I, Array[O]] {
  fn(input) {
    match separated_list0(sep, parser)(input) {
      Ok((items, rest)) =>
        if items.is_empty() {
          Err(Err::Error(ParseError::new(input, ErrorKind::Many0)))
        } else {
          Ok((items, rest))
        }
      Err(err) => Err(err)
    }
  }
}
