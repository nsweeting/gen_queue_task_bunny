defmodule GenQueue.Adapters.TaskBunnyMockTest do
  use ExUnit.Case

  import GenQueue.Test

  defmodule Enqueuer do
    Application.put_env(:gen_queue_task_bunny, __MODULE__, adapter: GenQueue.Adapters.TaskBunnyMock)

    use GenQueue, otp_app: :gen_queue_task_bunny
  end

  setup do
    setup_test_queue(Enqueuer)
  end

  describe "push/2" do
    test "sends the job back to the registered process from module" do
      {:ok, _} = Enqueuer.push(Job)
      assert_receive({Job, [%{}], %{}})
    end

    test "sends the job back to the registered process from module tuple" do
      {:ok, _} = Enqueuer.push({Job})
      assert_receive({Job, [%{}], %{}})
    end

    test "sends the job back to the registered process from module and map arg" do
      {:ok, _} = Enqueuer.push({Job, %{"foo" => "bar"}})
      assert_receive({Job, [%{"foo" => "bar"}], %{}})
    end

    test "sends the job back to the registered process from module and empty list arg" do
      {:ok, _} = Enqueuer.push({Job, []})
      assert_receive({Job, [%{}], %{}})
    end

    test "sends the job back to the registered process from module and list arg" do
      {:ok, _} = Enqueuer.push({Job, [%{"foo" => "bar"}]})
      assert_receive({Job, [%{"foo" => "bar"}], %{}})
    end

    test "sends the job back to the registered process with millisecond delay" do
      {:ok, _} = Enqueuer.push({Job, []}, delay: 0)
      assert_receive({Job, [%{}], %{delay: _}})
    end

    test "sends the job back to the registered process with datetime delay" do
      {:ok, _} = Enqueuer.push({Job, [%{}]}, delay: DateTime.utc_now())
      assert_receive({Job, [%{}], %{delay: _}})
    end

    test "does nothing if process is not registered" do
      reset_test_queue(Enqueuer)
      {:ok, _} = Enqueuer.push(Job)
    end
  end
end
