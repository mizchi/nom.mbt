# Benchmarks

This folder contains a small nom (Rust) benchmark to compare with the MoonBit implementation.

## MoonBit

From repo root:

```sh
moon -C nom.mbt bench
```

If you have native target support and want closer comparison to Rust:

```sh
moon -C nom.mbt bench --target native
```

## Rust (nom)

```sh
cd nom.mbt/bench/nom-rs
cargo bench
```

## Notes

- The MoonBit benchmarks live in `nom.mbt/src/str/bench.mbt` and `nom.mbt/src/bytes/bench.mbt`.
- They include both the nom.mbt parsers and hand-written implementations.
- The Rust benchmarks parse the same expressions as MoonBit to keep inputs aligned.
