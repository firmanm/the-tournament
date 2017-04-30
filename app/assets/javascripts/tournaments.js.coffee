# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

$ ->
  # tournament#show page
  if ($('body').data('controller')=='tournaments' && $('body').data('action')=='show')
    # Tournament creation
    createBracket = ->
      d = new $.Deferred
      $('#tournament').bracket({
        skipConsolationRound: gon.skip_consolation_round,
        skipSecondaryFinal: gon.skip_secondary_final,
        teamWidth: 100,
        scoreWidth: 35,
        init: gon.tournament_data,
        decorator: {
          edit: edit_fn,
          render: render_fn
        }
      })
      d.resolve()

    edit_fn = (container, data, doneCb) ->
      # Do something here

    render_fn = (container, data, score, state) ->
      switch state
        when "empty-bye"
          container.append("--")
          return
        when "empty-tbd"
          container.append("--")
          return
        else
          content = ''
          if data.flag && data.flag != ""
            content += '<span class="f16"><span class="flag '+data.flag+'"></span></span>'
          content += data.name
          container.append(content)
          return

    hideDecimal = ->
      jQuery.each($('.score'), ->
        if !isNaN(this.innerText)
          if gon.scoreless   # when the tournament is scoreless
            this.innerText = '--'
          else  # Same score win
            this.innerText = Math.abs(Math.floor(this.innerText))
      )

    setTooltip = ->
      $('.bracket .teamContainer').each (i) ->
        $(this).attr({
          'data-balloon-pos': 'right',
          'data-balloon-length': 'medium',
          'data-balloon': [].concat.apply([], gon.tournament_data['results'])[i][2]
        })

    prepareImage = ->
      setTimeout ->
        html2canvas($(".bracket"), {
          useCORS: true,
          onrendered: (canvas) ->
            canvasImage = canvas.toDataURL("image/png", 1.0)
            $("#download_btn").attr('href', canvasImage).attr('download', 'tournament.png')
            $("#btn-upload_img").attr('data-img_uri', canvasImage)
            $("#download_btn, #btn-upload_img").button("reset")
        })
      , 1500

    createBracket().done(hideDecimal(), setTooltip())


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
