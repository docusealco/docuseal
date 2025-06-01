# frozen_string_literal: true

RSpec.describe 'Template' do
  let!(:account) { create(:account) }
  let!(:user) { create(:user, account:) }
  let!(:template) { create(:template, account:, author: user, except_field_types: %w[phone payment]) }

  before do
    sign_in(user)
  end

  context 'when no submissions' do
    it 'shows the template page' do
      visit template_path(template)

      expect(page).to have_content(template.name)
      expect(page).to have_content('There are no Submissions')
      expect(page).to have_content('Send an invitation to fill and complete the form')
      expect(page).to have_button('Sign it Yourself')
    end
  end

  context 'when there are submissions' do
    let!(:submission) { create(:submission, template:, created_by_user: user) }
    let!(:submitters) { template.submitters.map { |s| create(:submitter, submission:, uuid: s['uuid']) } }

    it 'shows the template page with submissions' do
      visit template_path(template)

      submitters.each do |submitter|
        expect(page).to have_content(submitter.name)
      end

      expect(page).to have_content(template.name)
    end
  end

  context 'when managing a template' do
    before do
      visit template_path(template)
    end

    it 'archives a template' do
      expect do
        accept_confirm('Are you sure?') do
          click_button 'Archive'
        end
      end.to change { Template.active.count }.by(-1)

      expect(page).to have_content('Template has been archived')
    end

    it 'edits a template' do
      click_link 'Edit'

      expect(page).to have_current_path(edit_template_path(template), ignore_query: true)
    end

    it 'clones a template' do
      click_link 'Clone'

      within '#modal' do
        fill_in 'template[name]', with: 'New Template Name'

        expect do
          click_button 'Submit'
        end.to change { Template.active.count }.by(1)

        template = Template.last

        expect(template.name).to eq('New Template Name')
        expect(page).to have_current_path(edit_template_path(template), ignore_query: true)
      end
    end

    it 'clone a template and move it to a new folder' do
      click_link 'Clone'

      within '#modal' do
        fill_in 'template[name]', with: 'New Template Name'
        click_link 'Change Folder'
        fill_in 'folder_name', with: 'New Folder Name'

        expect do
          click_button 'Submit'
        end.to change { Template.active.count }.by(1).and change { TemplateFolder.active.count }.by(1)

        template = Template.last

        expect(template.name).to eq('New Template Name')
        expect(template.folder.name).to eq('New Folder Name')
        expect(page).to have_current_path(edit_template_path(template), ignore_query: true)
      end
    end

    it 'clones a template and moves it to an existing folder' do
      template_folder = create(:template_folder, :with_templates, account:, author: user)

      click_link 'Clone'

      within '#modal' do
        template_folder.reload
        fill_in 'template[name]', with: 'New Template Name'
        click_link 'Change Folder'
      end

      within '.autocomplete' do
        find('div', text: template_folder.name).click
      end

      within '#modal' do
        expect do
          click_button 'Submit'
        end.not_to(change { TemplateFolder.active.count })
      end

      template = Template.last
      expect(template.name).to eq('New Template Name')
      expect(template.folder.name).to eq(template_folder.name)
      expect(page).to have_current_path(edit_template_path(template), ignore_query: true)
    end

    it 'moves a template' do
      find('[data-tip="Move"]', visible: false).hover
      find('[data-tip="Move"]').click

      within '#modal' do
        fill_in 'name', with: 'New Folder Name'

        expect do
          click_button 'Move'
        end.to change { TemplateFolder.active.count }.by(1)

        template_folder = TemplateFolder.last

        expect(template_folder.name).to eq('New Folder Name')
        expect(page).to have_current_path(template_path(template), ignore_query: true)
      end
    end
  end

  context 'when filtering submissions' do
    let(:second_user) { create(:user, account:) }

    it 'displays only submissions by the selected author' do
      first_user_submissions = create_list(:submission, 5, :with_submitters, template:, created_by_user: user)
      second_user_submissions = create_list(:submission, 6, :with_submitters, template:, created_by_user: second_user)

      visit template_path(template)

      (first_user_submissions + second_user_submissions).map(&:submitters).flatten.last(10).uniq.each do |submitter|
        expect(page).to have_content(submitter.name)
      end

      page.find('.dropdown', text: 'Filter').click
      click_link 'Author'
      within '#modal' do
        select second_user.full_name, from: 'author'
        click_button 'Apply'
      end

      second_user_submissions.map(&:submitters).flatten.uniq.each do |submitter|
        expect(page).to have_content(submitter.name)
      end

      first_user_submissions.map(&:submitters).flatten.uniq.each do |submitter|
        expect(page).not_to have_content(submitter.name)
      end
    end

    it 'displays submissions created within the selected date range' do
      last_week_submissions = create_list(:submission, 5, :with_submitters, template:, created_by_user: user,
                                                                            created_at: 9.days.ago)
      this_week_submissions = create_list(:submission, 6, :with_submitters, template:, created_by_user: user,
                                                                            created_at: 5.days.ago)

      visit template_path(template)

      (last_week_submissions + this_week_submissions).map(&:submitters).flatten.last(10).uniq.each do |submitter|
        expect(page).to have_content(submitter.name)
      end

      page.find('.dropdown', text: 'Filter').click
      click_link 'Created at'
      within '#modal' do
        fill_in 'From', with: I18n.l(10.days.ago, format: '%Y-%m-%d')
        fill_in 'To', with: I18n.l(6.days.ago, format: '%Y-%m-%d')
        click_button 'Apply'
      end

      last_week_submissions.map(&:submitters).flatten.uniq.each do |submitter|
        expect(page).to have_content(submitter.name)
      end

      this_week_submissions.map(&:submitters).flatten.uniq.each do |submitter|
        expect(page).not_to have_content(submitter.name)
      end
    end

    it 'displays submissions completed within the selected date range' do
      last_week_submissions = create_list(:submission, 5, :with_submitters, template:, created_by_user: user)
      this_week_submissions = create_list(:submission, 6, :with_submitters, template:, created_by_user: user)

      last_week_submissions.map(&:submitters).flatten.each do |submitter|
        submitter.update!(completed_at: rand(6..10).days.ago)
      end

      this_week_submissions.map(&:submitters).flatten.each do |submitter|
        submitter.update!(completed_at: rand(2..5).days.ago)
      end

      visit template_path(template)

      (last_week_submissions + this_week_submissions).map(&:submitters).flatten.last(10).uniq.each do |submitter|
        expect(page).to have_content(submitter.name)
      end

      page.find('.dropdown', text: 'Filter').click
      click_link 'Completed at'
      within '#modal' do
        fill_in 'From', with: I18n.l(5.days.ago, format: '%Y-%m-%d')
        fill_in 'To', with: I18n.l(1.day.ago, format: '%Y-%m-%d')
        click_button 'Apply'
      end

      this_week_submissions.map(&:submitters).flatten.uniq.each do |submitter|
        expect(page).to have_content(submitter.name)
      end

      last_week_submissions.map(&:submitters).flatten.uniq.each do |submitter|
        expect(page).not_to have_content(submitter.name)
      end
    end
  end
end
