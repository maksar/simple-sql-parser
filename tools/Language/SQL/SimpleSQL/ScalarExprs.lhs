
Tests for parsing scalar expressions

> module Language.SQL.SimpleSQL.ScalarExprs (scalarExprTests) where

> import Language.SQL.SimpleSQL.TestTypes
> import Language.SQL.SimpleSQL.Syntax

> scalarExprTests :: TestItem
> scalarExprTests = Group "scalarExprTests"
>     [literals
>     ,identifiers
>     ,star
>     ,app
>     ,caseexp
>     ,operators
>     ,parens
>     ,subqueries
>     ,aggregates
>     ,windowFunctions
>     ]

> literals :: TestItem
> literals = Group "literals" $ map (uncurry TestScalarExpr)
>     [("3", NumLit "3")
>      ,("3.", NumLit "3.")
>      ,("3.3", NumLit "3.3")
>      ,(".3", NumLit ".3")
>      ,("3.e3", NumLit "3.e3")
>      ,("3.3e3", NumLit "3.3e3")
>      ,(".3e3", NumLit ".3e3")
>      ,("3e3", NumLit "3e3")
>      ,("3e+3", NumLit "3e+3")
>      ,("3e-3", NumLit "3e-3")
>      ,("'string'", StringLit "string")
>      ,("'1'", StringLit "1")
>      ,("interval '3' day", IntervalLit "3" "day" Nothing)
>      ,("interval '3' day (3)", IntervalLit "3" "day" $ Just 3)
>     ]

> identifiers :: TestItem
> identifiers = Group "identifiers" $ map (uncurry TestScalarExpr)
>     [("iden1", Iden "iden1")
>     ,("t.a", Iden2 "t" "a")
>     ]

> star :: TestItem
> star = Group "star" $ map (uncurry TestScalarExpr)
>     [("*", Star)
>     ,("t.*", Star2 "t")
>     ,("ROW(t.*,42)", App "ROW" [Star2 "t", NumLit "42"])
>     ]

> app :: TestItem
> app = Group "app" $ map (uncurry TestScalarExpr)
>     [("f()", App "f" [])
>     ,("f(a)", App "f" [Iden "a"])
>     ,("f(a,b)", App "f" [Iden "a", Iden "b"])
>     ]

> caseexp :: TestItem
> caseexp = Group "caseexp" $ map (uncurry TestScalarExpr)
>     [("case a when 1 then 2 end"
>      ,Case (Just $ Iden "a") [(NumLit "1"
>                               ,NumLit "2")] Nothing)

>     ,("case a when 1 then 2 when 3 then 4 end"
>      ,Case (Just $ Iden "a") [(NumLit "1", NumLit "2")
>                              ,(NumLit "3", NumLit "4")] Nothing)

>     ,("case a when 1 then 2 when 3 then 4 else 5 end"
>      ,Case (Just $ Iden "a") [(NumLit "1", NumLit "2")
>                              ,(NumLit "3", NumLit "4")] (Just $ NumLit "5"))

>     ,("case when a=1 then 2 when a=3 then 4 else 5 end"
>      ,Case Nothing [(BinOp (Iden "a") "=" (NumLit "1"), NumLit "2")
>                    ,(BinOp (Iden "a") "=" (NumLit "3"), NumLit "4")]
>                    (Just $ NumLit "5"))

>     ]

> operators :: TestItem
> operators = Group "operators"
>     [binaryOperators
>     ,unaryOperators
>     ,casts
>     ,miscOps]

> binaryOperators :: TestItem
> binaryOperators = Group "binaryOperators" $ map (uncurry TestScalarExpr)
>     [("a + b", BinOp (Iden "a") "+" (Iden "b"))
>      -- sanity check fixities
>      -- todo: add more fixity checking

>     ,("a + b * c"
>      ,BinOp  (Iden "a") "+"
>              (BinOp (Iden "b") "*" (Iden "c")))

>     ,("a * b + c"
>      ,BinOp (BinOp (Iden "a") "*" (Iden "b"))
>             "+" (Iden "c"))
>     ]

> unaryOperators :: TestItem
> unaryOperators = Group "unaryOperators" $ map (uncurry TestScalarExpr)
>     [("not a", PrefixOp "not" $ Iden "a")
>     ,("not not a", PrefixOp "not" $ PrefixOp "not" $ Iden "a")
>     ,("+a", PrefixOp "+" $ Iden "a")
>     ,("-a", PrefixOp "-" $ Iden "a")
>     ]


> casts :: TestItem
> casts = Group "operators" $ map (uncurry TestScalarExpr)
>     [("cast('1' as int)"
>      ,Cast (StringLit "1") $ TypeName "int")

>     ,("int '3'"
>      ,CastOp (TypeName "int") "3")

>     ,("cast('1' as double precision)"
>      ,Cast (StringLit "1") $ TypeName "double precision")

>     ,("double precision '3'"
>      ,CastOp (TypeName "double precision") "3")
>     ]

> subqueries :: TestItem
> subqueries = Group "unaryOperators" $ map (uncurry TestScalarExpr)
>     [("exists (select a from t)", SubQueryExpr SqExists ms)
>     ,("(select a from t)", SubQueryExpr SqSq ms)

>     ,("a in (select a from t)"
>      ,In True (Iden "a") (InQueryExpr ms))

>     ,("a not in (select a from t)"
>      ,In False (Iden "a") (InQueryExpr ms))

>     ,("a > all (select a from t)"
>      ,BinOp (Iden "a") ">" (SubQueryExpr SqAll ms))

>     ,("a = some (select a from t)"
>      ,BinOp (Iden "a") "=" (SubQueryExpr SqSome ms))

>     ,("a <= any (select a from t)"
>      ,BinOp (Iden "a") "<=" (SubQueryExpr SqAny ms))
>     ]
>   where
>     ms = makeSelect
>          {qeSelectList = [(Nothing,Iden "a")]
>          ,qeFrom = [TRSimple "t"]
>          }

> miscOps :: TestItem
> miscOps = Group "unaryOperators" $ map (uncurry TestScalarExpr)
>     [("a in (1,2,3)"
>      ,In True (Iden "a") $ InList $ map NumLit ["1","2","3"])

>     ,("a between b and c", SpecialOp "between" [Iden "a"
>                                                ,Iden "b"
>                                                ,Iden "c"])

>     ,("a not between b and c", SpecialOp "not between" [Iden "a"
>                                                        ,Iden "b"
>                                                        ,Iden "c"])

>     ,("a is null", PostfixOp "is null" (Iden "a"))
>     ,("a is not null", PostfixOp "is not null" (Iden "a"))
>     ,("a is true", PostfixOp "is true" (Iden "a"))
>     ,("a is not true", PostfixOp "is not true" (Iden "a"))
>     ,("a is false", PostfixOp "is false" (Iden "a"))
>     ,("a is not false", PostfixOp "is not false" (Iden "a"))
>     ,("a is unknown", PostfixOp "is unknown" (Iden "a"))
>     ,("a is not unknown", PostfixOp "is not unknown" (Iden "a"))
>     ,("a is distinct from b", BinOp (Iden "a") "is distinct from"(Iden "b"))

>     ,("a is not distinct from b"
>      ,BinOp (Iden "a") "is not distinct from" (Iden "b"))

>     ,("a like b", BinOp (Iden "a") "like" (Iden "b"))
>     ,("a not like b", BinOp (Iden "a") "not like" (Iden "b"))
>     ,("a is similar to b", BinOp (Iden "a") "is similar to" (Iden "b"))

>     ,("a is not similar to b"
>      ,BinOp (Iden "a") "is not similar to" (Iden "b"))

>     ,("a overlaps b", BinOp (Iden "a") "overlaps" (Iden "b"))
>     ,("extract(day from t)", SpecialOp "extract" [Iden "day", Iden "t"])

>     ,("substring(x from 1 for 2)"
>      ,SpecialOp "substring" [Iden "x", NumLit "1", NumLit "2"])

>     ]

> aggregates :: TestItem
> aggregates = Group "aggregates" $ map (uncurry TestScalarExpr)
>     [("count(*)",App "count" [Star])

>     ,("sum(a order by a)"
>     ,AggregateApp "sum" Nothing [Iden "a"] [(Iden "a", Asc)])

>     ,("sum(all a)"
>     ,AggregateApp "sum" (Just All) [Iden "a"] [])

>     ,("count(distinct a)"
>     ,AggregateApp "count" (Just Distinct) [Iden "a"] [])
>     ]

> windowFunctions :: TestItem
> windowFunctions = Group "windowFunctions" $ map (uncurry TestScalarExpr)
>     [("max(a) over ()", WindowApp "max" [Iden "a"] [] [])
>     ,("count(*) over ()", WindowApp "count" [Star] [] [])

>     ,("max(a) over (partition by b)"
>      ,WindowApp "max" [Iden "a"] [Iden "b"] [])

>     ,("max(a) over (partition by b,c)"
>      ,WindowApp "max" [Iden "a"] [Iden "b",Iden "c"] [])

>     ,("sum(a) over (order by b)"
>      ,WindowApp "sum" [Iden "a"] [] [(Iden "b", Asc)])

>     ,("sum(a) over (order by b desc,c)"
>      ,WindowApp "sum" [Iden "a"] [] [(Iden "b", Desc)
>                                     ,(Iden "c", Asc)])

>     ,("sum(a) over (partition by b order by c)"
>      ,WindowApp "sum" [Iden "a"] [Iden "b"] [(Iden "c", Asc)])
>      -- todo: check order by options, add frames
>     ]

> parens :: TestItem
> parens = Group "parens" $ map (uncurry TestScalarExpr)
>     [("(a)", Parens (Iden "a"))
>     ,("(a + b)", Parens (BinOp (Iden "a") "+" (Iden "b")))
>     ]
