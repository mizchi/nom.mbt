///| Benchmarks for bytes parsers

let request : Bytes = b"GET /12345?x=67890 HTTP/1.1\n"
let bytes_short : BytesView = request[:]
let bytes_long : BytesView = request.repeat(100)[:]

let tag_get : BytesView = b"GET /"[:]
let tag_q : BytesView = b"?x="[:]
let tag_suffix : BytesView = b" HTTP/1.1\n"[:]

fn bytes_to_int(bytes : BytesView) -> Int {
  let mut val = 0
  let zero = b'0'.to_int()
  for b in bytes {
    val = val * 10 + (b.to_int() - zero)
  }
  val
}

fn parse_number(input : BytesView) -> @nom.IResult[BytesView, Int] {
  @nom.map(digit1, bytes_to_int)(input)
}

fn request_sum(input : BytesView) -> @nom.IResult[BytesView, Int] {
  let parser = @nom.delimited(
    tag(tag_get),
    @nom.pair(parse_number, @nom.preceded(tag(tag_q), parse_number)),
    tag(tag_suffix),
  )
  @nom.map(parser, (pair) => pair.0 + pair.1)(input)
}

fn parse_requests_nom(input : BytesView) -> @nom.IResult[BytesView, Int] {
  @nom.map(@nom.many1(request_sum), (values) => {
    let mut sum = 0
    for v in values {
      sum = sum + v
    }
    sum
  })(input)
}

fn match_tag(input : BytesView, idx : Int, len : Int, pat : BytesView) -> Int? {
  let pat_len = pat.length()
  if idx + pat_len > len {
    return None
  }
  let mut i = 0
  while i < pat_len {
    match input.get(idx + i) {
      Some(b) =>
        if b == pat[i] {
          i = i + 1
        } else {
          return None
        }
      None => return None
    }
  }
  Some(idx + pat_len)
}

fn parse_digits(input : BytesView, idx : Int, len : Int) -> (Int, Int)? {
  if idx >= len {
    return None
  }
  let mut i = idx
  let mut val = 0
  let zero = b'0'.to_int()
  let mut has_digit = false
  while i < len {
    match input.get(i) {
      Some(b) =>
        if b >= b'0' && b <= b'9' {
          val = val * 10 + (b.to_int() - zero)
          i = i + 1
          has_digit = true
        } else {
          break
        }
      None => break
    }
  }
  if has_digit { Some((val, i)) } else { None }
}

fn parse_request_hand(input : BytesView, idx : Int, len : Int) -> (Int, Int)? {
  match match_tag(input, idx, len, tag_get) {
    Some(i1) =>
      match parse_digits(input, i1, len) {
        Some((a, i2)) =>
          match match_tag(input, i2, len, tag_q) {
            Some(i3) =>
              match parse_digits(input, i3, len) {
                Some((b, i4)) =>
                  match match_tag(input, i4, len, tag_suffix) {
                    Some(i5) => Some((a + b, i5))
                    None => None
                  }
                None => None
              }
            None => None
          }
        None => None
      }
    None => None
  }
}

fn parse_requests_hand(input : BytesView) -> Int? {
  let len = input.length()
  let mut i = 0
  let mut sum = 0
  while i < len {
    match parse_request_hand(input, i, len) {
      Some((value, next)) => {
        sum = sum + value
        i = next
      }
      None => return None
    }
  }
  Some(sum)
}

///|
test "bench: bytes nom short" (b : @bench.T) {
  let parser = @nom.all_consuming(parse_requests_nom)
  b.bench(fn() { b.keep(parser(bytes_short)) })
}

///|
test "bench: bytes nom long" (b : @bench.T) {
  let parser = @nom.all_consuming(parse_requests_nom)
  b.bench(fn() { b.keep(parser(bytes_long)) })
}

///|
test "bench: bytes hand short" (b : @bench.T) {
  b.bench(fn() { b.keep(parse_requests_hand(bytes_short)) })
}

///|
test "bench: bytes hand long" (b : @bench.T) {
  b.bench(fn() { b.keep(parse_requests_hand(bytes_long)) })
}
