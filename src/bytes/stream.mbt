///| Streaming buffer for BytesView parsers
pub struct Stream {
  buf : Bytes
} derive(Show, Eq)

///| Create an empty stream buffer
pub fn Stream::new() -> Stream {
  { buf: Bytes::default() }
}

///| Create a stream from an existing buffer
pub fn Stream::from_bytes(buf : Bytes) -> Stream {
  { buf, }
}

///| View the current buffered input
pub fn Stream::view(self : Stream) -> BytesView {
  self.buf[:]
}

///| Check whether the buffer is empty
pub fn Stream::is_empty(self : Stream) -> Bool {
  self.buf.length() == 0
}

///| Append a new chunk to the buffer
pub fn Stream::feed(self : Stream, chunk : BytesView) -> Stream {
  if chunk.length() == 0 {
    self
  } else if self.buf.length() == 0 {
    { buf: chunk.to_bytes() }
  } else {
    { buf: self.buf + chunk.to_bytes() }
  }
}

///| Run a parser on the buffer, advancing it on success
pub fn[O] Stream::parse(
  self : Stream,
  parser : @nom.Parser[BytesView, O],
) -> (@nom.IResult[BytesView, O], Stream) {
  let input = self.buf[:]
  match parser(input) {
    Ok((value, rest)) => {
      let remaining = rest.to_bytes()
      let rest_view = remaining[:]
      (Ok((value, rest_view)), { buf: remaining })
    }
    Err(err) => (Err(err), self)
  }
}
