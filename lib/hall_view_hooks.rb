class NotificationViewHook < Redmine::Hook::ViewListener
  render_on(:view_projects_form, :partial => 'projects/redmine_hall', :layout => false)
end
