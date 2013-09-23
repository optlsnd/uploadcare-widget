{
  namespace,
  utils,
  ui: {progress},
  templates: {tpl},
  jQuery: $,
  locale: {t}
} = uploadcare

namespace 'uploadcare.widget.tabs', (ns) ->

  class ns.PreviewTabMultiple extends ns.BasePreviewTab

    # dpm — abbreviation of dialog-preview-multiple
    CLASS_PREFIX = 'uploadcare-dpm-'
    ROLE_PREFIX = '@' + CLASS_PREFIX

    constructor: ->
      super

      @container.append tpl('tab-preview-multiple')

      @fileListEl = @__find('file-list')
      @filesCountEl = @__find('files-count')
      @footerText = @__find('footer-text')
      @doneBtnEl = @container.find('@uploadcare-dialog-preview-done')

      @__addFile(file) for file in @dialogApi.fileColl.get()

      @dialogApi.fileColl.onAdd.add [@__addFile, @__updateContainerView]
      @dialogApi.fileColl.onRemove.add [@__removeFile, @__updateContainerView]

      @dialogApi.fileColl.onAnyProgress.add @__fileProgress
      @dialogApi.fileColl.onAnyDone.add @__fileDone
      @dialogApi.fileColl.onAnyFail.add @__fileFailed

      utils.loadPlugin('jquery-ui').done =>
        @fileListEl.sortable
          axis: "y"
          update: =>
            elements = @__find 'file-item'
            index = (file) => elements.index @__fileToEl(file)
            @dialogApi.sortFiles (a, b) -> index(a) - index(b)

    __find: (s, context = @container) ->
      $(ROLE_PREFIX + s, context)

    __updateContainerView: =>
      @filesCountEl.text t('file', @dialogApi.fileColl.length())

      @footerText
        .text(
            t('dialog.tabs.preview.multiple.question')
        )

    __fileProgress: (file, progressInfo) =>
      fileEl = @__fileToEl(file)
      @__find('file-progressbar-value', fileEl)
        .css('width', Math.round(progressInfo.progress * 100) + '%')
      @__updateFileInfo(file, progressInfo.incompleteFileInfo)

    __fileDone: (file, info) =>
      fileEl = @__fileToEl(file)
      fileEl.addClass(CLASS_PREFIX + 'uploaded')
      @__updateFileInfo(file, info)

      if info.isImage
        fileEl.addClass(CLASS_PREFIX + 'image')

        @__find('file-preview-wrap', fileEl).html $('<img>')
          .attr
            src: "#{info.originalUrl}-/scale_crop/45x45/center/"

    __fileFailed: (file, error, info) =>
      fileEl = @__fileToEl(file)
      fileEl.addClass(CLASS_PREFIX + 'error')
      @__find('file-error', fileEl)
        .text t("errors.#{error}")
      @__updateFileInfo(file, info)

    __updateFileInfo: (file, info) =>
      fileEl = @__fileToEl(file)

      @__find('file-name', fileEl)
        .text(info.name or t('dialog.tabs.preview.unknownName'))

      @__find('file-size', fileEl)
        .text(utils.readableFileSize(info.size, '–'))

    __addFile: (file) =>
      $(file).data 'dmp-el', @__createFileEl(file)

    __removeFile: (file) =>
      @__fileToEl(file).remove()

    __fileToEl: (file) ->
      $(file).data('dmp-el')

    __createFileEl: (file) ->
      $(tpl 'tab-preview-multiple-file')
        .appendTo(@fileListEl)
        .on('click', ROLE_PREFIX + 'file-remove', (=> @dialogApi.removeFile file))
