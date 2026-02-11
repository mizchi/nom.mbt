///|
priv enum Token {
  Number(Int)
  Plus
  Minus
  Star
  Slash
  Percent
  Caret
  LParen
  RParen
}

///|
type CalcResult[O] = Result[(O, Int), @nom.Err[@nom.ParseError[StringView]]]

///|
fn err_at(
  input : StringView,
  offset : Int,
  kind : @nom.ErrorKind,
) -> @nom.Err[@nom.ParseError[StringView]] {
  @nom.Err::Error(@nom.ParseError::new(input.view(start_offset=offset), kind))
}

///|
fn skip_ws_ascii(input : StringView, offset : Int, len : Int) -> Int {
  let mut i = offset
  while i < len {
    match input.get_char(i) {
      Some(ch) =>
        if ch.is_ascii_whitespace() {
          i = i + ch.utf16_len()
        } else {
          break
        }
      None => break
    }
  }
  i
}

///|
fn lex_number(input : StringView, start : Int, len : Int) -> (Int, Int) {
  let mut i = start
  let mut value = 0
  while i < len {
    match input.get_char(i) {
      Some(ch) =>
        if ch.is_ascii_digit() {
          value = value * 10 + (ch.to_int() - '0'.to_int())
          i = i + ch.utf16_len()
        } else {
          break
        }
      None => break
    }
  }
  (value, i)
}

///|
fn lex_token(input : StringView, offset : Int, len : Int) -> CalcResult[Token] {
  let i = skip_ws_ascii(input, offset, len)
  if i >= len {
    Err(@nom.Err::Incomplete(@nom.Needed::Size(1)))
  } else {
    match input.get_char(i) {
      Some(ch) =>
        if ch.is_ascii_digit() {
          let (value, next) = lex_number(input, i, len)
          Ok((Number(value), next))
        } else {
          let next = i + ch.utf16_len()
          match ch {
            '+' => Ok((Plus, next))
            '-' => Ok((Minus, next))
            '*' => Ok((Star, next))
            '/' => Ok((Slash, next))
            '%' => Ok((Percent, next))
            '^' => Ok((Caret, next))
            '(' => Ok((LParen, next))
            ')' => Ok((RParen, next))
            _ => Err(err_at(input, i, @nom.ErrorKind::Char))
          }
        }
      None => Err(@nom.Err::Incomplete(@nom.Needed::Size(1)))
    }
  }
}

///|
fn pow_int(base : Int, exp : Int) -> Int {
  if exp <= 0 {
    if exp == 0 {
      1
    } else {
      0
    }
  } else {
    let mut acc = 1
    let mut i = 0
    while i < exp {
      acc = acc * base
      i = i + 1
    }
    acc
  }
}

///|
fn lex_infix(
  input : StringView,
  offset : Int,
  len : Int,
) -> Result[(Token, Int)?, @nom.Err[@nom.ParseError[StringView]]] {
  let i = skip_ws_ascii(input, offset, len)
  if i >= len {
    Ok(None)
  } else {
    match input.get_char(i) {
      Some(ch) => {
        let next = i + ch.utf16_len()
        match ch {
          '+' => Ok(Some((Plus, next)))
          '-' => Ok(Some((Minus, next)))
          '*' => Ok(Some((Star, next)))
          '/' => Ok(Some((Slash, next)))
          '%' => Ok(Some((Percent, next)))
          '^' => Ok(Some((Caret, next)))
          ')' => Ok(None)
          '(' => Ok(None)
          _ =>
            if ch.is_ascii_digit() {
              Ok(None)
            } else {
              Err(err_at(input, i, @nom.ErrorKind::Char))
            }
        }
      }
      None => Ok(None)
    }
  }
}

///|
fn apply_infix(op : Token, lhs : Int, rhs : Int) -> Int {
  match op {
    Plus => lhs + rhs
    Minus => lhs - rhs
    Star => lhs * rhs
    Slash => lhs / rhs
    Percent => lhs % rhs
    Caret => pow_int(lhs, rhs)
    _ => lhs
  }
}

///|
fn parse_prefix(input : StringView, offset : Int, len : Int) -> CalcResult[Int] {
  match lex_token(input, offset, len) {
    Ok((tok, next)) =>
      match tok {
        Number(value) => Ok((value, next))
        LParen =>
          match parse_expr_bp(input, next, len, 0) {
            Ok((value, after)) =>
              match lex_token(input, after, len) {
                Ok((RParen, next2)) => Ok((value, next2))
                Ok((_, _)) => Err(err_at(input, after, @nom.ErrorKind::Char))
                Err(err) => Err(err)
              }
            Err(err) => Err(err)
          }
        Plus =>
          match parse_expr_bp(input, next, len, 3) {
            Ok((value, next2)) => Ok((value, next2))
            Err(err) => Err(err)
          }
        Minus =>
          match parse_expr_bp(input, next, len, 3) {
            Ok((value, next2)) => Ok((-value, next2))
            Err(err) => Err(err)
          }
        _ => Err(err_at(input, offset, @nom.ErrorKind::Tag))
      }
    Err(err) => Err(err)
  }
}

///|
fn parse_expr_bp(
  input : StringView,
  offset : Int,
  len : Int,
  min_bp : Int,
) -> CalcResult[Int] {
  match parse_prefix(input, offset, len) {
    Ok((value, next)) => {
      let mut acc = value
      let mut i = next
      while true {
        match lex_infix(input, i, len) {
          Ok(Some((tok, next_tok))) => {
            let (l_bp, r_bp) = match tok {
              Plus => (1, 2)
              Minus => (1, 2)
              Star => (2, 3)
              Slash => (2, 3)
              Percent => (2, 3)
              Caret => (3, 3)
              _ => (0, 0)
            }
            if l_bp < min_bp {
              return Ok((acc, i))
            } else {
              match parse_expr_bp(input, next_tok, len, r_bp) {
                Ok((rhs, next_rhs)) => {
                  acc = apply_infix(tok, acc, rhs)
                  i = next_rhs
                }
                Err(err) => return Err(err)
              }
            }
          }
          Ok(None) => return Ok((acc, i))
          Err(err) => return Err(err)
        }
      }
      Ok((acc, i))
    }
    Err(err) => Err(err)
  }
}

///|
/// Public calculator parser
pub fn parse_calc(input : StringView) -> @nom.IResult[StringView, Int] {
  let len = input.length()
  match parse_expr_bp(input, 0, len, 0) {
    Ok((value, next)) => {
      let end = skip_ws_ascii(input, next, len)
      Ok((value, input.view(start_offset=end)))
    }
    Err(err) => Err(err)
  }
}
