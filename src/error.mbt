///| Error kinds similar to nom::error::ErrorKind
pub(all) enum ErrorKind {
  Tag
  Take
  TakeWhile
  TakeWhile1
  TakeUntil1
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

fn error_kind_label(kind : ErrorKind) -> String {
  match kind {
    Tag => "Tag"
    Take => "Take"
    TakeWhile => "TakeWhile"
    TakeWhile1 => "TakeWhile1"
    TakeUntil1 => "TakeUntil1"
    Char => "Char"
    Digit => "Digit"
    Eof => "Eof"
    MapRes => "MapRes"
    Alt => "Alt"
    Many0 => "Many0"
    Custom(msg) => "Custom(" + msg + ")"
  }
}

fn join_context(ctx : Array[String]) -> String {
  let sb = StringBuilder::new()
  let mut first = true
  for label in ctx {
    if !(first) {
      sb.write_string(" > ")
    }
    first = false
    sb.write_string(label)
  }
  sb.to_string()
}

///| Byte offset of a parsing error for BytesView inputs
pub fn bytes_error_offset(
  original : BytesView,
  err : ParseError[BytesView],
) -> Int {
  let orig_len = original.length()
  let err_len = err.input.length()
  if orig_len >= err_len { orig_len - err_len } else { 0 }
}

///| Code-unit offset of a parsing error for StringView inputs
pub fn string_error_offset(
  original : StringView,
  err : ParseError[StringView],
) -> Int {
  let orig_len = original.length()
  let err_len = err.input.length()
  if orig_len >= err_len { orig_len - err_len } else { 0 }
}

///| Return (offset, line, column) for a StringView parsing error
pub fn string_error_location(
  original : StringView,
  err : ParseError[StringView],
) -> (Int, Int, Int) {
  let offset = string_error_offset(original, err)
  let mut line = 1
  let mut col = 1
  let mut consumed = 0
  for ch in original {
    if consumed >= offset {
      break
    }
    if ch == '\n' {
      line = line + 1
      col = 1
    } else {
      col = col + 1
    }
    consumed = consumed + ch.utf16_len()
  }
  (offset, line, col)
}

fn format_error_detail_string(
  original : StringView,
  err : ParseError[StringView],
  label : String,
) -> String {
  let (offset, line, col) = string_error_location(original, err)
  let sb = StringBuilder::new()
  sb
    ..write_string(label)
    ..write_string(" at ")
    ..write_string(line.to_string())
    ..write_string(":")
    ..write_string(col.to_string())
    ..write_string(" (offset ")
    ..write_string(offset.to_string())
    ..write_string("): ")
    ..write_string(error_kind_label(err.kind))
  if err.context.length() > 0 {
    sb
      ..write_string("\ncontext: ")
      ..write_string(join_context(err.context))
  }
  sb.to_string()
}

fn format_error_detail_bytes(
  original : BytesView,
  err : ParseError[BytesView],
  label : String,
) -> String {
  let offset = bytes_error_offset(original, err)
  let sb = StringBuilder::new()
  sb
    ..write_string(label)
    ..write_string(" at offset ")
    ..write_string(offset.to_string())
    ..write_string(": ")
    ..write_string(error_kind_label(err.kind))
  if err.context.length() > 0 {
    sb
      ..write_string("\ncontext: ")
      ..write_string(join_context(err.context))
  }
  sb.to_string()
}

///| Format a string parsing error with location and context
pub fn format_error_string(
  original : StringView,
  err : Err[ParseError[StringView]],
) -> String {
  match err {
    Err::Error(parse) => format_error_detail_string(original, parse, "error")
    Err::Failure(parse) => format_error_detail_string(original, parse, "failure")
    Err::Incomplete(Needed::Unknown) => "incomplete: needed more input"
    Err::Incomplete(Needed::Size(n)) =>
      "incomplete: needed ".to_string() + n.to_string()
  }
}

///| Format a bytes parsing error with offset and context
pub fn format_error_bytes(
  original : BytesView,
  err : Err[ParseError[BytesView]],
) -> String {
  match err {
    Err::Error(parse) => format_error_detail_bytes(original, parse, "error")
    Err::Failure(parse) => format_error_detail_bytes(original, parse, "failure")
    Err::Incomplete(Needed::Unknown) => "incomplete: needed more input"
    Err::Incomplete(Needed::Size(n)) =>
      "incomplete: needed ".to_string() + n.to_string()
  }
}

///|
pub fn[E] to_incomplete(needed : Needed) -> Err[E] {
  Err::Incomplete(needed)
}
