# GenQueue TaskBunny
[![Build Status](https://travis-ci.org/nsweeting/gen_queue_task_bunny.svg?branch=master)](https://travis-ci.org/nsweeting/gen_queue_task_bunny)
[![GenQueue Exq Version](https://img.shields.io/hexpm/v/gen_queue_task_bunny.svg)](https://hex.pm/packages/gen_queue_task_bunny)

This is an adapter for [GenQueue](https://github.com/nsweeting/gen_queue) to enable
functionaility with [TaskBunny](https://github.com/shinyscorpion/task_bunny).

## Installation

The package can be installed by adding `gen_queue_task_bunny` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:gen_queue_task_bunny, "~> 0.1.1"}
  ]
end
```

## Documentation

See [HexDocs](https://hexdocs.pm/gen_queue_task_bunny) for additional documentation.

## Configuration

Before starting, please refer to the [TaskBunny](https://github.com/shinyscorpion/task_bunny) documentation
for details on configuration. This adapter handles zero `TaskBunny` related config.

## Creating Enqueuers

We can start off by creating a new `GenQueue` module, which we will use to push jobs to
`TaskBunny`.

```elixir
defmodule Enqueuer do
  use GenQueue, otp_app: :my_app
end
```

Once we have our module setup, ensure we have our config pointing to the `GenQueue.Adapters.TaskBunny`
adapter.

```elixir
config :my_app, Enqueuer, [
  adapter: GenQueue.Adapters.TaskBunny
]
```

## Starting Enqueuers

By default, `gen_queue_task_bunny` does not start TaskBunny on application start. So we must add
our new `Enqueuer` module to our supervision tree.

```elixir
  children = [
    supervisor(Enqueuer, []),
  ]
```

## Creating Jobs

Jobs are simply modules with a `perform` method. With `TaskBunny` we must add `use TaskBunny.Job`
to our jobs.

```elixir
defmodule MyJob do
  use TaskBunny.Job

  def perform(arg1) do
    IO.inspect(arg1)
  end
end
```

## Enqueuing Jobs

We can now easily enqueue jobs to `TaskBunny`. The adapter will handle a variety of argument formats.

```elixir
# Please note that zero-arg jobs default to using %{}, as per TaskBunny requirements.

# Push MyJob to your default queue with %{} arg.
{:ok, job} = Enqueuer.push(MyJob)

# Push MyJob to your default queue  with %{} arg.
{:ok, job} = Enqueuer.push({MyJob})

# Push MyJob to your default queue with %{"foo" => "bar"} arg.
{:ok, job} = Enqueuer.push({MyJob, %{"foo" => "bar"}})

# Push MyJob to "default" queue with %{} arg.
{:ok, job} = Enqueuer.push({MyJob, []})

# Push MyJob to "default" queue with %{"foo" => "bar"} arg.
{:ok, job} = Enqueuer.push({MyJob, [%{"foo" => "bar"}]})

# Push MyJob to "foo" queue with %{"foo" => "bar"} arg
{:ok, job} = Enqueuer.push({MyJob, %{"foo" => "bar"}}, [queue: "foo"])

# Schedule MyJob to your default queue with %{"foo" => "bar"} arg in 10 seconds
{:ok, job} = Enqueuer.push({MyJob, %{"foo" => "bar"}}, [delay: 10_000])

# Schedule MyJob to your default queue with %{"foo" => "bar"} arg at a specific time
date = DateTime.utc_now()
{:ok, job} = Enqueuer.push({MyJob, %{"foo" => "bar"}}, [delay: date])
```

## Testing

Optionally, we can also have our tests use the `GenQueue.Adapters.MockJob` adapter.

```elixir
config :my_app, Enqueuer, [
  adapter: GenQueue.Adapters.MockJob
]
```

This mock adapter uses the standard `GenQueue.Test` helpers to send the job payload
back to the current processes mailbox (or another named process) instead of actually
enqueuing the job to rabbitmq.

```elixir
defmodule MyJobTest do
  use ExUnit.Case, async: true

  import GenQueue.Test

  setup do
    setup_test_queue(Enqueuer)
  end

  test "my enqueuer works" do
    {:ok, _} = Enqueuer.push(Job)
    assert_receive(%GenQueue.Job{module: Job, args: []})
  end
end
```

If your jobs are being enqueued outside of the current process, we can use named
processes to recieve the job. This wont be async safe.

```elixir
import GenQueue.Test

setup do
  setup_global_test_queue(Enqueuer, :my_process_name)
end
```
