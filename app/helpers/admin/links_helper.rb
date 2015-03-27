module Admin::LinksHelper
  def link_delete_link(link, options = {class: 'btn btn-danger'})
    link_to 'Delete', admin_link_path(link), class: options[:class], data: { confirm: 'Are you sure?', remote: true, method: :delete }
  end
end