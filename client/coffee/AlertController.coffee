class AlertController
  constructor: ->
    @$alert = $('.alert')
    @$alertMessage = $('.message', @$alert)

  showMessage: (message) ->
    @$alert.removeClass('alert-error')
    @$alert.removeClass('alert-success')

    @$alertMessage.html("<strong>#{message}</strong>")
    @$alert.fadeIn('fast')

  hideMessage: () ->
    @$alert.fadeOut('fast')

  showSuccessMessage: (message) ->
    @$alert.removeClass('alert-error')
    @$alert.addClass('alert-success')

    @$alertMessage.html("<strong>#{message}</strong>")

    @$alert.fadeIn('fast', =>
      setTimeout( =>
        @$alert.fadeOut()
      , 2000)
    )

  showErrorMessage: (message) ->
    @$alert.removeClass('alert-success')
    @$alert.addClass('alert-error')

    @$alertMessage.html("<strong>#{message}</strong>")

    @$alert.fadeIn('fast', =>
      setTimeout( =>
        @$alert.fadeOut()
      , 2000)
    )