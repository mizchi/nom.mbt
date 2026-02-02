use criterion::{black_box, criterion_group, criterion_main, Criterion};
use nom::{
  IResult, Parser,
  branch::alt,
  character::complete::{char, digit1, one_of, space0},
  combinator::{all_consuming, map_res, opt, recognize},
  multi::fold_many0,
  sequence::{delimited, pair},
};

const EXPR_SHORT: &str = "1 + 2 * 3 - 4 / 5 + 6 * (7 + 8) - 9";

const EXPR_LONG: &str =
  "1 + 2 * 3 - 4 / 5 + 6 * (7 + 8) - 9 + 10 * 11 - 12 / 13 + 14 * (15 + 16) - 17 + 18 * 19 - 20 / 21 + 22 * (23 + 24) - 25 + 26 * 27 - 28 / 29 + 30 * (31 + 32) - 33 + 34 * 35 - 36 / 37 + 38 * (39 + 40) - 41 + 42 * 43 - 44 / 45 + 46 * (47 + 48) - 49 + 50";

const EXPR_COMPLEX_SHORT: &str =
  "((1 + 2) * (3 + 4) - (5 * (6 + 7) - 8) + 9) * (10 + (11 - 12) * (13 + 14 / (15 + 16))) - 17";

const EXPR_COMPLEX_LONG: &str =
  "((1 + 2) * (3 + 4) - (5 * (6 + 7) - 8) + 9) * (10 + (11 - 12) * (13 + 14 / (15 + 16))) - 17 + (18 * (19 + 20) - (21 + 22) * (23 - 24 / (25 + 26))) + ((27 + 28) * (29 - 30) + (31 * (32 + 33 - 34))) - (35 + (36 * (37 + 38)) + (39 - 40 / (41 + 42)))";

fn ws<'a, F, O>(inner: F) -> impl FnMut(&'a str) -> IResult<&'a str, O>
where
  F: Parser<&'a str, O, nom::error::Error<&'a str>>,
{
  delimited(space0, inner, space0)
}

fn number(input: &str) -> IResult<&str, i64> {
  map_res(recognize(pair(opt(one_of("+-")), digit1)), |s: &str| {
    s.parse::<i64>()
  })(input)
}

fn parens(input: &str) -> IResult<&str, i64> {
  delimited(ws(char('(')), expr, ws(char(')')))(input)
}

fn factor(input: &str) -> IResult<&str, i64> {
  alt((ws(number), parens))(input)
}

fn term(input: &str) -> IResult<&str, i64> {
  let (input, init) = factor(input)?;
  fold_many0(
    pair(ws(one_of("*/")), factor),
    move || init,
    |acc, (op, val)| if op == '*' { acc * val } else { acc / val },
  )(input)
}

fn expr(input: &str) -> IResult<&str, i64> {
  let (input, init) = term(input)?;
  fold_many0(
    pair(ws(one_of("+-")), term),
    move || init,
    |acc, (op, val)| if op == '+' { acc + val } else { acc - val },
  )(input)
}

fn parse_all(input: &str) -> IResult<&str, i64> {
  all_consuming(expr)(input)
}

fn bench_calc_short(c: &mut Criterion) {
  c.bench_function("nom calc short", |b| {
    b.iter(|| {
      let res = parse_all(black_box(EXPR_SHORT));
      black_box(res).unwrap();
    })
  });
}

fn bench_calc_long(c: &mut Criterion) {
  c.bench_function("nom calc long", |b| {
    b.iter(|| {
      let res = parse_all(black_box(EXPR_LONG));
      black_box(res).unwrap();
    })
  });
}

fn bench_calc_complex_short(c: &mut Criterion) {
  c.bench_function("nom calc complex short", |b| {
    b.iter(|| {
      let res = parse_all(black_box(EXPR_COMPLEX_SHORT));
      black_box(res).unwrap();
    })
  });
}

fn bench_calc_complex_long(c: &mut Criterion) {
  c.bench_function("nom calc complex long", |b| {
    b.iter(|| {
      let res = parse_all(black_box(EXPR_COMPLEX_LONG));
      black_box(res).unwrap();
    })
  });
}

criterion_group!(
  benches,
  bench_calc_short,
  bench_calc_long,
  bench_calc_complex_short,
  bench_calc_complex_long
);
criterion_main!(benches);
