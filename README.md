# Fal

## Installation

Install the gem and add to the application"s Gemfile by executing:

    $ bundle add fal

If bundler is not being used to manage dependencies, install the gem by executing:

    $ gem install fal

## Usage

### Configuration

Configure the client once at boot (e.g., in Rails an initializer) using `Fal.configure`.

```ruby
Fal.configure do |config|
  config.api_key = "your-key" # Optional. Defaults to ENV["FAL_KEY"] if not set.
  config.queue_base = "https://queue.fal.run" # Optional (default: https://queue.fal.run)
  config.sync_base = "https://fal.run" # Optional (default: https://fal.run)
  config.request_timeout = 120 # Optional (default: 120)
end
```

### Create a queued request

The Queue API is the recommended way to call models on fal. Provide a `model_id` in "namespace/name" format and an input payload.

```ruby
model_id = "fal-ai/fast-sdxl"

request = Fal::Request.create!(
  model_id: model_id,
  input: { prompt: "a cat" }
)

request.id       # => request_id from fal
request.status   # => "IN_QUEUE" | "IN_PROGRESS" | "COMPLETED"
```

You can also specify a webhook URL to be notified when the request is finished.

```ruby
request = Fal::Request.create!(
  model_id: model_id,
  input: { prompt: "a cat playing piano" },
  webhook_url: "https://example.com/fal/webhook"
)
```

### Get request status (find and reload)

Fetch the current status by id:

```ruby
status = Fal::Request.find_by!(id: request.id, model_id: model_id)
status.in_queue?      # => true/false
status.in_progress?   # => true/false
status.completed?     # => true/false
```

Reload an instance in-place, optionally including logs.

```ruby
request.reload!           # refreshes state
request.reload!(logs: true)
request.logs              # => array of log entries (if provided by model and logs=1)
# When status is COMPLETED, reload! will also fetch and set request.response
```

Status constants are available for direct comparisons:

```ruby
Fal::Request::Status::IN_QUEUE
Fal::Request::Status::IN_PROGRESS
Fal::Request::Status::COMPLETED
```

### Fetch the response payload after completion

Call `reload!` to populate `request.response`:

```ruby
# poll until completed
until request.completed?
  request.reload!
  sleep 1
end

request.response   # => model-specific response body
```

### Cancel a request

Requests that are still in the queue can be cancelled:

```ruby
request.cancel! # => { "status" => "CANCELLATION_REQUESTED" }
```

### Error handling

HTTP and API errors raise typed exceptions:

- `Fal::UnauthorizedError` (401)
- `Fal::ForbiddenError` (403)
- `Fal::NotFoundError` (404)
- `Fal::ServerError` (other non-success)

Rescue them as needed:

```ruby
begin
  Fal::Request.create!(model_id: model_id, input: { prompt: "hi" })
rescue Fal::UnauthorizedError
  # handle invalid/missing FAL_KEY
end
```

### Stream synchronous responses

Use `stream!` for SSE streaming from synchronous endpoints. It yields each chunk’s data Hash and returns a `Fal::Request` whose `response` contains the last chunk’s payload.

```ruby
model_id = "fal-ai/flux/dev"

last = Fal::Request.stream!(model_id: model_id, input: { prompt: "a cat" }) do |chunk|
  # chunk is a Hash, e.g. { images: [...] }
  puts chunk
end

last.completed?    # => true/false
last.response      # => last streamed data hash (e.g., { "response" => { ... } } or final payload)
```

### Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to rubygems.org.

For local development, copy the example environment file and set your API key so `bin/console` can load it automatically:

```
cp .env.example .env
echo 'FAL_KEY=your_api_key_here' >> .env
```

The console uses dotenv to load `.env`, so `Fal.configure` will default to `ENV["FAL_KEY"]`.
