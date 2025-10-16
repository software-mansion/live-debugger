%{
  configs: [
    %{
      name: "live_debugger",
      files: %{
        included: ["lib/live_debugger/**/*.ex", "test/**/*.exs"],
        excluded: []
      },
      plugins: [],
      requires: [],
      strict: true,
      parse_timeout: 5000,
      color: true,
      checks: %{
        enabled: [
          # always expands `A.{B, C}`
          {Credo.Check.Consistency.MultiAliasImportRequireUse, false},
          # including `case`, `fn` and `with` statements
          {Credo.Check.Consistency.ParameterPatternMatching, false},
          {Credo.Check.Readability.AliasOrder, false},
          {Credo.Check.Readability.BlockPipe, false},
          # goes further than formatter - fixes bad underscores, eg: `100_00` -> `10_000`
          {Credo.Check.Readability.LargeNumbers, false},
          # adds `@moduledoc false`
          {Credo.Check.Readability.ModuleDoc, false},
          {Credo.Check.Readability.MultiAlias, false},
          {Credo.Check.Readability.OneArityFunctionInPipe, false},
          # removes parens
          {Credo.Check.Readability.ParenthesesOnZeroArityDefs, false},
          {Credo.Check.Readability.PipeIntoAnonymousFunctions, false},
          {Credo.Check.Readability.PreferImplicitTry, false},
          {Credo.Check.Readability.SinglePipe, false},
          # **potentially breaks compilation** - see **Troubleshooting** section below
          {Credo.Check.Readability.StrictModuleLayout, false},
          {Credo.Check.Readability.UnnecessaryAliasExpansion, false},
          {Credo.Check.Readability.WithSingleClause, false},
          {Credo.Check.Refactor.CaseTrivialMatches, false},
          {Credo.Check.Refactor.CondStatements, false},
          # in pipes only
          {Credo.Check.Refactor.FilterCount, false},
          # in pipes only
          {Credo.Check.Refactor.MapInto, false},
          # in pipes only
          {Credo.Check.Refactor.MapJoin, false},
          {Credo.Check.Refactor.NegatedConditionsInUnless, false},
          {Credo.Check.Refactor.NegatedConditionsWithElse, false},
          # allows ecto's `from
          {Credo.Check.Refactor.PipeChainStart, false},
          {Credo.Check.Refactor.RedundantWithClauseResult, false},
          {Credo.Check.Refactor.UnlessWithElse, false},
          {Credo.Check.Refactor.WithClauses, false},
        ]
      }
    }
  ]
}
