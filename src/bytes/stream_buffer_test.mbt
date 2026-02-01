///|
test "bytes stream buffer retry" {
  let parser = tag(b"abc"[:])
  let stream0 = Stream::new()
  let stream1 = stream0.feed(b"a"[:])
  let (res1, stream1b) = stream1.parse(parser)
  match res1 {
    Err(@nom.Err::Incomplete(@nom.Needed::Size(3))) => assert_true(true)
    _ => fail("expected incomplete")
  }
  let stream2 = stream1b.feed(b"bc"[:])
  let (res2, stream3) = stream2.parse(parser)
  match res2 {
    Ok((matched, rest)) => {
      assert_eq(matched, b"abc"[:])
      assert_true(rest.length() == 0)
      assert_true(stream3.is_empty())
    }
    Err(_) => fail("expected ok")
  }
}

///|
test "bytes stream buffer keeps remainder" {
  let parser = tag(b"ab"[:])
  let stream = Stream::new().feed(b"abXY"[:])
  let (res, next) = stream.parse(parser)
  match res {
    Ok((_, rest)) => {
      assert_eq(rest, b"XY"[:])
      assert_eq(next.view(), b"XY"[:])
    }
    Err(_) => fail("expected ok")
  }
}
