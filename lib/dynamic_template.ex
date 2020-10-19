defmodule DynamicTemplate do
  def render(file_path, view_module, assigns) do
    module_name = module_name(file_path)

    if not Code.ensure_loaded?(module_name) do
      compile(file_path, module_name, view_module)
    end

    apply(module_name, :render, [assigns])
  end

  def compile(file_path, view_module) when is_binary(file_path) do
    compile(file_path, module_name(file_path), view_module)
  end

  def compile(file_path, module_name, view_module) when is_binary(file_path) and is_atom(module_name) and is_atom(view_module) do
    EEx.compile_file(file_path)
    |> quoted_template_module(module_name, view_module)
    |> Code.compile_quoted()

    :ok
  end

  def remove_by_file(file_path) when is_binary(file_path) do
    remove_by_name(module_name(file_path))
  end

  def remove_by_name(module_name) when is_atom(module_name) do
    :code.delete(module_name)
    :code.purge(module_name) # this kills all processes using the module (there's also soft_purge)
  end

  def module_name(file_path) do
    file_path
    |> get_module_identifier_from_filepath()
    |> get_qualified_temp_module_name()
  end

  defp quoted_template_module(quoted_template, module_name, view_module) do
    quote do
      defmodule unquote(module_name) do
        import unquote(view_module)

        def render(var!(assigns)) do
          _ = var!(assigns)
          unquote(quoted_template)
        end
      end
    end
  end

  defp get_qualified_temp_module_name(module_identifier) do
    ("Elixir.EExHelpersPriv." <> module_identifier)
    |> String.to_atom()
  end

  defp get_module_identifier_from_filepath(path) do
    # tried to make this regex as: /[^\.]\w/ but it matched every pair of characters (not what I wanted) - reason to have multiple `String.replace`

    path
    |> Path.rootname()
    |> Path.basename()
    |> String.replace(~r/^\w/, fn
      <<char>> -> <<char + (?A - ?a)>>
    end)
    |> String.replace(~r/\.\w/, fn
      <<?., char>> -> <<char + (?A - ?a)>>
    end)
    |> String.replace(~r/\_\w/, fn
      <<?_, char>> -> <<char + (?A - ?a)>>
    end)
  end
end
