require 'spec_helper'

describe Issues::ListContext do

  let(:user) { create(:user) }
  let(:project) { create(:project, creator: user) }
  
  titles = ['foo','bar','baz']
  titles.each_with_index do |title, index|
    let!(title.to_sym) { create(:issue, title: title, project: project, created_at: Time.now - (index * 60)) }
  end

  describe 'sorting' do

    it 'sorts by newest' do
      params = {:sort => 'newest'}

      issues = Issues::ListContext.new(project, user, params).execute
      issues.first.should eq foo
    end

    it 'sorts by oldest' do
      params = {:sort => 'oldest'}

      issues = Issues::ListContext.new(project, user, params).execute
      issues.first.should eq baz
    end

    it 'sorts by recently updated' do
      params = {:sort => 'recently_updated'}
      baz.updated_at = Time.now + 10
      baz.save

      issues = Issues::ListContext.new(project, user, params).execute
      issues.first.should eq baz
    end

    it 'sorts by least recently updated' do
      params = {:sort => 'last_updated'}
      bar.updated_at = Time.now - 10
      bar.save

      issues = Issues::ListContext.new(project, user, params).execute
      issues.first.should eq bar
    end

    it 'sorts by most recent milestone' do
      pending
    end

    it 'sorts by least recent milestone' do
      pending
    end
  end

  describe '.merge_with_filter_params' do

    it 'merges sort param with filter params' do
      params = {controller: 'issues', action: 'index', label_name: '', milestone_id: '', scope: '', state: '', assignee_id: '1'}

      new_params = Issues::ListContext.merge_with_filter(params, {sort: 'oldest'})

      new_params.should include(:label_name, :milestone_id, :scope, :state, :assignee_id, :sort)
      new_params.should include(:assignee_id => '1')
      new_params.should include(:sort => 'oldest')
      new_params.should_not include(:controller, :action)
    end
  end

end
