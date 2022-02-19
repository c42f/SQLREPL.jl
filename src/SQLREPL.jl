module SQLREPL

import LibPQ
import DataFrames
import ReplMaker
import REPL

# This uses some implementation details from SQLStrings
using SQLStrings
using SQLStrings: Sql, SplatArgs, Literal, parse_interpolations

function match_magic_syntax(str)
    m = match(r"(\\d) *(.*)", str)
    if !isnothing(m)
        return (m[1], m[2])
    else
        return nothing
    end
end

# One imperfect way to allow multi-line editing
function valid_input_checker(prompt_state)
    cmdstr = String(take!(copy(REPL.LineEdit.buffer(prompt_state))))
    magic = match_magic_syntax(cmdstr)
    if !isnothing(magic)
        return !isempty(magic[2])
    end
    length(findall(')', cmdstr)) == length(findall('(', cmdstr))
end

function libpq_eval(conn, str)
    magic = match_magic_syntax(str)
    if !isnothing(magic)
        if magic[1] == "\\d"
            table_name = magic[2]
            query = sql```
                SELECT
                    column_name,
                    data_type,
                    character_maximum_length,
                    column_default,
                    is_nullable
                FROM INFORMATION_SCHEMA.COLUMNS
                WHERE table_name = $table_name
            ```
            # TODO: Allow a pattern here and use `LIKE` with table_name?
        else
            error("Unknown magic command $(magic[1])")
        end
    else
        query = macroexpand(SQLStrings, :(@sql_cmd $str))
    end
    return quote
        $LibPQ.execute($conn, $query) |> $DataFrames.DataFrame
    end
end

"""
    SQLREPL.connect(conn; start_key=')')

Connect a PostgresSQL to a Julia REPL mode activated with `start_key`.  The
connection `conn` can either be a Postgres connection string or a
`LibPQ.Connection` object.
"""
function connect(conn::LibPQ.Connection; start_key=')')
    ReplMaker.initrepl(s->libpq_eval(conn, s),
                       valid_input_checker = valid_input_checker,
                       prompt_text="SQL> ",
                       prompt_color = :blue,
                       start_key=start_key,
                       mode_name="SQL")
end

function connect(connstr::AbstractString; kws...)
    connect(LibPQ.Connection(connstr); kws...)
end

end
