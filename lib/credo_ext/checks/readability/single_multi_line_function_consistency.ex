defmodule CredoExt.Check.Readability.SingleMultiLineFunctionConsistency do
  @moduledoc false

  use Credo.Check,
    # https://github.com/rrrene/credo/blob/master/CHANGELOG.md#add-ids-to-checks,
    # Checks are sorted by IDs, considering naming convention, let's use ID: EX31001, where:
    # - EX standing for elixir
    # - 3: Category "readability"
    # - 1: "Custom Credo Checks", considering docs: "The second digit is always 0 for Credo's standard checks "
    # - 001: a unique identifier (max 999 checks per category as per docs)
    id: "EX31001",
    category: :readability,
    base_priority: :high,
    tags: [:style],
    param_defaults: [],
    explanations: [
      check: """
      Ensures that if one function definition spans multiple lines (i.e., `do:` on a new line), all similar function
      definitions with the same name must also be multi-line for consistency.
      """,
      params: []
    ]

  alias Credo.SourceFile

  @do_atom_same_line_regex ~r/, do: /
  @do_atom_before_new_line_regex ~r/(, )?do:$/
  @do_atom_after_new_line_regex ~r/\s*do:/
  @do_regular_regex ~r/ do$/

  @doc false
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

  # Check if the group of function definitions has mixed formats (single-line and multi-line)
  defp same_do_atom_format?(module_functions),
    do:
      Enum.all?(module_functions, fn {_name, _line_no, format} -> format == :same_line end) ||
        Enum.all?(module_functions, fn {_name, _line_no, format} -> format == :next_line end)

  defp map_issues(module_functions, issue_meta) do
    if same_do_atom_format?(module_functions) do
      []
    else
      Enum.map(module_functions, &map_issue_for(&1, issue_meta))
    end
  end

  defp map_issue_for({_name, line_no, _format}, issue_meta) do
    format_issue(
      issue_meta,
      message: "Inconsistent formatting: if one function is multi-line, all should follow the same pattern.",
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

  defp get_args_length(nil),
    do: 0

  defp get_args_length(args),
    do: length(args)

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
