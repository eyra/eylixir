defmodule Systems.Content.TextItemModel do
  use Ecto.Schema
  import Ecto.Changeset

  alias Systems.{
    Content
  }

  schema "text_items" do
    field(:locale, :string, null: false)
    field(:text, :string, null: false)
    field(:text_plural, :string, null: true)
    belongs_to(:bundle, Content.TextBundleModel)
    timestamps()
  end

  @fields ~w()a

  def changeset(item, attrs) do
    item
    |> cast(attrs, @fields)
  end

  def text(%{text: text}, nil), do: text

  def text(%{text_plural: text_plural}, amount) when amount != 1 and not is_nil(text_plural),
    do: replace(text_plural, amount)

  def text(%{text: text}, amount), do: replace(text, amount)

  defp replace(string, amount), do: String.replace(string, "%{amount}", amount)
end