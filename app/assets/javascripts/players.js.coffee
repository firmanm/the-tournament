$(document).on 'turbolinks:load', ->
  # edit_players OR update_playersでトリガー（validation error時は、update_playersでrenderされる）
  if $('body').data('controller')=='tournaments' && $('body').data('action').match(/players/)
    # テキストエリアの行数を数えて表示。登録サイズと違ってたらエラー表示　
    setTeamsCount = ->
      teams_count = $.trim($('#tournament_teams_text').val()).split(/\r|\n/).length
      $('#teams_count').text(teams_count)

      if(teams_count != Number($('#tournament_size').text()))
        $('#teams_count').addClass('text-danger')
      else
        $('#teams_count').removeClass('text-danger')


    # 初回表示
    setTeamsCount()

    # テキストエリア編集時のアップデート
    $('#tournament_teams_text').on 'input propertychange', ->
      setTeamsCount()
