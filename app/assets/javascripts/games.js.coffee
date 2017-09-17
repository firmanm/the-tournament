# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

# スコアから勝者を判定
judge_winner = (score_1, score_2) ->
  winner = null
  if score_1 > score_2
    winner = 0
  else if score_1 < score_2
    winner = 1
  return winner

# formの値とdivのclassをリセット
reset_winner = ->
  $('.panel').removeClass('panel-warning').addClass('panel-default')
  $('.panel-heading i').removeClass('fa-trophy fa-times')
  $('#game_winner').val('')

# winner/loserの要素をそれぞれセット
set_winner = (winner) ->
  $('.panel').eq(winner).addClass('panel-warning')
  $('.panel-heading i').eq(winner).addClass('fa-trophy')
  $('.panel-heading i').eq(1-winner).addClass('fa-times')
  $('#game_winner').val(winner)


$(document).on 'turbolinks:load', ->
  if ($('body').data('controller')=='tournaments' && $('body').data('action')=='edit_game')
    # 同点の場合は最初から手動の勝者選択をactiveにしとく
    scores = [Number($('.game_game_records_score input')[0].value), Number($('.game_game_records_score input')[1].value)]
    winner = $("#game_winner").val()
    if winner
      set_winner(winner)
      $('#winner-select').val(winner)

    # スコアが変更されたとき
    $('.game_game_records_score input').change ->
      scores = [Number($('.game_game_records_score input')[0].value), Number($('.game_game_records_score input')[1].value)]
      # 点数比較して勝者を決定
      winner = judge_winner(scores[0], scores[1])
      reset_winner()

      # 引き分けじゃなかったら勝者セット
      if winner != null
        set_winner(winner)
        $('#winner-select').val(winner)
      else
        $('#winner-select').val('')

    # 手動の勝者選択が変更されたとき
    $('#winner-select').change ->
      reset_winner()
      # 2人のうちのどちらかが選ばれていたら
      if $.inArray($(this).val(), ["0","1"]) >= 0
        winner = $(this).val()
        set_winner(winner)
