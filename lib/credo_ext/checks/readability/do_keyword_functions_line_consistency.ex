defmodule CredoExt.Check.Readability.DoKeywordFunctionsLineConsistency do
  @moduledoc false
  #  d68364992b6c0ed927963ed78a1e5975
  use Credo.Check,
    id: "EX31001",
    category: :readability,
    base_priority: :high,
    tags: [:style],
    param_defaults: [],
    explanations: [
      check: """
      Ensures that if one function starting with `do:` keyword definition within the module spans multiple lines
      (i.e., `do:` on a new line), all similar function definitions with the same name must also be multi-line for consistency.

      https://github.com/rrrene/credo/blob/master/CHANGELOG.md#add-ids-to-checks,
      Checks are sorted by IDs, considering naming convention, the `ID` of this custom check is `EX31001`, where:
      - `EX` - standing for elixir
      - `3` - standing for category `readability`
      - `1` - standing for `Custom Credo Checks`, considering docs: `The second digit is always 0 for Credo's standard checks`
      - `001` - standing for a unique identifier (max 999 checks per `category` as per docs)

      ## Usage

      Add the needed custom check into to your `.credo.exs` file:

        ```elixir
      %{
        configs: [
          %{
            checks: %{
              enabled: [
                ..., # Other checks
                {CredoExt.Check.Readability.DoKeywordFunctionsLineConsistency, []}
              ]
            }
          }
        ]
      }
      ```

      ## Examples of different function definitions and how are they treated

      ```elixir
      defmodule SampleModule do
        #do on same line
        def get_type(%{type: type}), do: type |> Map.get(:coding) |> hd() |> Map.get(:code)

        #do on same line
        def get_type(%{
          type: type,
          value: value
        }), do: type |> Map.get(:coding) |> hd() |> Map.get(:code)

        #do on next line
        def get_type(%{
          type: :ok,
        }),
          do:  %{coding: [%{code: :ok}]} |> Map.get(:coding) |> hd() |> Map.get(:code)

        #do on same line
        def get_type(%{
          type: :ok_1,
        }), do:
           %{coding: [%{code: :ok_1}]} |> Map.get(:coding) |> hd() |> Map.get(:code)

        #do on same line
        def get_type(%{
          type: :ok_2,
        }), do: %{coding: [%{code: :ok_2}]}
          |> Map.get(:coding)
          |> hd()
          |> Map.get(:code)

        #do on same line
        def get_type(%{
          type: :ok_3,
        }), do: :ok_3

        #ignored because is a full body function
        def get_type(%{
          type: :ok_3,
        }) do
          :ok_3
        end

        # do on same line
        defp get_type(nil, nil), do: nil

        # do on same line
        defp get_type(%{
          item: "item"
        }, nil), do: nil

        # do on same line
        defp get_type(
          %{
            item: "item",
            item2: "item2"
          },
          %{another: "another"}
        ), do: nil

        # do on next line
        defp get_type(%{type: :test}, :ok),
          do: :ok

        # do on next line
        defp get_type(%{
          type: :test,
          value: :error
        }, :ok),
          do: :ok

        # ignored because it is a full body function
        defp get_type(%{
          type: :test,
          value: :error2
        }, :ok) do
          :ok
        end

        # ignored because it is a full body function
        defp get_type(%{
          type: :test,
          value: :error3
        }, :ok) do
          :ok
          |> to_string()
          |> IO.inspect(label: "---- ok ----", limit: :infinity)
        end

        # do on next line
        defp get_type(nil, :ok),
          do: :ok

        # do on next line
        defp get_type(nil, :err),
          do: :err
              |> to_string()
              |> IO.inspect(label: "---- io ----", limit: :infinity)
      end
      ```
      """,
      params: []
    ]

  alias Credo.SourceFile

  @do_atom_same_line_regex ~r/, do: /
  @do_atom_before_new_line_regex ~r/(, )?do:$/
  @do_atom_after_new_line_regex ~r/\s*do:/
  @do_regular_regex ~r/ do$/

  @doc """
  Run the check on the given source file.
  """
  @impl Credo.Check
  def run(%SourceFile{} = source_file, params) do
    with issue_meta <- IssueMeta.for(source_file, params),
         source <- SourceFile.source(source_file),
         ast <- SourceFile.ast(source_file),
         module_functions <- extract_do_atom_function_definitions(ast, source) do
      map_issues(module_functions, issue_meta)
    else
      _ -> []
    end
  end

  defp map_issues(module_functions, issue_meta) do
    if Enum.all?(module_functions, fn {_name, _line_no, format} -> format == :same_line end) ||
         Enum.all?(module_functions, fn {_name, _line_no, format} -> format == :next_line end) do
      []
    else
      Enum.map(module_functions, &map_issue_for(&1, issue_meta))
    end
  end

  defp map_issue_for({_name, line_no, _format}, issue_meta) do
    format_issue(
      issue_meta,
      message:
        "Inconsistent formatting: if one function, starting with `do:` keyword definition within the module, spans " <>
          "multiple lines, all similar function definitions with the same name must also be multi-line for consistency.",
      line_no: line_no
    )
  end

  # AST Traversal to extract function definitions and check their format (single-line or multi-line)
  defp extract_do_atom_function_definitions(ast, source_code) do
    source_lines = String.split(source_code, "\n")

    # Traverse the AST to extract function definitions
    result =
      Macro.prewalk(ast, [], fn
        # Match function definitions (def or defp)
        {access, meta, [{name, _inner_meta, args}, _body]} = node, acc when access in [:def, :defp] ->
          name_with_arity = "#{inspect(name)}/#{get_args_length(args)}"
          function_type = meta[:line] |> get_do_line(source_lines) |> get_function_type()
          {node, [{name_with_arity, meta[:line], function_type} | acc]}

        # If not a function definition, just continue traversal
        other, acc ->
          {other, acc}
      end)

    case result do
      {{_, _, [_, [{_, {_, _, _}}]]}, functions} ->
        Enum.filter(functions, fn {_, _, type} ->
          type != :ignore
        end)

      _ ->
        []
    end
  end

  defp get_args_length(nil), do: 0

  defp get_args_length(args), do: length(args)

  defp get_do_line(line_number, source_lines) do
    line = Enum.at(source_lines, line_number - 1)

    cond do
      nil == line -> nil
      Regex.match?(@do_atom_same_line_regex, line) -> line
      Regex.match?(@do_atom_before_new_line_regex, line) -> line
      Regex.match?(@do_atom_after_new_line_regex, line) -> line
      Regex.match?(@do_regular_regex, line) -> line
      true -> get_do_line(line_number + 1, source_lines)
    end
  end

  defp get_function_type(body_line) do
    cond do
      body_line == nil -> :ignore
      Regex.match?(@do_atom_same_line_regex, body_line) -> :same_line
      Regex.match?(@do_atom_before_new_line_regex, body_line) -> :next_line
      Regex.match?(@do_atom_after_new_line_regex, body_line) -> :next_line
      Regex.match?(@do_regular_regex, body_line) -> :ignore
      true -> :next_line
    end
  end
end
