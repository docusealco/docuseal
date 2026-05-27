# frozen_string_literal: true

module Faker
  class X < Base
    class << self
      ##
      # Produces a random X user based on X's v2 API.
      #
      # @return [Hash]
      #
      # @example
      #   Faker::X.user #=>  { data: [{:id=>"8821452687517076614", :name=>"Lincoln Paucek", :screen_name=>"cody"...
      #
      # @faker.version 1.7.3
      def user
        author_id = Faker::Number.between(from: 1, to: 9_223_372_036_854_775_807)

        {
          data: [
            {
              author_id: author_id.to_s,
              id: id.to_s,
              text: Faker::Lorem.sentence
            }
          ],
          includes: {
            users: [
              {
                public_metrics: {
                  followers_count: Faker::Number.between(to: 1, from: 1_000),
                  following_count: Faker::Number.between(to: 1, from: 200),
                  tweet_count: Faker::Number.between(to: 1, from: 10_000),
                  listed_count: Faker::Number.between(to: 1, from: 1_000)
                },
                username: screen_name,
                pinned_tweet_id: Faker::Number.between(from: 1, to: 9_223_372_036_854_775_807).to_s,
                entities: user_entities,
                description: Faker::Lorem.sentence,
                name: Faker::Name.name,
                verified: Faker::Boolean.boolean(true_ratio: 0.1),
                location: Faker::Internet.public_ip_v4_address,
                id: author_id.to_s,
                protected: Faker::Boolean.boolean(true_ratio: 0.1),
                url: url,
                profile_image_url: Faker::Avatar.image(slug: id, size: '48x48'),
                created_at: created_at
              }
            ]
          }
        }
      end

      ##
      # Produces a random X tweet with default attributes.
      #
      # @param include_user [Boolean] Include user details
      # @param include_media [Boolean] Include user media (photo) details
      # @return [Hash]
      #
      # @example
      #   Faker::X.tweet #=> { data: [{:id=>"8821452687517076614", :text=>"Ea et laboriosam vel non."...
      #   Faker::X.tweet(include_media: true) # Get a tweet object with a photo media attachment
      #   Faker::X.tweet(include_user: true) # Get a tweet object with an user details
      #
      # @faker.version 1.7.3
      def tweet(include_media: false, include_user: false)
        tweet = {}
        tweet_object = tweet_item
        includes = {}

        if include_media
          media_key = Faker::Number.between(from: 1, to: 9_223_372_036_854_775_807).to_s

          includes[:media] = media(media_key)
          tweet_object[:attachments] = { media_keys: [media_key] }
        end

        includes[:users] = user[:includes][:users] if include_user

        tweet[:data] = [
          tweet_object
        ]

        unless includes.empty?
          tweet[:includes] = includes
        end

        tweet
      end

      ##
      # Produces a random screen_name.
      #
      # @return [String]
      #
      # @example
      #   Faker::X.screen_name #=> "audreanne_hackett"
      #
      # @faker.version 1.7.3
      def screen_name
        Faker::Internet.username(specifier: nil, separators: ['_'])[0...20]
      end

      private

      def id
        Faker::Number.between(from: 1, to: 9_223_372_036_854_775_807)
      end

      def created_at
        Faker::Date.between(from: '2006-03-21', to: ::Date.today).to_time.utc.iso8601(3)
      end

      def url
        "https://t.co/#{Faker::Lorem.characters(number: 10)}"
      end

      def user_entities
        entities = tweet_entities

        {
          url: {
            urls: entities[:urls]
          },
          description: {
            hashtags: entities[:hashtags]
          }
        }
      end

      def tweet_entities
        display_url = Faker::Internet.url(host: 'example.com')

        {
          urls: [
            {
              start: 0,
              end: 5,
              url: url,
              expanded_url: display_url,
              display_url: display_url.sub('http://', '')
            }
          ],
          hashtags: [
            {
              start: 0,
              end: 5,
              tag: Faker::Lorem.word.capitalize
            }
          ]
        }
      end

      def media(media_key)
        expanded_url = Faker::LoremFlickr.image(size: '1064x600')

        [{
          height: Faker::Number.between(to: 1, from: 1000),
          media_key: media_key,
          type: 'photo',
          preview_image_url: expanded_url,
          width: Faker::Number.between(to: 1, from: 2000),
          alt_text: Faker::Lorem.sentence
        }]
      end

      def tweet_item
        conversation_id = id.to_s

        {
          id: conversation_id,
          text: Faker::Lorem.sentence,
          lang: sample(%w[en fr es pt it ja]),
          conversation_id: conversation_id,
          created_at: created_at,
          author_id: Faker::Number.between(from: 1, to: 9_223_372_036_854_775_807).to_s,
          public_metrics: {
            retweet_count: Faker::Number.between(to: 1, from: 100),
            reply_count: Faker::Number.between(to: 1, from: 20),
            like_count: Faker::Number.between(to: 1, from: 25),
            quote_count: Faker::Number.between(to: 1, from: 10)
          },
          possibly_sensitive: Faker::Boolean.boolean(true_ratio: 0.1),
          entities: tweet_entities
        }
      end
    end
  end
end
