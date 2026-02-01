///| Benchmarks for string parsers

let expr_short = "1 + 2 * 3 - 4 / 5 + 6 * (7 + 8) - 9"

let expr_long =
  "1 + 2 * 3 - 4 / 5 + 6 * (7 + 8) - 9 + 10 * 11 - 12 / 13 + 14 * (15 + 16) - 17 + 18 * 19 - 20 / 21 + 22 * (23 + 24) - 25 + 26 * 27 - 28 / 29 + 30 * (31 + 32) - 33 + 34 * 35 - 36 / 37 + 38 * (39 + 40) - 41 + 42 * 43 - 44 / 45 + 46 * (47 + 48) - 49 + 50"

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
