///| Streaming buffer for StringView parsers
pub struct Stream {
  buf : String
} derive(Show, Eq)

///| Create an empty stream buffer
pub fn Stream::new() -> Stream {
  { buf: "" }
}

///| Create a stream from an existing buffer
pub fn Stream::from_string(buf : String) -> Stream {
  { buf, }
}

///| View the current buffered input
pub fn Stream::view(self : Stream) -> StringView {
  self.buf[:]
}

///| Check whether the buffer is empty
pub fn Stream::is_empty(self : Stream) -> Bool {
  self.buf.is_empty()
}

///| Append a new chunk to the buffer
pub fn Stream::feed(self : Stream, chunk : StringView) -> Stream {
  if chunk.length() == 0 {
    self
  } else if self.buf.is_empty() {
    { buf: chunk.to_string() }
  } else {
    { buf: self.buf + chunk.to_string() }
  }
}

///| Run a parser on the buffer, advancing it on success
pub fn[O] Stream::parse(
  self : Stream,
  parser : @nom.Parser[StringView, O],
) -> (@nom.IResult[StringView, O], Stream) {
  let input = self.buf[:]
  match parser(input) {
    Ok((value, rest)) => {
      let remaining = rest.to_string()
      let rest_view = remaining[:]
      (Ok((value, rest_view)), { buf: remaining })
    }
    Err(err) => (Err(err), self)
  }
}
