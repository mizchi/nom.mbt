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

///| Take bytes until predicate holds (predicate byte is not consumed)
pub fn take_till(pred : (Byte) -> Bool) -> @nom.Parser[BytesView, BytesView] {
  take_while((b) => !pred(b))
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

///| Find the first index of a byte pattern
fn find_subslice(input : BytesView, needle : BytesView) -> Int? {
  let nlen = needle.length()
  if nlen == 0 {
    return None
  }
  let ilen = input.length()
  if ilen < nlen {
    return None
  }
  if nlen == 1 {
    match needle.get(0) {
      Some(target) => {
        let mut i = 0
        while i < ilen {
          match input.get(i) {
            Some(b) =>
              if b == target {
                return Some(i)
              } else {
                i = i + 1
              }
            None => break
          }
        }
        None
      }
      None => None
    }
  } else {
    find_subslice_bmh(input, needle)
  }
}

///| Find the first index using Boyer-Moore-Horspool
fn find_subslice_bmh(input : BytesView, needle : BytesView) -> Int? {
  let nlen = needle.length()
  let ilen = input.length()
  if nlen == 0 || ilen < nlen {
    return None
  }
  let table : Array[Int] = Array::make(256, nlen)
  let last_idx = nlen - 1
  let mut i = 0
  while i < last_idx {
    match needle.get(i) {
      Some(b) => table.set(b.to_int(), last_idx - i)
      None => ()
    }
    i = i + 1
  }
  let last = match needle.get(last_idx) {
    Some(b) => b
    None => return None
  }
  let mut pos = 0
  while pos + nlen <= ilen {
    let at = pos + last_idx
    match input.get(at) {
      Some(b) =>
        if b == last {
          let mut j = 0
          while j < last_idx {
            match (input.get(pos + j), needle.get(j)) {
              (Some(x), Some(y)) =>
                if x == y {
                  j = j + 1
                } else {
                  break
                }
              _ => break
            }
          }
          if j == last_idx {
            return Some(pos)
          }
          pos = pos + 1
        } else {
          pos = pos + table[b.to_int()]
        }
      None => break
    }
  }
  None
}

///| Take bytes until a pattern is found (pattern is not consumed)
pub fn take_until(needle : BytesView) -> @nom.Parser[BytesView, BytesView] {
  fn(input) {
    let nlen = needle.length()
    if nlen == 0 {
      Err(@nom.Err::Error(@nom.ParseError::new(input, @nom.ErrorKind::Take)))
    } else if input.length() < nlen {
      Err(@nom.Err::Incomplete(@nom.Needed::Size(nlen)))
    } else {
      match find_subslice(input, needle) {
        Some(idx) => Ok((input.sub(end=idx), input.sub(start=idx)))
        None => Err(@nom.Err::Incomplete(@nom.Needed::Unknown))
      }
    }
  }
}

///| Take bytes until a pattern is found (must take at least one)
pub fn take_until1(needle : BytesView) -> @nom.Parser[BytesView, BytesView] {
  fn(input) {
    match take_until(needle)(input) {
      Ok((matched, rest)) =>
        if matched.length() == 0 {
          Err(@nom.Err::Error(@nom.ParseError::new(input, @nom.ErrorKind::TakeUntil1)))
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

///| Match a specific byte
pub fn byte(expected : Byte) -> @nom.Parser[BytesView, Byte] {
  satisfy((b) => b == expected)
}

///| Build byte lookup table for fast membership checks
fn build_byte_table(bytes : BytesView) -> Array[Bool] {
  let table : Array[Bool] = Array::make(256, false)
  for b in bytes {
    table.set(b.to_int(), true)
  }
  table
}

///| Match one of the given bytes
pub fn one_of(bytes : BytesView) -> @nom.Parser[BytesView, Byte] {
  let table = build_byte_table(bytes)
  satisfy((b) => table[b.to_int()])
}

///| Match none of the given bytes
pub fn none_of(bytes : BytesView) -> @nom.Parser[BytesView, Byte] {
  let table = build_byte_table(bytes)
  satisfy((b) => !table[b.to_int()])
}

///| Take one or more bytes from the given set
pub fn is_a(bytes : BytesView) -> @nom.Parser[BytesView, BytesView] {
  let table = build_byte_table(bytes)
  take_while1((b) => table[b.to_int()])
}

///| Take one or more bytes not in the given set
pub fn is_not(bytes : BytesView) -> @nom.Parser[BytesView, BytesView] {
  let table = build_byte_table(bytes)
  take_while1((b) => !table[b.to_int()])
}

fn scan_ascii_space(input : BytesView) -> Int {
  let len = input.length()
  let mut i = 0
  while i < len {
    match input.get(i) {
      Some(b) =>
        if b is (b' ' | b'\t' | b'\n' | b'\r') {
          i = i + 1
        } else {
          break
        }
      None => break
    }
  }
  i
}

///| Zero or more ASCII whitespace bytes
pub fn space0(input : BytesView) -> @nom.IResult[BytesView, BytesView] {
  let consumed = scan_ascii_space(input)
  Ok((input.sub(end=consumed), input.sub(start=consumed)))
}

///| One or more ASCII whitespace bytes
pub fn space1(input : BytesView) -> @nom.IResult[BytesView, BytesView] {
  let consumed = scan_ascii_space(input)
  if consumed == 0 {
    if input.length() == 0 {
      Err(@nom.Err::Incomplete(@nom.Needed::Size(1)))
    } else {
      Err(@nom.Err::Error(@nom.ParseError::new(input, @nom.ErrorKind::TakeWhile1)))
    }
  } else {
    Ok((input.sub(end=consumed), input.sub(start=consumed)))
  }
}

///| One or more ASCII digits
pub fn digit1(input : BytesView) -> @nom.IResult[BytesView, BytesView] {
  take_while1((b) => b is (b'0'..=b'9'))(input)
}
