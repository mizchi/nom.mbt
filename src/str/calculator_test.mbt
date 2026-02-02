///|
test "calculator basic" {
  let input = "1 + 2 * 3"[:]
  match @nom.all_consuming(parse_calc)(input) {
    Ok((value, rest)) => {
      assert_eq(value, 7)
      assert_true(rest.is_empty())
    }
    Err(_) => fail("parse failed")
  }
}

///|
test "calculator parens" {
  let input = "(1 + 2) * 3"[:]
  match @nom.all_consuming(parse_calc)(input) {
    Ok((value, rest)) => {
      assert_eq(value, 9)
      assert_true(rest.is_empty())
    }
    Err(_) => fail("parse failed")
  }
}

///|
test "calculator unary" {
  let input = "-2 + 5"[:]
  match @nom.all_consuming(parse_calc)(input) {
    Ok((value, rest)) => {
      assert_eq(value, 3)
      assert_true(rest.is_empty())
    }
    Err(_) => fail("parse failed")
  }
}

///|
test "calculator unary parens" {
  let input = "-(1 + 2) * 3"[:]
  match @nom.all_consuming(parse_calc)(input) {
    Ok((value, rest)) => {
      assert_eq(value, -9)
      assert_true(rest.is_empty())
    }
    Err(_) => fail("parse failed")
  }
}

///|
test "calculator modulo" {
  let input = "2 * 3 % 4 + 5"[:]
  match @nom.all_consuming(parse_calc)(input) {
    Ok((value, rest)) => {
      assert_eq(value, 7)
      assert_true(rest.is_empty())
    }
    Err(_) => fail("parse failed")
  }
}

///|
test "calculator power" {
  let input = "2 ^ 3 ^ 2"[:]
  match @nom.all_consuming(parse_calc)(input) {
    Ok((value, rest)) => {
      assert_eq(value, 512)
      assert_true(rest.is_empty())
    }
    Err(_) => fail("parse failed")
  }
}
