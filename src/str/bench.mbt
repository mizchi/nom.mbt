///| Benchmarks for string parsers

let expr_short = "1 + 2 * 3 - 4 / 5 + 6 * (7 + 8) - 9"

let expr_long =
  "1 + 2 * 3 - 4 / 5 + 6 * (7 + 8) - 9 + 10 * 11 - 12 / 13 + 14 * (15 + 16) - 17 + 18 * 19 - 20 / 21 + 22 * (23 + 24) - 25 + 26 * 27 - 28 / 29 + 30 * (31 + 32) - 33 + 34 * 35 - 36 / 37 + 38 * (39 + 40) - 41 + 42 * 43 - 44 / 45 + 46 * (47 + 48) - 49 + 50"

// Unicode whitespace for non-ASCII benchmarks.
// U+3000 IDEOGRAPHIC SPACE, U+2003 EM SPACE.
let ws_ideo : String = (0x3000 : Int).unsafe_to_char().to_string()
let ws_em : String = (0x2003 : Int).unsafe_to_char().to_string()

fn with_unicode_ws(expr : StringView) -> String {
  let sb = StringBuilder::new(size_hint=expr.length())
  let mut toggle = false
  for ch in expr {
    if ch == ' ' {
      if toggle {
        sb.write_string(ws_ideo)
      } else {
        sb.write_string(ws_em)
      }
      toggle = not(toggle)
    } else {
      sb.write_char(ch)
    }
  }
  sb.to_string()
}

let expr_unicode_short : String = with_unicode_ws(expr_short[:])

let expr_unicode_long : String = with_unicode_ws(expr_long[:])

fn u(code : Int) -> String {
  (code : Int).unsafe_to_char().to_string()
}

fn fullwidth_number(n : Int) -> String {
  let s = n.to_string()
  let zero = '0'.to_int()
  let sb = StringBuilder::new(size_hint=s.length())
  for ch in s {
    let d = ch.to_int() - zero
    sb.write_char((0xff10 + d).unsafe_to_char())
  }
  sb.to_string()
}

let eq_char : Char = (0xff1d : Int).unsafe_to_char()
let sep_char : Char = (0xff1b : Int).unsafe_to_char()
let eq_str : String = eq_char.to_string()
let sep_str : String = sep_char.to_string()

let id_base : String = u(0x5909) + u(0x6570)

fn ident(n : Int) -> String {
  id_base + fullwidth_number(n)
}

fn make_assignments(pairs : Array[(String, Int)]) -> String {
  let sb = StringBuilder::new()
  let mut first = true
  for pair in pairs {
    let key = pair.0
    let value = pair.1
    if not(first) {
      sb.write_string(sep_str)
      sb.write_string(ws_ideo)
    }
    first = false
    sb.write_string(key)
    sb.write_string(ws_ideo)
    sb.write_string(eq_str)
    sb.write_string(ws_em)
    sb.write_string(fullwidth_number(value))
  }
  sb.to_string()
}

let assign_pairs_short : Array[(String, Int)] = [
  (ident(1), 123),
  (ident(2), 456),
  (ident(3), 789),
  (ident(4), 234),
  (ident(5), 567),
]

let assign_pairs_long : Array[(String, Int)] = [
  (ident(1), 12),
  (ident(2), 34),
  (ident(3), 56),
  (ident(4), 78),
  (ident(5), 90),
  (ident(6), 123),
  (ident(7), 234),
  (ident(8), 345),
  (ident(9), 456),
  (ident(10), 567),
  (ident(11), 678),
  (ident(12), 789),
  (ident(13), 890),
  (ident(14), 901),
  (ident(15), 2345),
  (ident(16), 3456),
  (ident(17), 4567),
  (ident(18), 5678),
  (ident(19), 6789),
  (ident(20), 7890),
]

let assign_pairs_single : Array[(String, Int)] = [
  (ident(1), 123),
]

let assign_unicode_short : String = make_assignments(assign_pairs_short)
let assign_unicode_long : String = make_assignments(assign_pairs_long)
let assign_unicode_single : String = make_assignments(assign_pairs_single)

let unicode_ws_sample : String = {
  let sb = StringBuilder::new()
  for _ in 0..<64 {
    sb.write_string(ws_ideo)
    sb.write_string(ws_em)
  }
  sb.to_string()
}

let unicode_ident_sample : String = ident(12345)
let unicode_number_sample : String = fullwidth_number(123456789)

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

fn is_fullwidth_digit(ch : Char) -> Bool {
  let v = ch.to_int()
  v >= 0xff10 && v <= 0xff19
}

fn fullwidth_digit1(input : StringView) -> @nom.IResult[StringView, StringView] {
  take_while1(is_fullwidth_digit)(input)
}

fn parse_fullwidth_digits(digits : StringView) -> Result[Int, Unit] {
  let mut acc = 0
  for ch in digits {
    if not(is_fullwidth_digit(ch)) {
      return Err(())
    }
    acc = acc * 10 + (ch.to_int() - 0xff10)
  }
  Ok(acc)
}

fn number_fullwidth(input : StringView) -> @nom.IResult[StringView, Int] {
  @nom.map_res(fullwidth_digit1, parse_fullwidth_digits, @nom.ErrorKind::MapRes)(
    input,
  )
}

fn is_ident_char_unicode(ch : Char) -> Bool {
  not(ch.is_ascii()) &&
  not(ch.is_whitespace()) &&
  ch != eq_char &&
  ch != sep_char
}

fn ident_unicode(input : StringView) -> @nom.IResult[StringView, StringView] {
  take_while1(is_ident_char_unicode)(input)
}

fn assignment_unicode(input : StringView) -> @nom.IResult[StringView, Int] {
  @nom.preceded(
    token_unicode(ident_unicode),
    @nom.preceded(token_unicode(char(eq_char)), number_fullwidth),
  )(input)
}

fn assignments_unicode(input : StringView) -> @nom.IResult[StringView, Int] {
  match assignment_unicode(input) {
    Ok((value, rest)) =>
      @nom.fold_many0(
        @nom.complete(
          @nom.preceded(token_unicode(char(sep_char)), assignment_unicode),
        ),
        () => value,
        (acc, item) => acc + item,
      )(rest)
    Err(err) => Err(err)
  }
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

fn parse_ident_unicode_hand(
  input : StringView,
  idx : Int,
  len : Int,
) -> Int? {
  let mut i = idx
  if i >= len {
    return None
  }
  match input.get_char(i) {
    Some(c) =>
      if is_ident_char_unicode(c) {
        i = i + 1
      } else {
        return None
      }
    None => return None
  }
  while i < len {
    match input.get_char(i) {
      Some(c) =>
        if is_ident_char_unicode(c) {
          i = i + 1
        } else {
          break
        }
      None => break
    }
  }
  Some(i)
}

fn parse_fullwidth_number_hand(
  input : StringView,
  idx : Int,
  len : Int,
) -> (Int, Int)? {
  let mut i = idx
  if i >= len {
    return None
  }
  match input.get_char(i) {
    Some(c) =>
      if not(is_fullwidth_digit(c)) {
        return None
      }
    None => return None
  }
  let mut val = 0
  while i < len {
    match input.get_char(i) {
      Some(c) =>
        if is_fullwidth_digit(c) {
          val = val * 10 + (c.to_int() - 0xff10)
          i = i + 1
        } else {
          break
        }
      None => break
    }
  }
  Some((val, i))
}

fn parse_assignment_hand_unicode(
  input : StringView,
  idx : Int,
  len : Int,
) -> (Int, Int)? {
  let mut i = skip_ws_unicode(input, idx, len)
  match parse_ident_unicode_hand(input, i, len) {
    Some(next_ident) => i = skip_ws_unicode(input, next_ident, len)
    None => return None
  }
  match input.get_char(i) {
    Some(c) =>
      if c == eq_char {
        i = i + 1
      } else {
        return None
      }
    None => return None
  }
  i = skip_ws_unicode(input, i, len)
  match parse_fullwidth_number_hand(input, i, len) {
    Some((value, next)) => Some((value, next))
    None => None
  }
}

fn parse_assignments_hand_unicode(input : StringView) -> Int? {
  let len = input.char_length()
  match parse_assignment_hand_unicode(input, 0, len) {
    Some((value, next)) => {
      let mut acc = value
      let mut i = next
      while true {
        let sep_idx = skip_ws_unicode(input, i, len)
        if sep_idx >= len {
          i = sep_idx
          break
        }
        match input.get_char(sep_idx) {
          Some(c) =>
            if c == sep_char {
              match parse_assignment_hand_unicode(input, sep_idx + 1, len) {
                Some((rhs, next2)) => {
                  acc = acc + rhs
                  i = next2
                }
                None => break
              }
            } else {
              i = sep_idx
              break
            }
          None => break
        }
      }
      let end = skip_ws_unicode(input, i, len)
      if end == len { Some(acc) } else { None }
    }
    None => None
  }
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

///|
test "bench: assignments unicode short" (b : @bench.T) {
  let parser = @nom.all_consuming(assignments_unicode)
  let input = assign_unicode_short[:]
  b.bench(fn() { b.keep(parser(input)) })
}

///|
test "bench: assignments unicode long" (b : @bench.T) {
  let parser = @nom.all_consuming(assignments_unicode)
  let input = assign_unicode_long[:]
  b.bench(fn() { b.keep(parser(input)) })
}

///|
test "bench: assignments unicode hand short" (b : @bench.T) {
  let input = assign_unicode_short[:]
  b.bench(fn() { b.keep(parse_assignments_hand_unicode(input)) })
}

///|
test "bench: assignments unicode hand long" (b : @bench.T) {
  let input = assign_unicode_long[:]
  b.bench(fn() { b.keep(parse_assignments_hand_unicode(input)) })
}

///|
test "bench: unicode ws scan" (b : @bench.T) {
  let input = unicode_ws_sample[:]
  b.bench(fn() { b.keep(space0_unicode(input)) })
}

///|
test "bench: unicode ws scan hand" (b : @bench.T) {
  let input = unicode_ws_sample[:]
  let len = input.char_length()
  b.bench(fn() { b.keep(skip_ws_unicode(input, 0, len)) })
}

///|
test "bench: unicode ident" (b : @bench.T) {
  let input = unicode_ident_sample[:]
  b.bench(fn() { b.keep(ident_unicode(input)) })
}

///|
test "bench: unicode ident hand" (b : @bench.T) {
  let input = unicode_ident_sample[:]
  let len = input.char_length()
  b.bench(fn() { b.keep(parse_ident_unicode_hand(input, 0, len)) })
}

///|
test "bench: unicode number" (b : @bench.T) {
  let input = unicode_number_sample[:]
  b.bench(fn() { b.keep(number_fullwidth(input)) })
}

///|
test "bench: unicode number hand" (b : @bench.T) {
  let input = unicode_number_sample[:]
  let len = input.char_length()
  b.bench(fn() { b.keep(parse_fullwidth_number_hand(input, 0, len)) })
}

///|
test "bench: unicode assignment" (b : @bench.T) {
  let parser = @nom.all_consuming(assignment_unicode)
  let input = assign_unicode_single[:]
  b.bench(fn() { b.keep(parser(input)) })
}

///|
test "bench: unicode assignment hand" (b : @bench.T) {
  let input = assign_unicode_single[:]
  b.bench(fn() { b.keep(parse_assignment_hand_unicode(input, 0, input.char_length())) })
}
