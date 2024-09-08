# CredoExt

Credo Checks Extension

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `credo_ext` along with `credo` to your list of dependencies in `mix.exs`, `credo` itself is required to run default checks and `credo_ext` is required to run custom checks. `credo` is needed for `credo-ext` in compile time:

```elixir
def deps do
  [
    {:credo, "~> 1.7", runtime: false},
    {:credo_ext, "~> 0.1.0"}
  ]
end
```

## Implemented Checks

- `CredoExt.Check.Readability.DoKeywordFunctionsLineConsistency` - This check enforces all functions with same name and arity in a module have `do: ` defined either on the same line of signature or on a new line, ignoring full-body functions (`do ... end`).

### Examples
<details>
<summary>Sample with definitions of functions with arity 1</summary>

```elixir
      defmodule SampleArity1 do
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
```
</details>

<details>
<summary>Sample with definitions of functions with arity 2</summary>

```elixir

      defmodule SampleArity2 do
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

        # do next line
        defp get_type(nil, :ok),
          do: :ok

        # do next line
        defp get_type(nil, :err),
          do: :err
              |> to_string()
              |> IO.inspect(label: "---- io ----", limit: :infinity)
      end
```

</details>

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

