# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

module TwitterCldr
  module Resources

    module Requirements
      autoload :CldrRequirement,       'twitter_cldr/resources/requirements/cldr_requirement'
      autoload :IcuRequirement,        'twitter_cldr/resources/requirements/icu_requirement'
      autoload :DependencyRequirement, 'twitter_cldr/resources/requirements/dependency_requirement'
      autoload :EmojiRequirement,      'twitter_cldr/resources/requirements/emoji_requirement'
      autoload :GitRequirement,        'twitter_cldr/resources/requirements/git_requirement'
      autoload :PomManager,            'twitter_cldr/resources/requirements/pom_manager'
      autoload :UcaRequirement,        'twitter_cldr/resources/requirements/uca_requirement'
      autoload :UnicodeRequirement,    'twitter_cldr/resources/requirements/unicode_requirement'
    end

  end
end
