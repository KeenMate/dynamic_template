defmodule DynamicTemplateTest do
  use ExUnit.Case
  doctest DynamicTemplate

  test "greets the world" do
    assert DynamicTemplate.hello() == :world
  end
end
