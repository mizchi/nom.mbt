use criterion::{black_box, criterion_group, criterion_main, Criterion};
use nom::{
  IResult, Parser,
  character::complete::{char, satisfy},
  combinator::{all_consuming, map_res, recognize},
  multi::{fold_many0, many0, many1},
  sequence::{delimited, preceded},
};

const EQ: char = '\u{FF1D}';
const SEP: char = '\u{FF1B}';
const IDEO: char = '\u{3000}';
const EM: char = '\u{2003}';
const IDENT_BASE: &str = "\u{53D8}\u{91CF}";

fn unicode_space0(input: &str) -> IResult<&str, &str> {
  recognize(many0(satisfy(|ch| ch.is_whitespace())))(input)
}

fn ws<'a, F, O>(inner: F) -> impl FnMut(&'a str) -> IResult<&'a str, O>
where
  F: Parser<&'a str, O, nom::error::Error<&'a str>>,
{
  delimited(unicode_space0, inner, unicode_space0)
}

fn is_fullwidth_digit(ch: char) -> bool {
  ('\u{FF10}'..='\u{FF19}').contains(&ch)
}

fn fullwidth_digit1(input: &str) -> IResult<&str, &str> {
  recognize(many1(satisfy(is_fullwidth_digit)))(input)
}

fn parse_fullwidth_digits(s: &str) -> Result<i64, ()> {
  let mut acc: i64 = 0;
  for ch in s.chars() {
    if !is_fullwidth_digit(ch) {
      return Err(());
    }
    acc = acc * 10 + (ch as i64 - 0xFF10);
  }
  Ok(acc)
}

fn number_fullwidth(input: &str) -> IResult<&str, i64> {
  map_res(fullwidth_digit1, parse_fullwidth_digits)(input)
}

fn is_ident_char_unicode(ch: char) -> bool {
  !ch.is_ascii() && !ch.is_whitespace() && ch != EQ && ch != SEP
}

fn ident_unicode(input: &str) -> IResult<&str, &str> {
  recognize(many1(satisfy(is_ident_char_unicode)))(input)
}

fn assignment_unicode(input: &str) -> IResult<&str, i64> {
  preceded(ws(ident_unicode), preceded(ws(char(EQ)), number_fullwidth))(input)
}

fn assignments_unicode(input: &str) -> IResult<&str, i64> {
  let (input, init) = assignment_unicode(input)?;
  fold_many0(
    preceded(ws(char(SEP)), assignment_unicode),
    move || init,
    |acc, item| acc + item,
  )(input)
}

fn parse_all(input: &str) -> IResult<&str, i64> {
  all_consuming(assignments_unicode)(input)
}

fn fullwidth_number(n: u32) -> String {
  let s = n.to_string();
  let mut out = String::with_capacity(s.len());
  for ch in s.chars() {
    let d = ch as u32 - '0' as u32;
    out.push(char::from_u32(0xFF10 + d).unwrap());
  }
  out
}

fn ident(n: u32) -> String {
  let mut out = String::with_capacity(IDENT_BASE.len() + 4);
  out.push_str(IDENT_BASE);
  out.push_str(&fullwidth_number(n));
  out
}

fn make_assignments(pairs: &[(u32, u32)]) -> String {
  let mut out = String::new();
  for (idx, (key, value)) in pairs.iter().enumerate() {
    if idx > 0 {
      out.push(SEP);
      out.push(IDEO);
    }
    out.push_str(&ident(*key));
    out.push(IDEO);
    out.push(EQ);
    out.push(EM);
    out.push_str(&fullwidth_number(*value));
  }
  out
}

fn make_assignments_short() -> String {
  let pairs: [(u32, u32); 5] = [
    (1, 123),
    (2, 456),
    (3, 789),
    (4, 234),
    (5, 567),
  ];
  make_assignments(&pairs)
}

fn make_assignments_long() -> String {
  let pairs: [(u32, u32); 20] = [
    (1, 12),
    (2, 34),
    (3, 56),
    (4, 78),
    (5, 90),
    (6, 123),
    (7, 234),
    (8, 345),
    (9, 456),
    (10, 567),
    (11, 678),
    (12, 789),
    (13, 890),
    (14, 901),
    (15, 2345),
    (16, 3456),
    (17, 4567),
    (18, 5678),
    (19, 6789),
    (20, 7890),
  ];
  make_assignments(&pairs)
}

fn bench_assignments_unicode_short(c: &mut Criterion) {
  let input = make_assignments_short();
  c.bench_function("nom assignments unicode short", |b| {
    b.iter(|| {
      let res = parse_all(black_box(&input));
      black_box(res).unwrap();
    })
  });
}

fn bench_assignments_unicode_long(c: &mut Criterion) {
  let input = make_assignments_long();
  c.bench_function("nom assignments unicode long", |b| {
    b.iter(|| {
      let res = parse_all(black_box(&input));
      black_box(res).unwrap();
    })
  });
}

criterion_group!(benches, bench_assignments_unicode_short, bench_assignments_unicode_long);
criterion_main!(benches);
