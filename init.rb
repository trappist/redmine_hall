Redmine::Plugin.register :redmine_hall do
  name 'Hall'
  author 'Rocco Stanzione'
  description 'Sends notifications to a Hall room.'
  version '0.0.1'
  url 'https://github.com/trappist/redmine_hall'
  author_url 'https://github.com/trappist'

  Rails.configuration.to_prepare do
    require_dependency 'hall_hooks'
    require_dependency 'hall_view_hooks'
    require_dependency 'hall_project_patch'
    Project.send(:include, RedmineHall::Patches::ProjectPatch)
  end

  settings :partial => 'settings/redmine_hall',
    :default => {
      :room_id => "",
      :auth_token => "",
    }
end
