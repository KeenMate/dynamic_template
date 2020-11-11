defmodule DynamicTemplate do
  def render(module_name, assigns) do
    case Code.ensure_loaded?(module_name) do
      true -> {:ok, render!(module_name, assigns)}
      false -> {:error, :template_not_loaded}
    end
  end

  def render!(module_name, assigns) do
    apply(module_name, :render, [assigns])
  end

  def compile(template_string, module_name, view_module, rendering_engine \\ Phoenix.HTML.Engine) when is_binary(template_string) and is_atom(rendering_engine) do
    EEx.compile_string(template_string, engine: rendering_engine)
    |> compile_ast(module_name, view_module)
  end

  def remove(module_name) when is_atom(module_name) do
    :code.delete(module_name)
    :code.purge(module_name) # this kills all processes using the module (there's also soft_purge)
  end

  defp compile_ast(ast, module_name, view_module) when is_atom(module_name) and is_atom(view_module) do
    ast
    |> quoted_template_module(module_name, view_module)
    |> Code.compile_quoted()

    :ok
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
end
