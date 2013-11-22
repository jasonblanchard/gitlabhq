require 'spec_helper'

describe "Issues" do
  let(:project) { create(:project) }

  before do
    login_as :user
    user2 = create(:user)

    project.team << [[@user, user2], :developer]
  end

  describe "Edit issue" do
    let!(:issue) do
      create(:issue,
             author: @user,
             assignee: @user,
             project: project)
    end

    before do
      visit project_issues_path(project)
      click_link "Edit"
    end

    it "should open new issue popup" do
      page.should have_content("Issue ##{issue.iid}")
    end

    describe "fill in" do
      before do
        fill_in "issue_title", with: "bug 345"
        fill_in "issue_description", with: "bug description"
      end

      it { expect { click_button "Save changes" }.to_not change {Issue.count} }

      it "should update issue fields" do
        click_button "Save changes"

        page.should have_content @user.name
        page.should have_content "bug 345"
        page.should have_content project.name
      end
    end
  end

  describe "Filter issue" do
    before do
      ['foobar', 'barbaz', 'gitlab'].each do |title|
        create(:issue,
               author: @user,
               assignee: @user,
               project: project,
               title: title)
      end

      @issue = Issue.first # with title 'foobar'
      @issue.milestone = create(:milestone, project: project)
      @issue.assignee = nil
      @issue.save
    end

    let(:issue) { @issue }

    it "should allow filtering by issues with no specified milestone" do
      visit project_issues_path(project, milestone_id: '0')

      page.should_not have_content 'foobar'
      page.should have_content 'barbaz'
      page.should have_content 'gitlab'
    end

    it "should allow filtering by a specified milestone" do
      visit project_issues_path(project, milestone_id: issue.milestone.id)

      page.should have_content 'foobar'
      page.should_not have_content 'barbaz'
      page.should_not have_content 'gitlab'
    end

    it "should allow filtering by issues with no specified assignee" do
      visit project_issues_path(project, assignee_id: '0')

      page.should have_content 'foobar'
      page.should_not have_content 'barbaz'
      page.should_not have_content 'gitlab'
    end

    it "should allow filtering by a specified assignee" do
      visit project_issues_path(project, assignee_id: @user.id)

      page.should_not have_content 'foobar'
      page.should have_content 'barbaz'
      page.should have_content 'gitlab'
    end
  end

  describe 'filter issue' do
    titles = ['foo','bar','baz']
    titles.each_with_index do |title, index|
      let!(title.to_sym) { create(:issue, title: title, project: project, created_at: Time.now - (index * 60)) }
    end
    let(:newer_due_milestone) { create(:milestone, :due_date => '2013-12-11') }
    let(:later_due_milestone) { create(:milestone, :due_date => '2013-12-12') }

    it 'sorts by newest' do
      visit project_issues_path(project, sort: 'newest')
      
      page.should have_selector("ul.issues-list li:first-child", :text => 'foo')
      page.should have_selector("ul.issues-list li:last-child", :text => 'baz')
    end

    it 'sorts by oldest' do
      visit project_issues_path(project, sort: 'oldest')

      page.should have_selector("ul.issues-list li:first-child", :text => 'baz')
      page.should have_selector("ul.issues-list li:last-child", :text => 'foo')
    end

    it 'sorts by most recently updated' do
      baz.updated_at = Time.now + 100
      baz.save
      visit project_issues_path(project, sort: 'recently_updated')

      page.should have_selector("ul.issues-list li:first-child", :text => 'baz')
    end

    it 'sorts by least recently updated' do
      baz.updated_at = Time.now - 100
      baz.save
      visit project_issues_path(project, sort: 'last_updated')

      page.should have_selector("ul.issues-list li:first-child", :text => 'baz')
    end

    describe 'sorting by milestone' do
      
      before :each do 
        foo.milestone = newer_due_milestone
        foo.save
        bar.milestone = later_due_milestone
        bar.save
      end

      it 'sorts by recently due milestone' do
        visit project_issues_path(project, sort: 'milestone_due_soon')

        page.should have_selector("ul.issues-list li:first-child", :text => 'foo')
      end

      it 'sorts by least recently due milestone' do
        visit project_issues_path(project, sort: 'milestone_due_later')

        page.should have_selector("ul.issues-list li:first-child", :text => 'bar')
      end
    end
  end
end
