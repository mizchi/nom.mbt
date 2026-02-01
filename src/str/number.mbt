///| Parse a signed integer (ASCII)
pub fn int(input : StringView) -> @nom.IResult[StringView, Int] {
  let parser = @nom.map_res(
    @nom.pair(@nom.opt(one_of("+-"[:] )), digit1),
    (pair) => {
      let sign = pair.0
      let digits = pair.1
      let parsed : Result[Int, @strconv.StrConvError] =
        try? @strconv.parse_int(digits)
      match parsed {
        Ok(value) =>
          if sign is Some('-') {
            Ok(-value)
          } else {
            Ok(value)
          }
        Err(_) => Err(())
      }
    },
    @nom.ErrorKind::MapRes,
  )
  parser(input)
}
