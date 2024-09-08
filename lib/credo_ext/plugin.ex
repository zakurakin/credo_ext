defmodule CredoExt.Plugin do
  @moduledoc """
  This is the Credo plugin that includes the custom checks.
  """

  def init(exec) do
    exec
  end

  def checks do
    [
      {CredoExt.Checks.Readability.DoKeywordFunctionsLineConsistency, []}
    ]
  end
end
