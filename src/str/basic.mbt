///| Match an exact string prefix
pub fn tag(expected : StringView) -> @nom.Parser[StringView, StringView] {
  fn(input) {
    if input.length() < expected.length() {
      Err(@nom.Err::Incomplete(@nom.Needed::Size(expected.length())))
    } else if input.has_prefix(expected) {
      let len = expected.length()
      Ok((input.view(end_offset=len), input.view(start_offset=len)))
    } else {
      Err(@nom.Err::Error(@nom.ParseError::new(input, @nom.ErrorKind::Tag)))
    }
  }
}

///| Take a fixed number of code units
pub fn take(count : Int) -> @nom.Parser[StringView, StringView] {
  fn(input) {
    if count < 0 || input.length() < count {
      if count < 0 {
        Err(@nom.Err::Error(@nom.ParseError::new(input, @nom.ErrorKind::Take)))
      } else {
        Err(@nom.Err::Incomplete(@nom.Needed::Size(count)))
      }
    } else {
      Ok((input.view(end_offset=count), input.view(start_offset=count)))
    }
  }
}

///| Take while predicate holds on chars
pub fn take_while(pred : (Char) -> Bool) -> @nom.Parser[StringView, StringView] {
  fn(input) {
    let mut consumed = 0
    for ch in input {
      if pred(ch) {
        consumed += ch.utf16_len()
      } else {
        break
      }
    }
    Ok((input.view(end_offset=consumed), input.view(start_offset=consumed)))
  }
}

///| Take while ASCII predicate holds (fast path)
fn take_while_ascii(pred : (Char) -> Bool) -> @nom.Parser[StringView, StringView] {
  fn(input) {
    let s = input.data()
    let start = input.start_offset()
    let end = start + input.length()
    let mut index = start
    while index < end {
      let cu = s.unsafe_get(index)
      if cu <= 0x7f {
        let ch = cu.unsafe_to_char()
        if pred(ch) {
          index += 1
          continue
        }
      }
      break
    }
    let consumed = index - start
    Ok((input.view(end_offset=consumed), input.view(start_offset=consumed)))
  }
}

///| Take while ASCII predicate holds (must take at least one)
fn take_while1_ascii(pred : (Char) -> Bool) -> @nom.Parser[StringView, StringView] {
  fn(input) {
    match take_while_ascii(pred)(input) {
      Ok((matched, rest)) =>
        if matched.length() == 0 {
          if input.length() == 0 {
            Err(@nom.Err::Incomplete(@nom.Needed::Size(1)))
          } else {
            Err(@nom.Err::Error(@nom.ParseError::new(input, @nom.ErrorKind::TakeWhile1)))
          }
        } else {
          Ok((matched, rest))
        }
      Err(err) => Err(err)
    }
  }
}

///| Build ASCII lookup table for fast membership checks
fn build_ascii_table(chars : StringView) -> (Bool, Array[Bool]) {
  let table : Array[Bool] = Array::make(128, false)
  for ch in chars {
    if ch.is_ascii() {
      table.set(ch.to_int(), true)
    } else {
      return (false, table)
    }
  }
  (true, table)
}

///| Fast-path parser for ASCII one_of
fn one_of_ascii_table(table : Array[Bool]) -> @nom.Parser[StringView, Char] {
  fn(input) {
    if input.length() == 0 {
      Err(@nom.Err::Incomplete(@nom.Needed::Size(1)))
    } else {
      let s = input.data()
      let idx = input.start_offset()
      let cu = s.unsafe_get(idx)
      if cu <= 0x7f {
        let ch = cu.unsafe_to_char()
        if table[ch.to_int()] {
          Ok((ch, input.view(start_offset=1)))
        } else {
          Err(@nom.Err::Error(@nom.ParseError::new(input, @nom.ErrorKind::Char)))
        }
      } else {
        Err(@nom.Err::Error(@nom.ParseError::new(input, @nom.ErrorKind::Char)))
      }
    }
  }
}

///| Take while predicate holds (must take at least one)
pub fn take_while1(pred : (Char) -> Bool) -> @nom.Parser[StringView, StringView] {
  fn(input) {
    match take_while(pred)(input) {
      Ok((matched, rest)) =>
        if matched.length() == 0 {
          if input.length() == 0 {
            Err(@nom.Err::Incomplete(@nom.Needed::Size(1)))
          } else {
            Err(@nom.Err::Error(@nom.ParseError::new(input, @nom.ErrorKind::TakeWhile1)))
          }
        } else {
          Ok((matched, rest))
        }
      Err(err) => Err(err)
    }
  }
}

///| Satisfy a predicate on the next char
pub fn satisfy(pred : (Char) -> Bool) -> @nom.Parser[StringView, Char] {
  fn(input) {
    match input.get_char(0) {
      Some(ch) =>
        if pred(ch) {
          let offset = ch.utf16_len()
          Ok((ch, input.view(start_offset=offset)))
        } else {
          Err(@nom.Err::Error(@nom.ParseError::new(input, @nom.ErrorKind::Char)))
        }
      None => Err(@nom.Err::Incomplete(@nom.Needed::Size(1)))
    }
  }
}

///| Match a specific char
pub fn char(expected : Char) -> @nom.Parser[StringView, Char] {
  satisfy((ch) => ch == expected)
}

///| Match one of two chars (fast path)
fn one_of2(a : Char, b : Char) -> @nom.Parser[StringView, Char] {
  fn(input) {
    match input.get_char(0) {
      Some(ch) =>
        if ch == a || ch == b {
          let offset = ch.utf16_len()
          Ok((ch, input.view(start_offset=offset)))
        } else {
          Err(@nom.Err::Error(@nom.ParseError::new(input, @nom.ErrorKind::Char)))
        }
      None => Err(@nom.Err::Incomplete(@nom.Needed::Size(1)))
    }
  }
}

///| Match one of the given chars
pub fn one_of(chars : StringView) -> @nom.Parser[StringView, Char] {
  let (ascii_only, table) = build_ascii_table(chars)
  if ascii_only {
    one_of_ascii_table(table)
  } else {
    satisfy((ch) => chars.contains_char(ch))
  }
}

///| Match none of the given chars
pub fn none_of(chars : StringView) -> @nom.Parser[StringView, Char] {
  satisfy((ch) => !chars.contains_char(ch))
}

///| Zero or more ASCII whitespace
pub fn space0(input : StringView) -> @nom.IResult[StringView, StringView] {
  take_while_ascii((ch) => ch.is_ascii_whitespace())(input)
}

///| One or more ASCII whitespace
pub fn space1(input : StringView) -> @nom.IResult[StringView, StringView] {
  take_while1_ascii((ch) => ch.is_ascii_whitespace())(input)
}

///| One or more ASCII digits
pub fn digit1(input : StringView) -> @nom.IResult[StringView, StringView] {
  take_while1_ascii((ch) => ch.is_ascii_digit())(input)
}
