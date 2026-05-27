# frozen_string_literal: true

LetterOpenerWeb::Engine.routes.draw do
  get  '/'                     => 'letters#index',    as: :letters
  post 'clear'                 => 'letters#clear',    as: :clear_letters
  get  ':id(/:style)'          => 'letters#show',     as: :letter
  post ':id/delete'            => 'letters#destroy',  as: :delete_letter
  get  ':id/attachments/:file' => 'letters#attachment', constraints: { file: %r{[^/]+} }
end
