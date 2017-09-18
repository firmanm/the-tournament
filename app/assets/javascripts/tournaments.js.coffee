# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

$(document).on 'turbolinks:load', ->
  # tournaments#show
  # if $('body').data('controller')=='tournaments' && $('body').data('action')=='show'
  #   $(".bracket").css('overflow-x', 'inherit').css('overflow-y', 'inherit').css('width', 'fit-content')
  #   setTimeout ->
  #     $("#btnImageDownload").button('loading')   #=> loading状態にしとく
  #     html2canvas($(".bracket"), {
  #       onrendered: (canvas) ->
  #         # canvasImage = canvas.toDataURL("image/jpeg", 1.0)
  #         canvasImage = canvas.toDataURL()
  #         $("#btnImageDownload").attr('href', canvasImage)
  #         $("#btnImageDownload").button('reset')    #=> 完了したらクリック可能状態に戻す
  #         $(".bracket").css('overflow-x', 'scroll').css('overflow-y', 'scroll').css('width', '100%')
  #     })
  #   , 3000


  # tournament#edit page - Tags input
  if $('#tournament_tag_list').length
    $('#tournament_tag_list').tagsInput({'width':'100%', 'height':'auto'})


  # tournament#photos
  if ($('body').data('controller')=='tournaments' && $('body').data('action')=='photos')
    if gon.album_id != null && gon.album_id != ''
      window.fbAsyncInit = ->
        FB.init({
          appId      : '1468816573143230',
          xfbml      : true,
          version    : 'v2.8'
        })
        FB.AppEvents.logPageView()

        request_url = "/" + gon.album_id + "/photos?fields=images&access_token=" + gon.fb_token
        FB.api request_url, (response) ->
          photos = ''
          album_url = "https://www.facebook.com/media/set/?set=a." + gon.album_id
          $.each response.data, (index, obj) ->
            return false if index >= 12

            start_div = end_div = ''
            if index%4 == 0
              start_div = '<div class="row" style="margin-bottom:15px;">'
            if index%4 == 3 || index == response.data.length
              end_div = '</div>'
            photos += start_div + '<div class="col-sm-3"><a href="' + album_url + '" target="_blank"><div style="width:100%;height:200px;background-size:cover;background-position:center;background-image:url('+obj.images[0]['source']+')"></div></a></div>' + end_div
          $('.album-container').append(photos)
