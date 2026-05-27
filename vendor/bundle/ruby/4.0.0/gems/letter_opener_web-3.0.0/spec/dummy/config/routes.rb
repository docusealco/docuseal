# frozen_string_literal: true

Rails.application.routes.draw do
  mount LetterOpenerWeb::Engine => '/letter_opener_web'
end
