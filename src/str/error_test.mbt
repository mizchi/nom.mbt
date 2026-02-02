///|
test "string error location" {
  let input = "abx\nc"[:]
  let parser = @nom.pair(tag("ab"[:]), tag("c"[:]))
  match parser(input) {
    Err(@nom.Err::Error(err)) => {
      assert_eq(@nom.string_error_offset(input, err), 2)
      let (offset, line, col) = @nom.string_error_location(input, err)
      assert_eq(offset, 2)
      assert_eq(line, 1)
      assert_eq(col, 3)
      let msg = @nom.format_error_string(input, @nom.Err::Error(err))
      assert_eq(msg, "error at 1:3 (offset 2): Tag")
    }
    _ => fail("expected error")
  }
}
