///|
test "string tag incomplete" {
  let input = "ab"[:]
  match tag("abc"[:])(input) {
    Err(@nom.Err::Incomplete(@nom.Needed::Size(3))) => assert_true(true)
    _ => fail("expected incomplete")
  }
}

///|
test "string take incomplete" {
  let input = "ab"[:]
  match take(3)(input) {
    Err(@nom.Err::Incomplete(@nom.Needed::Size(3))) => assert_true(true)
    _ => fail("expected incomplete")
  }
}
