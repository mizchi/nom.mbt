///|
test "string stream buffer retry" {
  let parser = tag("abc"[:])
  let stream0 = Stream::new()
  let stream1 = stream0.feed("a"[:])
  let (res1, stream1b) = stream1.parse(parser)
  match res1 {
    Err(@nom.Err::Incomplete(@nom.Needed::Size(3))) => assert_true(true)
    _ => fail("expected incomplete")
  }
  let stream2 = stream1b.feed("bc"[:])
  let (res2, stream3) = stream2.parse(parser)
  match res2 {
    Ok((matched, rest)) => {
      assert_eq(matched, "abc"[:])
      assert_true(rest.is_empty())
      assert_true(stream3.is_empty())
    }
    Err(_) => fail("expected ok")
  }
}

///|
test "string stream buffer keeps remainder" {
  let parser = tag("ab"[:])
  let stream = Stream::new().feed("abXY"[:])
  let (res, next) = stream.parse(parser)
  match res {
    Ok((_, rest)) => {
      assert_eq(rest, "XY"[:])
      assert_eq(next.view(), "XY"[:])
    }
    Err(_) => fail("expected ok")
  }
}
