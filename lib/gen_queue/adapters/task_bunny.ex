defmodule GenQueue.Adapters.TaskBunny do
  @moduledoc """
  An adapter for `GenQueue` to enable functionaility with `TaskBunny`.
  """

  use GenQueue.JobAdapter

  def start_link(_gen_queue, _opts) do
    TaskBunny.Supervisor.start_link()
  end

  @doc """
  Push a `GenQueue.Job` for `TaskBunny` to consume.

  ## Parameters:
    * `gen_queue` - A `GenQueue` module
    * `job` - A `GenQueue.Job`

  ## Returns:
    * `{:ok, job}` if the operation was successful
    * `{:error, reason}` if there was an error
  """
  @spec handle_job(gen_queue :: GenQueue.t(), job :: GenQueue.Job.t()) ::
          {:ok, GenQueue.Job.t()} | {:error, any}
  def handle_job(gen_queue, %GenQueue.Job{args: []} = job) do
    handle_job(gen_queue, %{job | args: [%{}]})
  end

  def handle_job(gen_queue, %GenQueue.Job{args: [arg]} = job) do
    case TaskBunny.Job.enqueue(job.module, arg, build_options(job)) do
      :ok -> {:ok, job}
      error -> error
    end
  end

  defp build_options(%GenQueue.Job{queue: queue, delay: %DateTime{} = delay}) do
    ms_delay = DateTime.diff(DateTime.utc_now(), delay, :millisecond)
    [queue: queue, delay: delay]
  end

  defp build_options(%GenQueue.Job{queue: queue, delay: delay}) when is_integer(delay) do
    [queue: queue, delay: delay]
  end

  defp build_options(%GenQueue.Job{queue: queue}) do
    [queue: queue]
  end
end
