defmodule EyraUI.Text.Title2 do
  @moduledoc """
  This title is to be used for ...?
  """
  use Surface.Component

  slot(default, required: true)
  prop(color, :css_class, default: "text-grey1")
  prop(margin, :string, default: "mb-6 md:mb-8 lg:mb-10")

  def render(assigns) do
    ~H"""
    <div class="text-title5 font-title5 sm:text-title3 sm:font-title3 lg:text-title2 lg:font-title2 {{@margin}} {{@color}}">
      <slot />
    </div>
    """
  end
end
