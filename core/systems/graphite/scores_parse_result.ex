defmodule Systems.Graphite.ScoresParseResult do
  alias __MODULE__, as: Result
  alias Systems.Graphite

  @base_fields ["submission", "github_commit_url"]

  defstruct [:csv, :duplicate_count, :rejected, :valid]

  def from_file(local_path, leaderboard) do
    lines =
      local_path
      |> File.stream!()
      |> CSV.decode(headers: true)

    from_lines(lines, leaderboard)
  end

  def from_lines(lines, leaderboard) do
    submission_map =
      Graphite.Public.get_submissions(leaderboard.tool)
      |> Enum.reduce(%{}, fn submission, acc ->
        Map.put(acc, submission.id, submission.github_commit_url)
      end)

    records =
      lines
      |> to_records()
      |> Stream.map(fn record -> check_fields(record, leaderboard.metrics, :missing_metric) end)
      |> Stream.map(fn record -> check_fields(record, @base_fields, :missing_base_field) end)
      |> Stream.map(fn record -> convert_ints(record, ["submission"]) end)
      |> Stream.map(fn record -> convert_floats(record, leaderboard.metrics) end)
      |> Stream.map(fn record -> check_submission(record, submission_map) end)
      |> Enum.map(fn record -> check_github_url(record, submission_map) end)

    {valid, rejected} =
      Enum.split_with(records, fn
        {_, _, []} -> true
        {_, _, [_ | _]} -> false
      end)

    %Result{csv: lines, rejected: rejected, valid: valid}
  end

  defp to_records(lines) do
    lines
    |> Enum.with_index(1)
    |> Enum.map(&unpack/1)
  end

  defp unpack({{:ok, line}, line_nr}), do: {line_nr, line, []}
  defp unpack({{:error, _}, line_nr}), do: {line_nr, nil, [:parse_error]}

  defp check_fields({_, nil, _} = record, _fields, _error), do: record

  defp check_fields({line_nr, line, errors} = record, fields, error) do
    if Enum.all?(fields, fn field -> Map.has_key?(line, field) end) do
      record
    else
      {line_nr, line, [error | errors]}
    end
  end

  defp check_submission({_, nil, _} = record, _submission_map), do: record

  defp check_submission({line_nr, line, errors}, submission_map) do
    if Map.has_key?(submission_map, line["submission"]) do
      submission = Map.get(submission_map, line["submission"])
      {line_nr, Map.put(line, "submission_record", submission), errors}
    else
      {line_nr, line, [:missing_submission | errors]}
    end
  end

  defp check_github_url({_, nil, _} = record, _submission_map), do: record

  defp check_github_url({_, _, [:missing_submission | _]} = record, _), do: record

  defp check_github_url({line_nr, line, errors} = record, submission_map) do
    if line["github_commit_url"] == submission_map[line["submission"]] do
      record
    else
      {line_nr, line, [:incorrect_url | errors]}
    end
  end

  def convert_ints({_, nil, _} = record), do: record

  def convert_ints({line_nr, line, errors}, fields) do
    updated =
      fields
      |> Enum.reduce(
        line,
        fn field, acc ->
          Map.update!(acc, field, fn value -> String.to_integer(value) end)
        end
      )

    {line_nr, updated, errors}
  end

  def convert_floats({_, nil, _} = record), do: record

  def convert_floats({line_nr, line, errors}, fields) do
    updated =
      fields
      |> Enum.reduce(
        line,
        fn field, acc ->
          Map.update!(acc, field, fn value -> String.to_float(value) end)
        end
      )

    {line_nr, updated, errors}
  end
end
