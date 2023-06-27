defmodule Systems.Student.Presenter do
  use Systems.Presenter

  alias Systems.{
    Student,
    Pool
  }

  @impl true
  def view_model(id, Pool.SubmissionPage = page, assigns) when is_integer(id) do
    Pool.Public.get_submission!(id, pool: Pool.Model.preload_graph([:org, :currency]))
    |> view_model(page, assigns)
  end

  @impl true
  def view_model(%Pool.SubmissionModel{} = submission, Pool.SubmissionPage, assigns) do
    Student.Pool.SubmissionPageBuilder.view_model(submission, assigns)
  end

  @impl true
  def view_model(id, Pool.DetailPage, assigns) do
    pool = Pool.Public.get!(id, Pool.Model.preload_graph([:org, :currency, :participants]))
    Student.Pool.DetailPageBuilder.view_model(pool, assigns)
  end
end
