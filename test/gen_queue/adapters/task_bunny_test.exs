defmodule GenQueue.Adapters.TaskBunnyTest do
  use ExUnit.Case

  import GenQueue.Test
  import GenQueue.TaskBunnyTestHelpers

  Application.put_env(:task_bunny, :hosts, [
    default: [connect_options: "amqp://localhost"]
  ])

  Application.put_env(:task_bunny, :queue, [
    namespace: "task_bunny.",
    queues: [[name: "normal", jobs: :default]]
  ])

  defmodule Enqueuer do
    Application.put_env(:gen_queue_task_bunny, __MODULE__, adapter: GenQueue.Adapters.TaskBunny)

    use GenQueue, otp_app: :gen_queue_task_bunny
  end

  defmodule Job do
    use TaskBunny.Job

    def perform(arg1) do
      send_item(Enqueuer, {:performed, arg1})
      :ok
    end
  end

  setup do
    setup_global_test_queue(Enqueuer, :test)
  end

  describe "push/2" do
    test "enqueues and runs job from module" do
      {:ok, pid} = Enqueuer.start_link()
      {:ok, job} = Enqueuer.push(Job)
      assert_receive({:performed, %{}})
      assert %GenQueue.Job{module: Job, args: [%{}]} = job
      stop_process(pid)
    end

    test "enqueues and runs job from module tuple" do
      {:ok, pid} = Enqueuer.start_link()
      {:ok, job} = Enqueuer.push({Job})
      assert_receive({:performed, %{}})
      assert %GenQueue.Job{module: Job, args: [%{}]} = job
      stop_process(pid)
    end

    test "enqueues and runs job from module and args" do
      {:ok, pid} = Enqueuer.start_link()
      {:ok, job} = Enqueuer.push({Job, [%{"foo" => "bar"}]})
      assert_receive({:performed, %{"foo" => "bar"}})
      assert %GenQueue.Job{module: Job, args: [%{"foo" => "bar"}]} = job
      stop_process(pid)
    end

    test "enqueues and runs job from module and single arg" do
      {:ok, pid} = Enqueuer.start_link()
      {:ok, job} = Enqueuer.push({Job, %{"foo" => "bar"}})
      assert_receive({:performed, %{"foo" => "bar"}})
      assert %GenQueue.Job{module: Job, args: [%{"foo" => "bar"}]} = job
      stop_process(pid)
    end

    test "enqueues a job with millisecond based delay" do
      {:ok, pid} = Enqueuer.start_link()
      {:ok, job} = Enqueuer.push({Job, []}, delay: 0)
      assert_receive({:performed, %{}})
      assert %GenQueue.Job{module: Job, args: [%{}], delay: 0} = job
      stop_process(pid)
    end

    test "enqueues a job with datetime based delay" do
      {:ok, pid} = Enqueuer.start_link()
      {:ok, job} = Enqueuer.push({Job, []}, delay: DateTime.utc_now())
      assert_receive({:performed, %{}})
      assert %GenQueue.Job{module: Job, args: [%{}], delay: %DateTime{}} = job
      stop_process(pid)
    end
  end
end
