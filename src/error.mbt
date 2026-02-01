///| Error kinds similar to nom::error::ErrorKind
pub(all) enum ErrorKind {
  Tag
  Take
  TakeWhile
  TakeWhile1
  Char
  Digit
  Eof
  MapRes
  Alt
  Many0
  Custom(String)
} derive(Show, ToJson, Eq)

///| Streaming-needed hint (like nom::Needed)
pub(all) enum Needed {
  Unknown
  Size(Int)
} derive(Show, ToJson, Eq)

///| Parse error with input snapshot and optional context stack
pub struct ParseError[I] {
  input : I
  kind : ErrorKind
  context : Array[String]
} derive(Show, ToJson, Eq)

///| Error wrapper (recoverable vs failure)
pub(all) enum Err[E] {
  Error(E)
  Failure(E)
  Incomplete(Needed)
} derive(Show, ToJson, Eq)

///| Nom-style result type
pub type IResult[I, O] = Result[(O, I), Err[ParseError[I]]]

///| Parser function type
pub type Parser[I, O] = (I) -> IResult[I, O]

///| Input length trait for parsers that need to detect progress
pub trait InputLen {
  length(Self) -> Int
}

///|
pub impl InputLen for StringView with length(self) {
  self.length()
}

///|
pub impl InputLen for BytesView with length(self) {
  self.length()
}

///|
pub fn[I] ParseError::new(input : I, kind : ErrorKind) -> ParseError[I] {
  { input, kind, context: [] }
}

///|
pub fn[I] ParseError::with_context(
  self : ParseError[I],
  label : String,
) -> ParseError[I] {
  { input: self.input, kind: self.kind, context: self.context.add([label]) }
}

///|
pub fn[I] to_error(input : I, kind : ErrorKind) -> Err[ParseError[I]] {
  Err::Error(ParseError::new(input, kind))
}

///|
pub fn[I] to_failure(input : I, kind : ErrorKind) -> Err[ParseError[I]] {
  Err::Failure(ParseError::new(input, kind))
}

///|
pub fn[E] to_incomplete(needed : Needed) -> Err[E] {
  Err::Incomplete(needed)
}
