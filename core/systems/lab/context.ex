defmodule Systems.Lab.Context do
  import Ecto.Query, warn: false
  alias Core.Repo

  alias Systems.{
    Lab
  }

  alias Core.Accounts.User

  def get(id, opts \\ []) do
    from(lab_tool in Lab.ToolModel,
      preload: ^Keyword.get(opts, :preload, [])
    )
    |> Repo.get!(id)
  end

  def reserve_time_slot(time_slot_id, %User{} = user) when is_integer(time_slot_id) do
    Lab.TimeSlotModel
    |> Repo.get(time_slot_id)
    |> reserve_time_slot(user)
  end

  def reserve_time_slot(%Lab.TimeSlotModel{} = time_slot, %User{} = user) do
    # Disallow reservations for past time slots
    if DateTime.compare(time_slot.start_time, DateTime.now!("Etc/UTC")) == :lt do
      {:error, :time_slot_is_in_the_past}
    else
      # First cancel any existing reservations for the same lab
      cancel_reservations(time_slot.tool_id, user)

      %Lab.ReservationModel{}
      |> Lab.ReservationModel.changeset(%{status: :reserved, user_id: user.id, time_slot_id: time_slot.id})
      |> Repo.insert()
    end
  end

  def reservation_for_user(%Lab.ToolModel{} = tool, %User{} = user) do
    reservation_query(tool.id, user)
    |> Repo.one()
  end

  def cancel_reservation(%Lab.ToolModel{} = tool, %User{} = user) do
    cancel_reservations(tool.id, user)
  end

  defp cancel_reservations(tool_id, %User{} = user) when is_integer(tool_id) do
    query = reservation_query(tool_id, user)
    {update_count, _} = Repo.update_all(query, set: [status: :cancelled])

    unless update_count < 2 do
      throw(:more_than_one_reservation_should_not_happen)
    end
  end

  defp reservation_query(tool_id, %User{} = user) when is_integer(tool_id) do
    from(reservation in Lab.ReservationModel,
      join: time_slot in Lab.TimeSlotModel,
      on: [id: reservation.time_slot_id],
      join: tool in Lab.ToolModel,
      on: [id: time_slot.tool_id],
      where:
        reservation.user_id == ^user.id and tool.id == ^tool_id and
          reservation.status == :reserved
    )
  end
end
