# frozen_string_literal: true

Rack::Request.forwarded_priority = %i[x_forwarded]
