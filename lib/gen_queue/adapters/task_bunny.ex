defmodule GenQueue.Adapters.TaskBunny do
  @moduledoc """
  An adapter for `GenQueue` to enable functionaility with `TaskBunny`.
  """

  @type job :: module | {module} | {module, any}
  @type pushed_job :: {module, list, map}

  use GenQueue.Adapter

  def start_link(_gen_queue, _opts) do
    TaskBunny.Supervisor.start_link()
  end

  @doc """
  Push a job for TaskBunny to consume.

  ## Parameters:
    * `gen_queue` - Any GenQueue module
    * `job` - Any valid job format
    * `opts` - A keyword list of job options

  ## Options
    * `:queue` - The queue to push the job to.
    * `:delay` - Either a `DateTime` or millseconds-based integer.

  ## Returns:
    * `{:ok, {module, args, opts}}` if the operation was successful
    * `{:error, reason}` if there was an error
  """
  def handle_push(_gen_queue, job, opts) when is_atom(job) do
    do_enqueue(job, %{}, build_opts_map(opts))
  end

  def handle_push(_gen_queue, {job}, opts) do
    do_enqueue(job, %{}, build_opts_map(opts))
  end

  def handle_push(_gen_queue, {job, arg}, opts) when is_map(arg) do
    do_enqueue(job, arg, build_opts_map(opts))
  end

  def handle_push(_gen_queue, {job, []}, opts) do
    do_enqueue(job, %{}, build_opts_map(opts))
  end

  def handle_push(_gen_queue, {job, [arg]}, opts) when is_map(arg) do
    do_enqueue(job, arg, build_opts_map(opts))
  end

  @doc false
  def handle_pop(_gen_queue, _opts) do
    {:error, :not_implemented}
  end

  @doc false
  def handle_flush(_gen_queue, _opts) do
    {:error, :not_implemented}
  end

  @doc false
  def handle_length(_gen_queue, _opts) do
    {:error, :not_implemented}
  end

  @doc false
  def build_opts_map(opts) do
    opts
    |> Enum.into(%{})
    |> case do
      %{delay: %DateTime{} = delay} = opts ->
        ms_delay = DateTime.diff(DateTime.utc_now(), delay, :millisecond)
        Map.put(opts, :delay, ms_delay)

      opts ->
        opts
    end
  end

  defp do_enqueue(job, arg, opts) do
    case TaskBunny.Job.enqueue(job, arg, Enum.into(opts, [])) do
      :ok -> {:ok, {job, [arg], opts}}
      error -> error
    end
  end
end
