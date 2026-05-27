Rails.application.routes.draw do
  get "recede_historical_location", to: "turbo/native/navigation#recede", as: :turbo_recede_historical_location
  get "resume_historical_location", to: "turbo/native/navigation#resume", as: :turbo_resume_historical_location
  get "refresh_historical_location", to: "turbo/native/navigation#refresh", as: :turbo_refresh_historical_location
end if Turbo.draw_routes
