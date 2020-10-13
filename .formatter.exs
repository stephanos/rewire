locals_without_parens = [
  rewire: 2,
  rewire: 3
]

[
  inputs: ["{mix,.formatter}.exs", "{config,lib,fixtures,test}/**/*.{ex,exs}"],
  locals_without_parens: locals_without_parens,
  export: [
    locals_without_parens: locals_without_parens
  ]
]
