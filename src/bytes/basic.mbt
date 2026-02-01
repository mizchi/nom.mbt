///| Match an exact byte sequence
pub fn tag(expected : BytesView) -> @nom.Parser[BytesView, BytesView] {
  fn(input) {
    let len = expected.length()
    if input.length() < len {
      Err(@nom.Err::Incomplete(@nom.Needed::Size(len)))
    } else {
      let matched = input.sub(end=len)
      if matched == expected {
        Ok((matched, input.sub(start=len)))
      } else {
        Err(@nom.Err::Error(@nom.ParseError::new(input, @nom.ErrorKind::Tag)))
      }
    }
  }
}

///| Take a fixed number of bytes
pub fn take(count : Int) -> @nom.Parser[BytesView, BytesView] {
  fn(input) {
    if count < 0 || input.length() < count {
      if count < 0 {
        Err(@nom.Err::Error(@nom.ParseError::new(input, @nom.ErrorKind::Take)))
      } else {
        Err(@nom.Err::Incomplete(@nom.Needed::Size(count)))
      }
    } else {
      Ok((input.sub(end=count), input.sub(start=count)))
    }
  }
}

///| Take bytes while predicate holds
pub fn take_while(pred : (Byte) -> Bool) -> @nom.Parser[BytesView, BytesView] {
  fn(input) {
    let mut rest = input
    while rest is [b, .. tail] {
      if pred(b) {
        rest = tail
      } else {
        break
      }
    }
    let consumed = input.length() - rest.length()
    Ok((input.sub(end=consumed), rest))
  }
}

///| Take bytes while predicate holds (must take at least one)
pub fn take_while1(pred : (Byte) -> Bool) -> @nom.Parser[BytesView, BytesView] {
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

///| Satisfy a predicate on the next byte
pub fn satisfy(pred : (Byte) -> Bool) -> @nom.Parser[BytesView, Byte] {
  fn(input) {
    match input.get(0) {
      Some(b) =>
        if pred(b) {
          Ok((b, input.sub(start=1)))
        } else {
          Err(@nom.Err::Error(@nom.ParseError::new(input, @nom.ErrorKind::Char)))
        }
      None => Err(@nom.Err::Incomplete(@nom.Needed::Size(1)))
    }
  }
}

///| Check if a BytesView contains a byte
fn contains(bytes : BytesView, target : Byte) -> Bool {
  for b in bytes {
    if b == target {
      return true
    }
  }
  false
}

///| Match one of the given bytes
pub fn one_of(bytes : BytesView) -> @nom.Parser[BytesView, Byte] {
  satisfy((b) => contains(bytes, b))
}

///| Match none of the given bytes
pub fn none_of(bytes : BytesView) -> @nom.Parser[BytesView, Byte] {
  satisfy((b) => !contains(bytes, b))
}

///| Zero or more ASCII whitespace bytes
pub fn space0(input : BytesView) -> @nom.IResult[BytesView, BytesView] {
  take_while((b) => b is (b' ' | b'\t' | b'\n' | b'\r'))(input)
}

///| One or more ASCII whitespace bytes
pub fn space1(input : BytesView) -> @nom.IResult[BytesView, BytesView] {
  take_while1((b) => b is (b' ' | b'\t' | b'\n' | b'\r'))(input)
}

///| One or more ASCII digits
pub fn digit1(input : BytesView) -> @nom.IResult[BytesView, BytesView] {
  take_while1((b) => b is (b'0'..=b'9'))(input)
}
