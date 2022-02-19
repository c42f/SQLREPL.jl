# SQLREPL.jl

A Julia REPL mode for PostgreSQL powered by
[ReplMaker.jl](https://github.com/MasonProtter/ReplMaker.jl),
[LibPQ.jl](https://github.com/invenia/LibPQ.jl) and
[SQLStrings.jl](https://github.com/JuliaComputing/SQLStrings.jl).

## Tutorial

This is an unregistered package but you can install it with Julia's Pkg mode:
```
pkg> add https://github.com/c42f/SQLREPL.jl
```

To connect the REPL mode, you'll need a connection string for your Postgres
database. You can then use:

```julia
julia> using SQLREPL
julia> SQLREPL.connect("your_connection_string")
REPL mode SQL initialized. Press ) to enter and backspace to exit.
"Prompt(\"SQL> \",...)"
```

Now press `)` to enter the REPL mode. You can create tables and do some simple
data insertion and extraction with standard SQL syntax:

```sql
SQL> create table foo (x text, y int);

SQL> insert into foo values ('hi', 1);

SQL> insert into foo values ('ho ho', 2);

SQL> select * from foo
2×2 DataFrame
 Row │ x        y      
     │ String?  Int32? 
─────┼─────────────────
   1 │ hi            1
   2 │ ho ho         2
```

Thanks to SQLStrings.jl, you can also interpolate local Julia values into your
expression. Let's set `min_y` in the Julia `Main` module:

```julia
julia> min_y = 2
```

And we can now use `$min_y` within our queries:

```sql
SQL> select * from foo where y >= $min_y
1×2 DataFrame
 Row │ x        y      
     │ String?  Int32? 
─────┼─────────────────
   1 │ ho ho         2
```

For more complex data manipulation, the REPL mode can be combined with
programmatic access via the normal Julia REPL:

```julia
julia> using LibPQ, SQLStrings

julia> conn = LibPQ.Connection("");

julia> for y=1:10
           msg = "Hi $y"
           LibPQ.execute(conn, sql`insert into foo values ($msg, $y)`)
       end
```

thence

```sql
SQL> select * from foo
12×2 DataFrame
 Row │ x        y      
     │ String?  Int32? 
─────┼─────────────────
   1 │ hi            1
   2 │ ho ho         2
   3 │ Hi 1          1
   4 │ Hi 2          2
   5 │ Hi 3          3
   6 │ Hi 4          4
   7 │ Hi 5          5
   8 │ Hi 6          6
   9 │ Hi 7          7
  10 │ Hi 8          8
  11 │ Hi 9          9
  12 │ Hi 10        10
```


## How To

### Editing multi-line statements

To edit multi-line SQL statements easily, surround your statement with brackets:

```sql
SQL> (select * from foo
         where y > 5
         and   y <= 7)
2×2 DataFrame
 Row │ x        y      
     │ String?  Int32? 
─────┼─────────────────
   1 │ Hi 6          6
   2 │ Hi 7          7
```

Alternatively, to insert a line, the usual key binding `ALT+Enter` can always be used.

### Accessing the result of the previous query

The resulting `DataFrame` is available in the `ans` variable back in the Julia
REPL. Starting with

```sql
SQL> (select * from foo
         where y > 5
         and   y <= 7);
```

we then have

```julia
julia> ans
2×2 DataFrame
 Row │ x        y      
     │ String?  Int32? 
─────┼─────────────────
   1 │ Hi 6          6
   2 │ Hi 7          7
```

### Inspecting table schema

To inspect table schema you can use the `psql`-like meta-command `\d`:

```sql
SQL> \d foo
2×5 DataFrame
 Row │ column_name  data_type  character_maximum_length  column_default  is_nullable 
     │ String?      String?    Union{Missing, Int32}     String?         String?     
─────┼───────────────────────────────────────────────────────────────────────────────
   1 │ x            text                        missing  missing         YES
   2 │ y            integer                     missing  missing         YES
```

In the future we might implement more of the
[`psql` meta-commands](https://www.postgresql.org/docs/14/app-psql.html).

## Development

[![Build Status](https://github.com/c42f/SQLREPL.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/c42f/SQLREPL.jl/actions/workflows/CI.yml?query=branch%3Amain)

This package arose from [a discussion](https://discourse.julialang.org/t/easiest-and-most-complete-package-for-postgresql-right-now-feb-2022/75920) on Julia discourse.
