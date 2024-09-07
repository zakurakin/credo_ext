defmodule CredoExt.Check.Readability.SingleMultiLineFunctionConsistencyTest do
  @moduledoc false

  use Credo.Test.Case

  alias CredoExt.Check.Readability.SingleMultiLineFunctionConsistency

  setup do
    {:ok, _} = Application.ensure_all_started(:credo)

    :ok
  end

  test "should NOT report expected code" do
    [
      """
      defmodule CredoSampleModule do
        defp get_type(%{type: type}), do: type |> Map.get(:coding) |> hd() |> Map.get(:code)
        defp get_type(nil), do: nil
      end
      """,
      """
      defmodule CredoSampleModule do
        defp get_type(%{type: type}),
          do: type |> Map.get(:coding) |> hd() |> Map.get(:code)

        defp get_type(nil),
          do: nil
      end
      """
    ]
    |> to_source_files()
    |> run_check(SingleMultiLineFunctionConsistency)
    |> refute_issues()
  end

  test "should NOT report expected code when args are multi-lined" do
    [
      """
      defmodule CredoSampleModule do
        defp get_type(%{
          type: type,
          value: _value
        }), do: type |> Map.get(:coding) |> hd() |> Map.get(:code)

        defp get_type(nil), do: nil
      end
      """,
      """
      defmodule CredoSampleModule do
        defp get_type(%{type: type}),
          do: type |> Map.get(:coding) |> hd() |> Map.get(:code)

        defp get_type(nil),
          do: nil
      end
      """
    ]
    |> to_source_files()
    |> run_check(SingleMultiLineFunctionConsistency)
    |> refute_issues()
  end

  test "should NOT report expected code when some function isn't start with atom do:" do
    [
      """
      defmodule CredoSampleModule do
        defp get_type(%{
          type: type,
          value: _value
        }), do: type |> Map.get(:coding) |> hd() |> Map.get(:code)

        defp get_type(%{
          type: type
        }) do
          type |> Map.get(:coding) |> hd() |> Map.get(:code)
        end

        defp get_type(nil), do: nil
      end
      """,
      """
      defmodule CredoSampleModule do
        defp get_type(%{type: type}),
          do: type |> Map.get(:coding) |> hd() |> Map.get(:code)

        defp get_type(nil),
          do: nil
      end
      """
    ]
    |> to_source_files()
    |> run_check(SingleMultiLineFunctionConsistency)
    |> refute_issues()
  end

  test "should report expected code when there are functions having same time do next line and same line, ignoring full body" do
    [
      """
      defmodule CredoSampleModule do
        #1 do on same line
        defp get_type(%{type: type}), do: type |> Map.get(:coding) |> hd() |> Map.get(:code)

        #2 do on same line
        defp get_type(%{
          type: type,
          value: value
        }), do: type |> Map.get(:coding) |> hd() |> Map.get(:code)

        #3 do on next line
        defp get_type(%{
          type: :ok,
        }),
          do: :ok |> Map.get(:coding) |> hd() |> Map.get(:code)

        #4 do on same line
        defp get_type(%{
          type: :ok_1,
        }), do:
          :ok_1 |> Map.get(:coding) |> hd() |> Map.get(:code)

        #5 do on same line
        defp get_type(%{
          type: :ok_2,
        }), do: :ok_2
          |> Map.get(:coding)
          |> hd()
          |> Map.get(:code)

        #6 do same line
        defp get_type(%{
          type: :ok_3,
        }), do: :ok_3

        #7 ignored because is a full body function
        defp get_type(%{
          type: :ok_3,
        }) do
          :ok_3
        end
      end
      """
    ]
    |> to_source_files()
    |> run_check(SingleMultiLineFunctionConsistency)
    |> assert_issues(fn issues ->
      assert Enum.count(issues) == 6

      assert 6 ==
               issues
               |> Enum.filter(fn issue ->
                 issue.scope == "CredoSampleModule.get_type"
               end)
               |> Enum.count()
    end)
  end

  test "should report expected code when there are functions having same time do next line and same line, ignoring full body, access def" do
    [
      """
      defmodule CredoSampleModule do
        #1 do on same line
        def get_type(%{type: type}), do: type |> Map.get(:coding) |> hd() |> Map.get(:code)

        #2 do on same line
        def get_type(%{
          type: type,
          value: value
        }), do: type |> Map.get(:coding) |> hd() |> Map.get(:code)

        #3 do on next line
        def get_type(%{
          type: :ok,
        }),
          do: :ok |> Map.get(:coding) |> hd() |> Map.get(:code)

        #4 do on same line
        def get_type(%{
          type: :ok_1,
        }), do:
          :ok_1 |> Map.get(:coding) |> hd() |> Map.get(:code)

        #5 do on same line
        def get_type(%{
          type: :ok_2,
        }), do: :ok_2
          |> Map.get(:coding)
          |> hd()
          |> Map.get(:code)

        #6 do same line
        def get_type(%{
          type: :ok_3,
        }), do: :ok_3

        #7 ignored because is a full body function
        def get_type(%{
          type: :ok_3,
        }) do
          :ok_3
        end
      end
      """
    ]
    |> to_source_files()
    |> run_check(SingleMultiLineFunctionConsistency)
    |> assert_issues(fn issues ->
      assert Enum.count(issues) == 6

      assert 6 ==
               issues
               |> Enum.filter(fn issue ->
                 issue.scope == "CredoSampleModule.get_type"
               end)
               |> Enum.count()
    end)
  end

  test "should report expected code when there are functions having same time do next line and same line, ignoring full body, arity 2" do
    [
      """
      defmodule CredoSampleModule do
        # do same line
        defp get_type(nil, nil), do: nil

        # do same line
        defp get_type(%{
          item: "item"
        }, nil), do: nil

        # do same line
        defp get_type(
          %{
            item: "item",
            item2: "item2"
          },
          %{another: "another"}
        ), do: nil

        # do next line
        defp get_type(%{type: :test}, :ok),
          do: :ok

        # do next line
        defp get_type(%{
          type: :test,
          value: :error
        }, :ok),
          do: :ok

        # ignored because it is full body function
        defp get_type(%{
          type: :test,
          value: :error2
        }, :ok) do
          :ok
        end

        # ignored because it is full body function
        defp get_type(%{
          type: :test,
          value: :error3
        }, :ok) do
          :ok
          |> to_string()
          |> IO.inspect(label: "---- ok ----", limit: :infinity)
        end

        # do next line
        defp get_type(nil, :ok),
          do: :ok

        # do next line
        defp get_type(nil, :err),
          do: :err
              |> IO.inspect(label: "---- io ----", limit: :infinity)
              |> IO.inspect(label: "---- io ----", limit: :infinity)
      end
      """
    ]
    |> to_source_files()
    |> run_check(SingleMultiLineFunctionConsistency)
    |> assert_issues(fn issues ->
      assert Enum.count(issues) == 7

      assert 7 ==
               issues
               |> Enum.filter(fn issue ->
                 issue.scope == "CredoSampleModule.get_type"
               end)
               |> Enum.count()
    end)
  end

  test "should report code that violates the SingleMultiLineFunctionConsistency rule" do
    [
      """
      defmodule CredoSampleModule do
        defp fn1(%{type: type, value: _value}), do: type |> Map.get(:coding) |> hd() |> Map.get(:code)

        defp fn1(%{
          type: type,
          value: _value,
          code: _code
        }), do: type |> Map.get(:coding) |> hd() |> Map.get(:code)

        defp fn1(%{type: nil}), do: type |> Map.get(:coding) |> hd() |> Map.get(:code)

        defp fn1(:ok), do: :ok

        defp fn1(:not_ok),
          do: :not_ok

        defp fn1(nil) do
          :error
          IO.puts("error")
        end

        defp fn1(:test) do
          :test
          |> IO.inspect(label: "---- test ----", limit: :infinity)
        end

        defp fn1(_) do
          :error |> IO.inspect(label: "---- io ----", limit: :infinity)
        end
      end
      """,
      """
      defmodule CredoSampleModule2 do
        defp fn2(%{type: type}), do: type |> Map.get(:coding) |> hd() |> Map.get(:code)

        defp fn2(nil),
          do: nil
      end
      """,
      """
      defmodule CredoSampleModule3 do
        defp fn3(%{type: type}), do: type |> Map.get(:coding) |> hd() |> Map.get(:code)

        defp fn3(%{
          type: type,
          value: value
        }), do: type |> Map.get(:coding) |> hd()
          |> Map.get(:code)

        defp fn3(%{
          type: type,
          value: value,
          test: test
        }), do: type |> Map.get(:coding) |> hd() |> Map.get(:code)

        defp fn3(nil, nil),
          do: nil
      end
      """
    ]
    |> to_source_files()
    |> run_check(SingleMultiLineFunctionConsistency)
    |> assert_issues(fn issues ->
      assert Enum.count(issues) == 11
    end)
  end

  test "should report code that violates the SingleMultiLineFunctionConsistency rule when mixing valid/invalid sources" do
    [
      """
      defmodule InvalidModule1 do
        defp get_type(%{type: type}), do: type |> Map.get(:coding) |> hd() |> Map.get(:code)

        defp get_type(%{type: nil}), do: type |> Map.get(:coding) |> hd() |> Map.get(:code)

        defp get_type(nil),
          do: nil
      end
      """,
      """
      defmodule ValidModule1 do
        defp get_type(%{type: type}), do: type |> Map.get(:coding) |> hd() |> Map.get(:code)
        defp get_type(nil), do: nil
      end
      """,
      """
      defmodule InvalidModule2 do
        defp get_type(%{type: type}), do: type |> Map.get(:coding) |> hd() |> Map.get(:code)

        defp get_type(nil),
          do: nil
      end
      """,
      """
      defmodule ValidModule2 do
        defp get_type(%{type: type}),
          do: type |> Map.get(:coding) |> hd() |> Map.get(:code)

        defp get_type(nil),
          do: nil
      end
      """,
      """
      defmodule InvalidModule3 do
        defp get_type(%{type: type}), do: type |> Map.get(:coding) |> hd() |> Map.get(:code)

        defp get_type(nil),
          do: nil
      end
      """,
      """
      defmodule InvalidModule4 do
        defp test("a"), do: "a"
        defp test("b"), do: "b"
        defp test(_), do: :error

        defp test2("a"), do: "a"
        defp test2("b"),
          do: "b"
        defp test2(_), do: nil

        defp get_type(%{type: type}), do: type |> Map.get(:coding) |> hd() |> Map.get(:code)

        defp get_type(nil),
          do: nil
      end
      """
    ]
    |> to_source_files()
    |> run_check(SingleMultiLineFunctionConsistency)
    |> assert_issues(fn issues ->
      assert Enum.count(issues) == 15

      assert 3 ==
               issues
               |> Enum.filter(fn issue -> issue.scope == "InvalidModule1.get_type" end)
               |> Enum.count()

      assert 2 ==
               issues
               |> Enum.filter(fn issue -> issue.scope == "InvalidModule2.get_type" end)
               |> Enum.count()

      assert 2 ==
               issues
               |> Enum.filter(fn issue -> issue.scope == "InvalidModule3.get_type" end)
               |> Enum.count()

      assert 3 ==
               issues
               |> Enum.filter(fn issue -> issue.scope == "InvalidModule4.test" end)
               |> Enum.count()

      assert 3 ==
               issues
               |> Enum.filter(fn issue -> issue.scope == "InvalidModule4.test2" end)
               |> Enum.count()

      assert 2 ==
               issues
               |> Enum.filter(fn issue -> issue.scope == "InvalidModule4.get_type" end)
               |> Enum.count()
    end)
  end
end
