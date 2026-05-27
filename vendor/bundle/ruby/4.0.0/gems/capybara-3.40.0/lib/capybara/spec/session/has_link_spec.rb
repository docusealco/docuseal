# frozen_string_literal: true

Capybara::SpecHelper.spec '#has_link?' do
  before do
    @session.visit('/with_html')
  end

  it 'should be true if the given link is on the page' do
    expect(@session).to have_link('foo')
    expect(@session).to have_link('awesome title')
    expect(@session).to have_link('A link', href: '/with_simple_html')
    expect(@session).to have_link(:'A link', href: :'/with_simple_html')
    expect(@session).to have_link('A link', href: %r{/with_simple_html})
    expect(@session).to have_link('labore', target: '_self')
  end

  it 'should be false if the given link is not on the page' do
    expect(@session).not_to have_link('monkey')
    expect(@session).not_to have_link('A link', href: '/nonexistent-href')
    expect(@session).not_to have_link('A link', href: /nonexistent/)
    expect(@session).not_to have_link('labore', target: '_blank')
  end

  it 'should notify if an invalid locator is specified' do
    allow(Capybara::Helpers).to receive(:warn).and_return(nil)
    @session.has_link?(@session)
    expect(Capybara::Helpers).to have_received(:warn).with(/Called from: .+/)
  end

  context 'with focused:', requires: [:active_element] do
    it 'should be true if the given link is on the page and has focus' do
      @session.send_keys(:tab)

      expect(@session).to have_link('labore', focused: true)
    end

    it 'should be false if the given link is on the page and does not have focus' do
      expect(@session).to have_link('labore', focused: false)
    end
  end

  it 'should raise an error if an invalid option is passed' do
    expect do
      expect(@session).to have_link('labore', invalid: true)
    end.to raise_error(ArgumentError, 'Invalid option(s) :invalid, should be one of :above, :below, :left_of, :right_of, :near, :count, :minimum, :maximum, :between, :text, :id, :class, :style, :visible, :obscured, :exact, :exact_text, :normalize_ws, :match, :wait, :filter_set, :focused, :href, :alt, :title, :target, :download')
  end
end

Capybara::SpecHelper.spec '#has_no_link?' do
  before do
    @session.visit('/with_html')
  end

  it 'should be false if the given link is on the page' do
    expect(@session).not_to have_no_link('foo')
    expect(@session).not_to have_no_link('awesome title')
    expect(@session).not_to have_no_link('A link', href: '/with_simple_html')
    expect(@session).not_to have_no_link('labore', target: '_self')
  end

  it 'should be true if the given link is not on the page' do
    expect(@session).to have_no_link('monkey')
    expect(@session).to have_no_link('A link', href: '/nonexistent-href')
    expect(@session).to have_no_link('A link', href: %r{/nonexistent-href})
    expect(@session).to have_no_link('labore', target: '_blank')
  end

  context 'with focused:', requires: [:active_element] do
    it 'should be true if the given link is on the page and has focus' do
      expect(@session).to have_no_link('labore', focused: true)
    end

    it 'should be false if the given link is on the page and does not have focus' do
      @session.send_keys(:tab)

      expect(@session).to have_no_link('labore', focused: false)
    end
  end
end
