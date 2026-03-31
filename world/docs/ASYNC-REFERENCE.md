# Async & Async::Service Reference

Quick reference for the concurrency primitives used in the Synthetic runtime.
Sources: [async tasks guide](https://socketry.github.io/async/guides/tasks/index.html) and [async-service getting started](https://socketry.github.io/async-service/guides/getting-started/index.html).

---

## Tasks

Tasks are the fundamental unit of sequential execution. They form a parent-child tree — cancelling a parent cancels all its children.

### Spawning tasks

```ruby
# Inline / blocking
Async do
  sleep(1)
  puts "done"
end

# Concurrent — each iteration runs in parallel
Async do
  jobs.each do |job|
    Async { process(job) }
  end
end
```

### Waiting for a task's result

```ruby
task = Async { expensive_work }
result = task.wait   # blocks until done, re-raises if failed
```

### Exceptions

Unhandled exceptions put a task into `:failed` state. Calling `wait` re-raises:

```ruby
task = Async { raise "Boom" }
task.status  # => :failed
task.wait    # raises RuntimeError "Boom"
```

---

## Barrier — waiting for a group of tasks

`Async::Barrier` coordinates a collection of tasks. Call `barrier.wait` to block until all finish; call `barrier.cancel` to stop them all.

```ruby
barrier = Async::Barrier.new

barrier.async { process(job_a) }
barrier.async { process(job_b) }

barrier.wait
```

Always cancel in `ensure` to avoid leaks if one task raises:

```ruby
barrier = Async::Barrier.new

begin
  jobs.each { |j| barrier.async { process(j) } }
  barrier.wait
ensure
  barrier.cancel
end
```

### Waiting for the first N completions

Combine `Barrier` with the block form of `wait` to stop early once enough results are in:

```ruby
barrier = Async::Barrier.new

begin
  jobs.each { |j| barrier.async { process(j) } }

  done = []
  barrier.wait do |task|
    done << task.wait
    break if done.size >= 2   # stop after 2 tasks complete
  end
ensure
  barrier.cancel              # cancel remaining tasks
end
```

---

## Semaphore — capping concurrency

`Async::Semaphore.new(n)` lets at most `n` tasks run concurrently. Excess tasks yield until a slot is free.

```ruby
semaphore = Async::Semaphore.new(2)

jobs.each do |job|
  semaphore.async { process(job) }
end
```

### Barrier + Semaphore together

Pass the barrier as the semaphore's parent so tasks are also tracked for bulk wait/cancel:

```ruby
barrier  = Async::Barrier.new
semaphore = Async::Semaphore.new(2, parent: barrier)

begin
  jobs.each { |j| semaphore.async { process(j) } }
  barrier.wait
ensure
  barrier.cancel
end
```

This is the pattern used for Synthetic tool concurrency: the Synthetic's semaphore caps its own cycle share, and Tools are nested inside a further semaphore carved from that budget.

---

## Cancellation

```ruby
# Cancel one task
task = Async { long_running }
task.cancel

# Cancel all tasks in a barrier
barrier.cancel
```

---

## Timeouts

```ruby
Async do |task|
  task.with_timeout(5) do
    slow_api_call
  rescue Async::TimeoutError
    handle_timeout
  end
end
```

---

## Transient tasks

Mark background housekeeping tasks as `transient: true`. They do not keep the reactor alive and are cancelled automatically when all non-transient tasks complete:

```ruby
@heartbeat = Async(transient: true) do
  loop do
    sleep(30)
    ping_hub
  end
end
```

---

## Async::Service

`async-service` supervises long-running services as a group. The `world/` process is an async-service configuration file.

### Defining a service

```ruby
class SyntheticService < Async::Service::Generic
  def setup(container)
    super

    container.run(count: 1, restart: true) do |instance|
      instance.ready!
      # Synthetic event loop runs here
    end
  end
end
```

`restart: true` — the container restarts the service automatically on crash.
`count: 1` — one instance per service declaration (can be raised for stateless workers).

### Custom properties

Configuration blocks can pass arbitrary values to the service class:

```ruby
service "sid-security-consultant" do
  service_class SyntheticService
  synthetic_id  17
  archetype     "SecurityConsultant"
end
```

Read them inside `setup`:

```ruby
evaluator = self.environment.evaluator
id        = evaluator.synthetic_id
archetype = evaluator.archetype
```

### The service file

The `world/service.rb` entry point is an executable async-service config:

```ruby
#!/usr/bin/env async-service

service "sid-security-consultant" do
  service_class SyntheticService
  synthetic_id  17
  archetype     "SecurityConsultant"
end

service "alice-analyst" do
  service_class SyntheticService
  synthetic_id  42
  archetype     "DataAnalyst"
end
```

Adding a Synthetic to the organisation = adding a `service` block here.

### Running programmatically (e.g. in specs)

```ruby
configuration = Async::Service::Configuration.build do
  service "test-synthetic" do
    service_class SyntheticService
    synthetic_id  99
    archetype     "TestArchetype"
  end
end

Async::Service::Controller.run(configuration)
```

---

## How these fit together in the Synthetic runtime

```
async-service process  (world/service.rb)
  └── Controller manages N services, one per Synthetic
        └── SyntheticService#setup calls container.run(restart: true)
              └── event loop fiber (Async::Task)
                    ├── Semaphore caps this Synthetic's cycle share
                    └── barrier + semaphore for concurrent Tool spawning
```

Key implications:
- **Semaphore on the Synthetic** — limits cycles consumed by one agent; many Synthetics share the container fairly
- **Nested semaphore for Tools** — carving from the Synthetic's own budget means spawning many Tools degrades the Synthetic's responsiveness (emergent disincentive, not enforced by Governor)
- **`restart: true`** — a crashing Synthetic is automatically restarted without affecting siblings
- **`transient: true`** — use for heartbeat / health-check fibers that shouldn't block shutdown
