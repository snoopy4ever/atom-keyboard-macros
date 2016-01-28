{CompositeDisposable} = require 'atom'
{keystrokeForKeyboardEvent, keydownEvent, characterForKeyboardEvent} = require './helpers'
{FindNextCommand, FindPreviousCommand, FindNextSelectedCommand, FindPreviousSelectedCommand, SetSelectionAsFindPatternCommand, ReplacePreviousCommand, ReplaceNextCommand, ReplaceAllCommand} = require './macro-command'

module.exports =
class FindAndReplace
  findView: null
  findEditor: null
  replaceEditor: null

  ###
  regexOption: false
  caseSensitive: false
  inCurrentSelection: false
  wholeWord: false
  ###

  #toggle: ->
  findNext: null
  findPrevious: null
  findNextSelected: null
  findPreviousSelected: null
  setSelectionAsFindPattern: null
  replacePrevious: null
  replaceNext: null
  replaceAll: null

  isRecording: false

  activate: ->
    # wake up find-and-replace
    editorElement = atom.views.getView(atom.workspace.getActiveTextEditor())
    atom.commands.dispatch(editorElement, 'find-and-replace:toggle') # wake up if not active
    atom.commands.dispatch(editorElement, 'find-and-replace:toggle') # hide

    isRecording = false
    @getFindAndReplaceMethods()

  deactivate: ->
    panels = atom.workspace.getBottomPanels()

    for panel in panels
      item = panel.item
      name = item?.__proto__?.constructor?.name
      if name == 'FindView'
        item.findNext = @findNext
        item.findPrevious = @findPrevious
        item.findNextSelected = @findNextSelected
        item.findPreviousSelected = @findPreviousSelected
        item.setSelectionAsFindPattern = @setSelectionAsFindPattern
        item.replaceNext = @replaceNext
        item.replaceAll = @replaceAll

    @replaceAllButton.removeEventListener('on', @replaceAllButtonHook)
    @replaceNextButton.removeEventListener('on', @replaceNextButtonHook)
    @nextButton.removeEventListener('on', @nextButtonHook)
    @regexOptionButton.removeEventListener('on', @regexOptionButtonHook)
    @caseOptionButton.removeEventListener('on', @caseOptionButtonHook)
    @selectionOptionButton.removeEventListener('on', @selectionOptionButtonHook)
    @wholeWordOptionButton.removeEventListener('on', @wholeWordOptionButtonHook)


  #
  # get Methods from FindView
  #
  getFindAndReplaceMethods: ->
    if @findNext
      return

    panels = atom.workspace.getBottomPanels()

    for panel in panels
      item = panel.item
      name = item?.__proto__?.constructor?.name
      if name == 'FindView'
        #console.log('item', item)
        @findView = item

        @findNext = item.findNext
        @findPrevious = item.findPrevious
        @findNextSelected = item.findNextSelected
        @findPreviousSelected = item.findPreviousSelected
        @setSelectionAsFindPattern = item.setSelectionAsFindPattern
        @replacePrevious = item.replacePrevious
        @replaceNext = item.replaceNext
        @replaceAll = item.replaceAll

        @findEditor = item.findEditor
        @replaceEditor = item.replaceEditor

        @replaceAllButton = item.replaceAllButton
        @replaceNextButton = item.replaceNextButton
        @nextButton = item.nextButton
        @regexOptionButton = item.regexOptionButton
        @caseOptionButton = item.caseOptionButton
        @selectionOptionButton = item.selectionOptionButton
        @wholeWordOptionButton = item.wholeWordOptionButton

        if !(@findNext and @findPrevious and @findNextSelected and @findPrevious and @findPreviousSelected and @setSelectionAsFindPattern and @replacePrevious and @replaceNext and @replaceAll and @findEditor and @replaceEditor)
          @findNext = null
          @findPrevious = null
          @findNextSelected = null
          @findPreviousSelected = null
          @setSelectionAsFindPattern = null
          @replacePrevious = null
          @replaceNext = null
          @replaceAll = null
          @findEditor = null
          @replaceEditor = null
          return

        item.findNext = @findNextMonitor
        item.findPrevious = @findPreviousMonitor
        item.findNextSelected = @findNextSelectedMonitor
        item.findPreviousSelected = @findPreviousSelectedMonitor
        item.setSelectionAsFindPattern = @setSelectionAsFindPatternMonitor
        item.replacePrevious = @replacePreviousMonitor
        item.replaceNext = @replaceNextMonitor
        item.replaceAll = @replaceAllMonitor

        self = this
        @replaceAllButtonHook = (e) ->
          self.replaceAllMonitor()
        @replaceAllButton.on 'click', @replaceAllButtonHook

        @replaceNextButtonHook = (e) ->
          self.replaceNextMonitor()
        @replaceNextButton.on 'click', @replaceNextButtonHook

        @nextButtonHook = (e) ->
          self.findNextMonitor()
        @nextButton.on 'click', @nextButtonHook

        ###
        @regexOptionButtonHook = (e) ->
          self.regexOptionButtonMonitor()
        @regexOptionButton.on 'click', @regexOptionButtonHook

        @caseOptionButtonHook = (e) ->
          self.caseOptionButtonMonitor()
        @caseOptionButton.on 'click', @caseOptionButtonHook

        @selectionOptionButtonHook = (e) ->
          self.selectionOptionButtonMonitor()
        @selectionOptionButton.on 'click', @selectionOptionButtonHook

        @wholeWordOptionButtonHook = (e) ->
          self.wholeWordOptionButtonMonitor()
        @wholeWordOptionButton.on 'click', @wholeWordOptionButtonHook
        ###

        break

  # Util

  getFindText: ->
    @findEditor?.getText()

  getReplaceText: ->
    @replaceEditor?.getText()

  setFindText: (text) ->
    @findEditor?.setText(text)

  setReplaceText: (text) ->
    @replaceEditor?.setText(text)

  #
  # start & stop
  #

  startRecording: (@macroSequence)->
    @isRecording = true

  stopRecording: ->
    @isRecording = false

  ###
  #
  # hook option buttons on change
  #
  regexOptionButtonMonitor: ->
    options = @findView.model?.getFindOptions()
    @regexOption = options?.useRegex

  caseOptionButtonMonitor: ->
    options = @findView.model?.getFindOptions()
    @caseSensitive = options?.caseSensitive

  selectionOptionButtonMonitor: ->
    options = @findView.model?.getFindOptions()
    @inCurrentSelection = options?.inCurrentSelection

  wholeWordOptionButtonMonitor: ->
    options = @findView.model?.getFindOptions()
    @wholeWord = options.wholeWord
  ###


  #
  # hook handlers
  #

  # findNext: (options={focusEditorAfter: false}) =>
  #findNextMonitor: (options={focusEditorAfter: false}) ->
  findNextMonitor: ->
    if not @isRecording
      return
    options = @findView.model?.getFindOptions()
    @macroSequence.push(new FindNextCommand(this, @getFindText(), options))
    #@macroSequence.push(new FindNextCommand(this, @getFindText()))

  #findPrevious: (options={focusEditorAfter: false}) =>
  #findPreviousMonitor: (options={focusEditorAfter: false}) ->
  findPreviousMonitor: ->
    if not @isRecording
      return
    options = @findView.model?.getFindOptions()
    @macroSequence.push(new FindPreviousCommand(this, @getFindText(), options))
    #@macroSequence.push(new FindPreviousCommand(this, @getFindText()))

  # findNextSelected: =>
  findNextSelectedMonitor: ->
    if not @isRecording
      return
    options = @findView.model?.getFindOptions()
    @macroSequence.push(new FindNextSelectedCommand(this, @getFindText(), options))

  # findPreviousSelected: =>
  findPreviousSelectedMonitor: ->
    if not @isRecording
      return
    options = @findView.model?.getFindOptions()
    @macroSequence.push(new FindPreviousSelectedCommand(this, @getFindText(), options))

  # setSelectionAsFindPattern: =>
  setSelectionAsFindPatternMonitor: ->
    if not @isRecording
      return
    options = @findView.model?.getFindOptions()
    @macroSequence.push(new SetSelectionAsFindPatternCommand(this), options)

  # replacePrevious: =>
  replacePreviousMonitor: ->
    if not @isRecording
      return
    options = @findView.model?.getFindOptions()
    @macroSequence.push(new ReplacePreviousCommand(this, @getFindText(), @getReplaceText(), options))

  # replaceNext: =>
  replaceNextMonitor: ->
    if not @isRecording
      return
    options = @findView.model?.getFindOptions()
    @macroSequence.push(new ReplaceNextCommand(this, @getFindText(), @getReplaceText(), options))

  # replaceAll: =>
  replaceAllMonitor: ->
    if not @isRecording
      return
    options = @findView.model?.getFindOptions()
    @macroSequence.push(new ReplaceAllCommand(this, @getFindText(), @getReplaceText(), options))