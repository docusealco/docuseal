# frozen_string_literal: true

RSpec.describe LetterOpenerWeb::Letter do
  let(:location) { Pathname.new(__dir__).join('..', '..', 'tmp').cleanpath }

  def rich_text(mail_id)
    <<~MAIL
      Rich text for #{mail_id}
      <!DOCTYPE html>
      <body>
        <div id="container">
          <div id="message_headers">
            <dl>
              <dt>From:</dt>
              <dd>noreply@example.com</dd>
            </dl>
          </div>

          <a href='a-link.html'>
            <img src='an-image.jpg'>
            Link text
          </a>
          <a href='fooo.html'>Bar</a>
          <a href="example.html" class="blank"></a>
          <address><a href="inside-address.html">inside address</a></address>
        </div>
      </body>
    MAIL
  end

  before :each do
    LetterOpenerWeb.configure { |config| config.letters_location = location }

    %w[1111_1111 2222_2222].each do |folder|
      FileUtils.mkdir_p("#{location}/#{folder}")
      File.write("#{location}/#{folder}/plain.html", "Plain text for #{folder}")
      File.write("#{location}/#{folder}/rich.html", rich_text(folder))
      FileUtils.mkdir_p("#{Rails.root.join('tmp', 'letter_opener')}/#{folder}")
      File.write("#{Rails.root.join('tmp', 'letter_opener')}/#{folder}/rich.html", "Rich text for #{folder}")
    end
  end

  after :each do
    LetterOpenerWeb.reset!
    FileUtils.rm_rf(location)
  end

  describe 'rich text headers' do
    let(:id) { '1111_1111' }
    subject { described_class.new(id: id).headers }

    before do
      FileUtils.rm_rf("#{location}/#{id}/plain.html")
    end

    it { is_expected.to match(%r{<dl>\s*<dt>From:</dt>\s*<dd>noreply@example\.com</dd>}m) }
  end

  describe 'plain text headers' do
    let(:id) { '1111_1111' }
    subject { described_class.new(id: id).headers }

    before do
      FileUtils.rm_rf("#{location}/#{id}/rich.html")
    end

    it { is_expected.to eq('UNABLE TO PARSE HEADERS') }
  end

  describe 'rich text version' do
    let(:id) { '1111_1111' }
    subject { described_class.new(id: id).rich_text }

    it { is_expected.to match(/Rich text for 1111_1111/) }

    it 'changes links to show up on a new window' do
      link_html = [
        "<a href='a-link.html' target='_blank'>",
        "  <img src='an-image.jpg'/>",
        '  Link text',
        '</a>'
      ].join("\n    ")

      expect(subject).to include(link_html)
    end

    it 'always rewrites links with a closing tag rather than making them selfclosing' do
      expect(subject).to include("<a class='blank' href='example.html' target='_blank'></a>")
    end
  end

  describe 'plain text version' do
    let(:id) { '2222_2222' }
    subject { described_class.new(id: id).plain_text }

    it { is_expected.to match(/Plain text for 2222_2222/) }
  end

  describe 'default style' do
    let(:id) { '2222_2222' }
    subject { described_class.new(id: id) }

    it 'returns rich if rich text version is present' do
      expect(subject.default_style).to eq('rich')
    end

    it 'returns plain if rich text version is not present' do
      allow(File).to receive_messages(exist?: false)
      expect(subject.default_style).to eq('plain')
    end
  end

  describe 'attachments' do
    let(:file)            { 'an-image.csv' }
    let(:attachments_dir) { "#{location}/#{id}/attachments" }
    let(:id)              { '1111_1111' }

    subject { described_class.new(id: id) }

    before do
      FileUtils.mkdir_p(attachments_dir)
      File.open("#{attachments_dir}/#{file}", 'w') { |f| f.puts 'csv,contents' }
    end

    it 'builds a hash with file name as key and full path as value' do
      expect(subject.attachments).to eq(file => "#{attachments_dir}/#{file}")
    end
  end

  describe '.search' do
    let(:search_results) { described_class.search }
    let(:first_letter)   { search_results.first }
    let(:last_letter)    { search_results.last }

    before do
      allow(File).to receive(:mtime).with("#{location}/1111_1111").and_return(Date.today - 1.day)
      allow(File).to receive(:mtime).with("#{location}/2222_2222").and_return(Date.today)
    end

    it 'returns a list of ordered letters' do
      expect(first_letter.sent_at).to be > last_letter.sent_at
    end
  end

  describe '.find' do
    let(:id)     { 'an-id' }
    let(:letter) { described_class.find(id) }

    it 'returns a letter with id set' do
      expect(letter.id).to eq(id)
    end
  end

  describe '.destroy_all' do
    it 'removes all letters' do
      described_class.destroy_all
      expect(Dir["#{location}/**/*"]).to be_empty
    end
  end

  describe '#delete' do
    let(:id) { '1111_1111' }

    subject { described_class.new(id: id).delete }

    it 'removes the letter with given id' do
      subject
      directories = Dir["#{location}/*"]
      expect(directories.count).to eql(1)
      expect(directories.first).not_to match(id)
    end

    context 'when the id is outside of the letters base path' do
      let(:id) { '../3333_3333' }

      it 'does not remove the letter' do
        expect(FileUtils).not_to receive(:rm_rf).with(location.join(id).cleanpath.to_s)

        expect(subject).to be_nil
      end
    end
  end
end
