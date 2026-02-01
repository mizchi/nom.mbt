///|
test "bytes tag incomplete" {
  let input = b"ab"[:]
  match tag(b"abc"[:])(input) {
    Err(@nom.Err::Incomplete(@nom.Needed::Size(3))) => assert_true(true)
    _ => fail("expected incomplete")
  }
}

///|
test "bytes take incomplete" {
  let input = b"ab"[:]
  match take(3)(input) {
    Err(@nom.Err::Incomplete(@nom.Needed::Size(3))) => assert_true(true)
    _ => fail("expected incomplete")
  }
}
