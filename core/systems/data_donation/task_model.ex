defmodule Systems.DataDonation.TaskModel do
  use Ecto.Schema
  import Ecto.Changeset

  embedded_schema do
    field(:position, :integer)
    field(:title, :string)
    field(:subtitle, :string)
  end

  @fields ~w(position title subtitle)a

  def changeset(model, params) do
    model
    |> cast(params, @fields)
    |> validate_required(@fields)
  end
end
