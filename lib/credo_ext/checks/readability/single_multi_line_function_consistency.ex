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

  @comma_do_atom_regex ~r/\s*, do:/
  @do_atom_regex ~r/\s*do:/
  @do_regex ~r/\s*do/

  @doc false
  @impl Credo.Check
  def run(%SourceFile{} = source_file, params) do
    with issue_meta <- IssueMeta.for(source_file, params),
         source <- SourceFile.source(source_file),
         ast <- SourceFile.ast(source_file),
         {{_, _, [_, [{_, {_, _, _}}]]}, functions} <- extract_function_definitions(ast, source) do
      functions
      |> Enum.filter(fn {_, _, type} -> type != :ignore end)
      |> Enum.group_by(&elem(&1, 0))
      |> Enum.reduce([], &map_issues(&1, &2, issue_meta))
    else
      _ -> []
    end
  end

  defp map_issues({_fn_name, matches}, acc, issue_meta) do
    if has_mixed_format?(matches) do
      acc ++ Enum.map(matches, &map_issue_for(&1, issue_meta))
    else
      acc
    end
  end

  # Check if the group of function definitions has mixed formats (single-line and multi-line)
  defp has_mixed_format?(matches),
    do:
      Enum.any?(matches, fn {_name, _line_no, format} -> format == :same_line end) &&
        Enum.any?(matches, fn {_name, _line_no, format} -> format == :next_line end)

  defp map_issue_for({_name, line_no, _format}, issue_meta) do
    format_issue(
      issue_meta,
      message: "Inconsistent formatting: if one function is multi-line, all should follow the same pattern.",
      line_no: line_no
    )
  end

  # AST Traversal to extract function definitions and check their format (single-line or multi-line)
  defp extract_function_definitions(ast, source_code) do
    source_lines = String.split(source_code, "\n")

    # Traverse the AST to extract function definitions
    Macro.prewalk(ast, [], fn
      # Match function definitions (def or defp)
      {access, meta, [{name, _inner_meta, args}, _body]} = node, acc when access in [:def, :defp] ->
        name_with_arity = "#{inspect(name)}/#{get_args_length(args)}"
        function_type = meta[:line] |> get_body_line(source_lines) |> get_function_type()
        {node, [{name_with_arity, meta[:line], function_type} | acc]}

      # If not a function definition, just continue traversal
      other, acc ->
        {other, acc}
    end)
  end

  defp get_args_length(nil), do: 0
  defp get_args_length(args), do: length(args)

  defp get_function_type(body_line) do
    cond do
      Regex.match?(@comma_do_atom_regex, body_line) -> :same_line
      Regex.match?(@do_atom_regex, body_line) -> :next_line
      true -> :ignore
    end
  end

  defp get_body_line(line_number, source_lines) do
    line = Enum.at(source_lines, line_number - 1)

    if Regex.match?(@comma_do_atom_regex, line) || Regex.match?(@do_atom_regex, line) || Regex.match?(@do_regex, line) do
      line
    else
      get_body_line(line_number + 1, source_lines)
    end
  end
end
