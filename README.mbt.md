# nom for MoonBit

Nom-like parser combinators for MoonBit. The core types mirror nom's
`IResult`/`Parser` style but keep MoonBit syntax and `StringView`/`BytesView`
inputs.

- `IResult[I, O] = Result[(O, I), Err[ParseError[I]]]`
- `Parser[I, O] = (I) -> IResult[I, O]`

## Quick example (string)

```mbt check
///| Example: parse an integer with optional whitespace

fn parse_int_ws(input : StringView) -> @nom.IResult[StringView, Int] {
  let parser = @nom.delimited(
    @nom/str.space0,
    @nom/str.int,
    @nom/str.space0,
  )
  parser(input)
}

///|
test "parse int with ws" {
  let input = " 123 "[:]
  match parse_int_ws(input) {
    Ok((value, rest)) => {
      assert_eq(value, 123)
      assert_true(rest.is_empty())
    }
    Err(_) => fail("parse failed")
  }
}
```

## Packages

- `@nom` - core combinators and error types
- `@nom/str` - string parsers (`StringView`)
- `@nom/bytes` - bytes parsers (`BytesView`)

Streaming is partially supported: parsers may return `Err::Incomplete(Needed::Size(_))`
when the input is too short. Use `@nom/str.Stream` or `@nom/bytes.Stream`
to buffer chunks and retry the parser, or use `@nom.complete(parser)` to treat
`Incomplete` as a normal error for non-streaming parsing.

```mbt check
///| Example: streaming string buffer
let parser = @nom/str.tag("abc"[:])
let stream0 = @nom/str.Stream::new()
let stream1 = stream0.feed("a"[:])
let (res1, stream1b) = stream1.parse(parser)
// res1 is Err::Incomplete(_)
let stream2 = stream1b.feed("bc"[:])
let (res2, stream3) = stream2.parse(parser)
// res2 is Ok(("abc", "")) and stream3 is now empty
```

## Benchmark vs Rust nom (local)

Numbers below are local microbenchmarks run on 2026-02-02.
They are sensitive to machine and compiler versions, so treat them as rough
guidance, not absolute truth.

- MoonBit: `moon bench --target native`
- Rust: `cargo bench --bench calculator` and `cargo bench --bench assignments_unicode`

| case | MoonBit (µs) | Rust/nom (µs) | ratio |
| --- | ---: | ---: | ---: |
| calc short | 0.66 | 0.259 | 2.55x |
| calc long | 3.82 | 1.718 | 2.22x |
| calc complex short | 1.59 | 0.815 | 1.95x |
| calc complex long | 4.07 | 2.145 | 1.90x |
| assignments unicode short | 0.90 | 0.591 | 1.52x |
| assignments unicode long | 3.71 | 2.617 | 1.42x |

Short, ASCII-heavy inputs tend to amplify constant overhead. As expressions
get longer or more Unicode-heavy, the gap shrinks.
