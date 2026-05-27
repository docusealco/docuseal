# frozen_string_literal: true

Capybara::SpecHelper.spec '#has_element?' do
  before do
    @session.visit('/with_html')
  end

  it 'should be true if the given element is on the page' do
    expect(@session).to have_element('a', id: 'foo')
    expect(@session).to have_element('a', text: 'A link', href: '/with_simple_html')
    expect(@session).to have_element('a', text: :'A link', href: :'/with_simple_html')
    expect(@session).to have_element('a', text: 'A link', href: %r{/with_simple_html})
    expect(@session).to have_element('a', text: 'labore', target: '_self')
  end

  it 'should be false if the given element is not on the page' do
    expect(@session).not_to have_element('a', text: 'monkey')
    expect(@session).not_to have_element('a', text: 'A link', href: '/nonexistent-href')
    expect(@session).not_to have_element('a', text: 'A link', href: /nonexistent/)
    expect(@session).not_to have_element('a', text: 'labore', target: '_blank')
  end

  it 'should notify if an invalid locator is specified' do
    allow(Capybara::Helpers).to receive(:warn).and_return(nil)
    @session.has_element?(@session)
    expect(Capybara::Helpers).to have_received(:warn).with(/Called from: .+/)
  end
end

Capybara::SpecHelper.spec '#has_no_element?' do
  before do
    @session.visit('/with_html')
  end

  it 'should be false if the given element is on the page' do
    expect(@session).not_to have_no_element('a', id: 'foo')
    expect(@session).not_to have_no_element('a', text: 'A link', href: '/with_simple_html')
    expect(@session).not_to have_no_element('a', text: 'labore', target: '_self')
  end

  it 'should be true if the given element is not on the page' do
    expect(@session).to have_no_element('a', text: 'monkey')
    expect(@session).to have_no_element('a', text: 'A link', href: '/nonexistent-href')
    expect(@session).to have_no_element('a', text: 'A link', href: %r{/nonexistent-href})
    expect(@session).to have_no_element('a', text: 'labore', target: '_blank')
  end
end
