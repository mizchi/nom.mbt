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
    let mut count = 0
    for ch in input {
      if pred(ch) {
        count += 1
      } else {
        break
      }
    }
    let end_offset =
      match input.offset_of_nth_char(count) {
        Some(offset) => offset
        None => input.length()
      }
    Ok((input.view(end_offset=end_offset), input.view(start_offset=end_offset)))
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
          let offset =
            match input.offset_of_nth_char(1) {
              Some(v) => v
              None => input.length()
            }
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

///| Match one of the given chars
pub fn one_of(chars : StringView) -> @nom.Parser[StringView, Char] {
  satisfy((ch) => chars.contains_char(ch))
}

///| Match none of the given chars
pub fn none_of(chars : StringView) -> @nom.Parser[StringView, Char] {
  satisfy((ch) => !chars.contains_char(ch))
}

///| Zero or more ASCII whitespace
pub fn space0(input : StringView) -> @nom.IResult[StringView, StringView] {
  take_while((ch) => ch.is_ascii_whitespace())(input)
}

///| One or more ASCII whitespace
pub fn space1(input : StringView) -> @nom.IResult[StringView, StringView] {
  take_while1((ch) => ch.is_ascii_whitespace())(input)
}

///| One or more ASCII digits
pub fn digit1(input : StringView) -> @nom.IResult[StringView, StringView] {
  take_while1((ch) => ch.is_ascii_digit())(input)
}
