module Wait
  def wait_until seconds = 20, &condition
    Timeout.timeout(seconds) do
      until (result = condition.call)
        sleep 0.1
      end
      result
    end
  end
end
