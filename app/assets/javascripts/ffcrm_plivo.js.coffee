jQuery ($) ->
  jQuery('#search_number_type_tollfree').click ->
    jQuery('#search_services').hide()
    jQuery('#search_prefix td').first().html("Prefix")
    jQuery('#search_prefix td').last().html('<select id="search_area_prefix" name="search[prefix]"><option value="">All</option><option value="855">855</option><option value="866">866</option><option value="877">877</option><option value="888">888</option></select>')
  jQuery('#search_number_type_local').click ->
    jQuery('#search_services').show()
    jQuery('#search_prefix td').first().html("Search")
    jQuery('#search_prefix td').last().html('<input id="search_area_code" name="search[area_code]" placeholder="prefix or area" type="text">')


    #jQuery('#plivo_number_number_type_User').click ->
    #don't remember what is it

  jQuery('#replist p').click ->
    jQuery('#replist ul').toggle("blind",500)

jQuery ($) ->
  jQuery('.plivo-call-gen').click ->
    jQuery.post('/plivo/phone/send', {'phone' : jQuery(this).data('phone')})
