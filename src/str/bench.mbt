///| Benchmarks for string parsers

let expr_short = "1 + 2 * 3 - 4 / 5 + 6 * (7 + 8) - 9"

let expr_long =
  "1 + 2 * 3 - 4 / 5 + 6 * (7 + 8) - 9 + 10 * 11 - 12 / 13 + 14 * (15 + 16) - 17 + 18 * 19 - 20 / 21 + 22 * (23 + 24) - 25 + 26 * 27 - 28 / 29 + 30 * (31 + 32) - 33 + 34 * 35 - 36 / 37 + 38 * (39 + 40) - 41 + 42 * 43 - 44 / 45 + 46 * (47 + 48) - 49 + 50"

// Unicode whitespace for non-ASCII benchmarks.
// U+3000 IDEOGRAPHIC SPACE, U+2003 EM SPACE.
let ws_ideo : String = (0x3000 : Int).unsafe_to_char().to_string()
let ws_em : String = (0x2003 : Int).unsafe_to_char().to_string()

let expr_unicode_short =
  "1\{ws_ideo}+\{ws_em}2\{ws_ideo}*\{ws_em}3\{ws_ideo}-\{ws_em}4\{ws_ideo}/\{ws_em}5\{ws_ideo}+\{ws_em}6\{ws_ideo}*\{ws_em}(\{ws_ideo}7\{ws_em}+\{ws_ideo}8\{ws_em})\{ws_ideo}-\{ws_em}9"

let expr_unicode_long =
  "1\{ws_ideo}+\{ws_em}2\{ws_ideo}*\{ws_em}3\{ws_ideo}-\{ws_em}4\{ws_ideo}/\{ws_em}5\{ws_ideo}+\{ws_em}6\{ws_ideo}*\{ws_em}(\{ws_ideo}7\{ws_em}+\{ws_ideo}8\{ws_em})\{ws_ideo}-\{ws_em}9\{ws_ideo}+\{ws_em}10\{ws_ideo}*\{ws_em}11\{ws_ideo}-\{ws_em}12\{ws_ideo}/\{ws_em}13\{ws_ideo}+\{ws_em}14\{ws_ideo}*\{ws_em}(\{ws_ideo}15\{ws_em}+\{ws_ideo}16\{ws_em})\{ws_ideo}-\{ws_em}17\{ws_ideo}+\{ws_em}18\{ws_ideo}*\{ws_em}19\{ws_ideo}-\{ws_em}20\{ws_ideo}/\{ws_em}21\{ws_ideo}+\{ws_em}22\{ws_ideo}*\{ws_em}(\{ws_ideo}23\{ws_em}+\{ws_ideo}24\{ws_em})\{ws_ideo}-\{ws_em}25"

fn skip_ws(input : StringView, idx : Int, len : Int) -> Int {
  let mut i = idx
  while i < len {
    match input.get_char(i) {
      Some(c) =>
        if c.is_ascii_whitespace() {
          i = i + 1
        } else {
          break
        }
      None => break
    }
  }
  i
}

fn parse_number(input : StringView, idx : Int, len : Int) -> (Int, Int)? {
  let mut i = idx
  let mut sign = 1
  if i < len {
    match input.get_char(i) {
      Some('+') => i = i + 1
      Some('-') => {
        sign = -1
        i = i + 1
      }
      _ => ()
    }
  }
  if i >= len {
    return None
  }
  let zero = '0'.to_int()
  match input.get_char(i) {
    Some(c) =>
      if not(c.is_ascii_digit()) {
        return None
      }
    None => return None
  }
  let mut val = 0
  while i < len {
    match input.get_char(i) {
      Some(c) =>
        if c.is_ascii_digit() {
          val = val * 10 + (c.to_int() - zero)
          i = i + 1
        } else {
          break
        }
      None => break
    }
  }
  Some((val * sign, i))
}

fn parse_factor(input : StringView, idx : Int, len : Int) -> (Int, Int)? {
  let mut i = skip_ws(input, idx, len)
  if i >= len {
    return None
  }
  match input.get_char(i) {
    Some('(') => {
      i = i + 1
      match parse_expr(input, i, len) {
        Some((value, next)) => {
          let j = skip_ws(input, next, len)
          match input.get_char(j) {
            Some(')') => Some((value, j + 1))
            _ => None
          }
        }
        None => None
      }
    }
    _ => parse_number(input, i, len)
  }
}

fn parse_term(input : StringView, idx : Int, len : Int) -> (Int, Int)? {
  match parse_factor(input, idx, len) {
    Some((value, next)) => {
      let mut acc = value
      let mut i = next
      while true {
        let op_idx = skip_ws(input, i, len)
        if op_idx >= len {
          break
        }
        let op = input.get_char(op_idx)
        match op {
          Some('*') => {
            match parse_factor(input, op_idx + 1, len) {
              Some((rhs, next2)) => {
                acc = acc * rhs
                i = next2
              }
              None => break
            }
          }
          Some('/') => {
            match parse_factor(input, op_idx + 1, len) {
              Some((rhs, next2)) => {
                acc = acc / rhs
                i = next2
              }
              None => break
            }
          }
          _ => break
        }
      }
      Some((acc, i))
    }
    None => None
  }
}

fn parse_expr(input : StringView, idx : Int, len : Int) -> (Int, Int)? {
  match parse_term(input, idx, len) {
    Some((value, next)) => {
      let mut acc = value
      let mut i = next
      while true {
        let op_idx = skip_ws(input, i, len)
        if op_idx >= len {
          break
        }
        let op = input.get_char(op_idx)
        match op {
          Some('+') => {
            match parse_term(input, op_idx + 1, len) {
              Some((rhs, next2)) => {
                acc = acc + rhs
                i = next2
              }
              None => break
            }
          }
          Some('-') => {
            match parse_term(input, op_idx + 1, len) {
              Some((rhs, next2)) => {
                acc = acc - rhs
                i = next2
              }
              None => break
            }
          }
          _ => break
        }
      }
      Some((acc, i))
    }
    None => None
  }
}

fn parse_calc_hand(input : StringView) -> Int? {
  let len = input.char_length()
  match parse_expr(input, 0, len) {
    Some((value, next)) => {
      let end = skip_ws(input, next, len)
      if end == len { Some(value) } else { None }
    }
    None => None
  }
}

fn space0_unicode(input : StringView) -> @nom.IResult[StringView, StringView] {
  take_while((ch) => ch.is_whitespace())(input)
}

fn digit1_unicode(input : StringView) -> @nom.IResult[StringView, StringView] {
  take_while1((ch) => ch.is_ascii_digit())(input)
}

fn[O] token_unicode(
  parser : @nom.Parser[StringView, O],
) -> @nom.Parser[StringView, O] {
  @nom.delimited(space0_unicode, parser, space0_unicode)
}

fn int_unicode(input : StringView) -> @nom.IResult[StringView, Int] {
  let parser = @nom.map_res(
    @nom.pair(@nom.opt(one_of("+-"[:] )), digit1_unicode),
    (pair) => {
      let sign = pair.0
      let digits = pair.1
      let parsed : Result[Int, @strconv.StrConvError] =
        try? @strconv.parse_int(digits)
      match parsed {
        Ok(value) =>
          if sign is Some('-') {
            Ok(-value)
          } else {
            Ok(value)
          }
        Err(_) => Err(())
      }
    },
    @nom.ErrorKind::MapRes,
  )
  parser(input)
}

fn parens_unicode(
  parser : @nom.Parser[StringView, Int],
) -> @nom.Parser[StringView, Int] {
  @nom.delimited(
    token_unicode(char('(')),
    parser,
    token_unicode(char(')')),
  )
}

fn factor_unicode(input : StringView) -> @nom.IResult[StringView, Int] {
  let parser = @nom.alt([
    parens_unicode(expr_unicode),
    int_unicode,
  ])
  token_unicode(parser)(input)
}

fn term_unicode(input : StringView) -> @nom.IResult[StringView, Int] {
  match factor_unicode(input) {
    Ok((value, rest)) =>
      @nom.fold_many0(
        @nom.complete(@nom.pair(token_unicode(one_of("*/"[:])), factor_unicode)),
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

fn expr_unicode(input : StringView) -> @nom.IResult[StringView, Int] {
  match term_unicode(input) {
    Ok((value, rest)) =>
      @nom.fold_many0(
        @nom.complete(@nom.pair(token_unicode(one_of("+-"[:])), term_unicode)),
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

fn parse_calc_hand_unicode(input : StringView) -> Int? {
  let len = input.char_length()
  match parse_expr_unicode(input, 0, len) {
    Some((value, next)) => {
      let end = skip_ws_unicode(input, next, len)
      if end == len { Some(value) } else { None }
    }
    None => None
  }
}

fn skip_ws_unicode(input : StringView, idx : Int, len : Int) -> Int {
  let mut i = idx
  while i < len {
    match input.get_char(i) {
      Some(c) =>
        if c.is_whitespace() {
          i = i + 1
        } else {
          break
        }
      None => break
    }
  }
  i
}

fn parse_number_unicode(input : StringView, idx : Int, len : Int) -> (Int, Int)? {
  let mut i = idx
  let mut sign = 1
  if i < len {
    match input.get_char(i) {
      Some('+') => i = i + 1
      Some('-') => {
        sign = -1
        i = i + 1
      }
      _ => ()
    }
  }
  if i >= len {
    return None
  }
  let zero = '0'.to_int()
  match input.get_char(i) {
    Some(c) =>
      if not(c.is_ascii_digit()) {
        return None
      }
    None => return None
  }
  let mut val = 0
  while i < len {
    match input.get_char(i) {
      Some(c) =>
        if c.is_ascii_digit() {
          val = val * 10 + (c.to_int() - zero)
          i = i + 1
        } else {
          break
        }
      None => break
    }
  }
  Some((val * sign, i))
}

fn parse_factor_unicode(input : StringView, idx : Int, len : Int) -> (Int, Int)? {
  let mut i = skip_ws_unicode(input, idx, len)
  if i >= len {
    return None
  }
  match input.get_char(i) {
    Some('(') => {
      i = i + 1
      match parse_expr_unicode(input, i, len) {
        Some((value, next)) => {
          let j = skip_ws_unicode(input, next, len)
          match input.get_char(j) {
            Some(')') => Some((value, j + 1))
            _ => None
          }
        }
        None => None
      }
    }
    _ => parse_number_unicode(input, i, len)
  }
}

fn parse_term_unicode(input : StringView, idx : Int, len : Int) -> (Int, Int)? {
  match parse_factor_unicode(input, idx, len) {
    Some((value, next)) => {
      let mut acc = value
      let mut i = next
      while true {
        let op_idx = skip_ws_unicode(input, i, len)
        if op_idx >= len {
          break
        }
        let op = input.get_char(op_idx)
        match op {
          Some('*') => {
            match parse_factor_unicode(input, op_idx + 1, len) {
              Some((rhs, next2)) => {
                acc = acc * rhs
                i = next2
              }
              None => break
            }
          }
          Some('/') => {
            match parse_factor_unicode(input, op_idx + 1, len) {
              Some((rhs, next2)) => {
                acc = acc / rhs
                i = next2
              }
              None => break
            }
          }
          _ => break
        }
      }
      Some((acc, i))
    }
    None => None
  }
}

fn parse_expr_unicode(input : StringView, idx : Int, len : Int) -> (Int, Int)? {
  match parse_term_unicode(input, idx, len) {
    Some((value, next)) => {
      let mut acc = value
      let mut i = next
      while true {
        let op_idx = skip_ws_unicode(input, i, len)
        if op_idx >= len {
          break
        }
        let op = input.get_char(op_idx)
        match op {
          Some('+') => {
            match parse_term_unicode(input, op_idx + 1, len) {
              Some((rhs, next2)) => {
                acc = acc + rhs
                i = next2
              }
              None => break
            }
          }
          Some('-') => {
            match parse_term_unicode(input, op_idx + 1, len) {
              Some((rhs, next2)) => {
                acc = acc - rhs
                i = next2
              }
              None => break
            }
          }
          _ => break
        }
      }
      Some((acc, i))
    }
    None => None
  }
}

///|
test "bench: calculator short" (b : @bench.T) {
  let parser = @nom.all_consuming(parse_calc)
  let input = expr_short[:]
  b.bench(fn() { b.keep(parser(input)) })
}

///|
test "bench: calculator long" (b : @bench.T) {
  let parser = @nom.all_consuming(parse_calc)
  let input = expr_long[:]
  b.bench(fn() { b.keep(parser(input)) })
}

///|
test "bench: calculator hand short" (b : @bench.T) {
  let input = expr_short[:]
  b.bench(fn() { b.keep(parse_calc_hand(input)) })
}

///|
test "bench: calculator hand long" (b : @bench.T) {
  let input = expr_long[:]
  b.bench(fn() { b.keep(parse_calc_hand(input)) })
}

///|
test "bench: calculator unicode short" (b : @bench.T) {
  let parser = @nom.all_consuming(expr_unicode)
  let input = expr_unicode_short[:]
  b.bench(fn() { b.keep(parser(input)) })
}

///|
test "bench: calculator unicode long" (b : @bench.T) {
  let parser = @nom.all_consuming(expr_unicode)
  let input = expr_unicode_long[:]
  b.bench(fn() { b.keep(parser(input)) })
}

///|
test "bench: calculator unicode hand short" (b : @bench.T) {
  let input = expr_unicode_short[:]
  b.bench(fn() { b.keep(parse_calc_hand_unicode(input)) })
}

///|
test "bench: calculator unicode hand long" (b : @bench.T) {
  let input = expr_unicode_long[:]
  b.bench(fn() { b.keep(parse_calc_hand_unicode(input)) })
}
