///|
test "bytes byte and is_a" {
  let input = b"abc123"[:]
  match byte(b'a')(input) {
    Ok((value, rest)) => {
      assert_eq(value, b'a')
      assert_eq(rest, b"bc123"[:])
    }
    Err(_) => fail("byte failed")
  }
  match is_a(b"abc"[:])(input) {
    Ok((matched, rest)) => {
      assert_eq(matched, b"abc"[:])
      assert_eq(rest, b"123"[:])
    }
    Err(_) => fail("is_a failed")
  }
}

///|
test "bytes is_not and take_till" {
  let input = b"xyz=123"[:]
  match is_not(b"abc="[:])(input) {
    Ok((matched, rest)) => {
      assert_eq(matched, b"xyz"[:])
      assert_eq(rest, b"=123"[:])
    }
    Err(_) => fail("is_not failed")
  }
  match take_till((b) => b == b'=')(input) {
    Ok((matched, rest)) => {
      assert_eq(matched, b"xyz"[:])
      assert_eq(rest, b"=123"[:])
    }
    Err(_) => fail("take_till failed")
  }
}

///|
test "bytes take_until" {
  let input = b"abc??def"[:]
  match take_until(b"??"[:])(input) {
    Ok((matched, rest)) => {
      assert_eq(matched, b"abc"[:])
      assert_eq(rest, b"??def"[:])
    }
    Err(_) => fail("take_until failed")
  }
  match take_until(b"?"[:])(input) {
    Ok((matched, rest)) => {
      assert_eq(matched, b"abc"[:])
      assert_eq(rest, b"??def"[:])
    }
    Err(_) => fail("take_until single failed")
  }
  match take_until(b"ZZ"[:])(input) {
    Err(@nom.Err::Incomplete(@nom.Needed::Unknown)) => ()
    _ => fail("expected incomplete")
  }
}

///|
test "bytes take_until1 empty" {
  let input = b"??"[:]
  match take_until1(b"??"[:])(input) {
    Err(@nom.Err::Error(err)) => assert_eq(err.kind, @nom.ErrorKind::TakeUntil1)
    _ => fail("expected take_until1 error")
  }
}
