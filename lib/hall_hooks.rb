class NotificationHook < Redmine::Hook::Listener

  def controller_issues_new_after_save(context = {})
    issue   = context[:issue]
    project = issue.project
    return true unless hall_configured?(project)

    author  = CGI::escapeHTML(User.current.name)
    tracker = CGI::escapeHTML(issue.tracker.name.downcase)
    subject = CGI::escapeHTML(issue.subject)
    url     = get_url(issue)
    text    = "#{author} reported #{project.name} #{tracker} <a href=\"#{url}\" target=\"_blank\">##{issue.id}</a>: #{subject}"

    data          = {}
    data[:text]   = text
    data[:token]  = hall_auth_token(project)

    send_message(data)
  end

  def controller_issues_edit_after_save(context = {})
    issue   = context[:issue]
    project = issue.project
    return true unless hall_configured?(project)

    author  = CGI::escapeHTML(User.current.name)
    tracker = CGI::escapeHTML(issue.tracker.name.downcase)
    subject = CGI::escapeHTML(issue.subject)
    comment = CGI::escapeHTML(context[:journal].notes)
    url     = get_url(issue)
    text    = "#{author} updated #{project.name} #{tracker} <a href=\"#{url}\" target=\"_blank\">##{issue.id}</a>: #{subject}"
    text   += ": <i>#{truncate(comment)}</i>" unless comment.blank?

    data          = {}
    data[:text]   = text
    data[:token]  = hall_auth_token(project)

    send_message(data)
  end

  def controller_wiki_edit_after_save(context = {})
    page    = context[:page]
    project = page.wiki.project
    return true unless hall_configured?(project)

    author       = CGI::escapeHTML(User.current.name)
    wiki         = CGI::escapeHTML(page.pretty_title)
    project_name = CGI::escapeHTML(project.name)
    url          = get_url(page)
    text         = "#{author} edited #{project_name} wiki page <a href=\"#{url}\">#{wiki}</a>"

    data          = {}
    data[:text]   = text
    data[:token]  = hall_auth_token(project)

    send_message(data)
  end

  private

  def hall_configured?(project)
    hall_auth_token(project).present?
  end

  def hall_auth_token(project)
    project.hall_auth_token
  end

  def get_url(object)
    case object
      when Issue    then "#{Setting[:protocol]}://#{Setting[:host_name]}/issues/#{object.id}"
      when WikiPage then "#{Setting[:protocol]}://#{Setting[:host_name]}/projects/#{object.wiki.project.identifier}/wiki/#{object.title}"
    else
      Rails.logger.info "Asked redmine_hall for the url of an unsupported object #{object.inspect}"
    end
  end

  def send_message(data)
    Rails.logger.info "Sending message to Hall: #{data[:text]}"
    req = Net::HTTP::Post.new("/api/1/services/generic/#{data[:token]}")
    req.set_form_data({
      :title => 'Redmine',
      :message => data[:text]
    })
    req["Content-Type"] = 'application/x-www-form-urlencoded'

    http = Net::HTTP.new("hall.com", 443)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    begin
      http.start do |connection|
        connection.request(req)
      end
    rescue Net::HTTPBadResponse => e
      Rails.logger.error "Error hitting Hall API: #{e}"
    end
  end

  def truncate(text, length = 20, end_string = '...')
    return unless text
    words = text.split()
    words[0..(length-1)].join(' ') + (words.length > length ? end_string : '')
  end
end
