styleTemplate = require './style-template'
path = require 'path'

fs = null
less = null

# referred from markdown-preview-view.coffee in the official Markdown Preview
## this function is not used anymore
getTextEditorStyles = ()->
  textEditorStyles = document.createElement("atom-styles")
  textEditorStyles.initialize(atom.styles)
  textEditorStyles.setAttribute("context", "atom-text-editor")
  document.body.appendChild(textEditorStyles)

  # Extract style elements content
  style = Array.prototype.slice.apply(textEditorStyles.childNodes).map((styleElement) -> styleElement.innerText)

  # delete element
  textEditorStyles.parentNode.removeChild(textEditorStyles)

  return style

# get array of styles that has 'atom-text-editor' or ':host'
## this function is not used anymore
getReplacedTextEditorStyles = ()->
  styles = getTextEditorStyles()
  output = []

  for i in [0...styles.length]
    if styles[i].indexOf('atom-text-editor') >= 0
      output.push(styles[i]
                    .replace(/[^\.]atom-text-editor/g, '.markdown-preview-enhanced pre')
                    .replace(/:host/g, '.markdown-preview-enhanced .host')
                    .replace(/\.syntax\-\-/g, '.mpe-syntax--'))

  return output.join('\n')


getMarkdownPreviewCSS = ()->
  markdownPreviewRules = []
  ruleRegExp = /\.(markdown-preview-enhanced|mpe-syntax--)/

  for stylesheet in document.styleSheets
    if stylesheet.rules.length
      for rule in stylesheet.rules
        # We only need `.markdown-preview-enhanced` css
        if rule.cssText.match(ruleRegExp)
          markdownPreviewRules.push(rule.cssText)

  return markdownPreviewRules
          .join('\n')
          .replace(/[^\.]atom-text-editor/g, 'pre.editor-colors')
          .replace(/:host/g, '.host') # Remove shadow-dom :host selector causing problem on FF
          .replace(/\.syntax\-\-/g, '.mpe-syntax--')

# cb() is optional
loadPreviewTheme = (previewTheme, cb)->
  previewThemeElement = document.getElementById('markdown-preview-enhanced-preview-theme')
  return cb?() if previewThemeElement?.getAttribute('data-preview-theme') == previewTheme and previewThemeElement?.innerHTML.length

  fs ?= require 'fs'
  less ?= require 'less'
  themes = atom.themes.getLoadedThemes()

  for theme in themes
    if theme.name == previewTheme # found the theme that match previewTheme
      themePath = theme.path
      indexLessPath = path.resolve(themePath, './index.less')
      syntaxVariablesFile = path.resolve(themePath, './styles/syntax-variables.less')

      if !previewThemeElement
        previewThemeElement = document.createElement('style')
        previewThemeElement.id = 'markdown-preview-enhanced-preview-theme'
        previewThemeElement.setAttribute('for', 'markdown-preview-enhanced')
        head = document.getElementsByTagName('head')[0]
        atomStyles = document.getElementsByTagName('atom-styles')[0]
        head.insertBefore(previewThemeElement, atomStyles)
      previewThemeElement.setAttribute 'data-preview-theme', previewTheme

      # compile less to css
      fs.readFile indexLessPath, {encoding: 'utf-8'}, (error, data)->
        return cb?() if error

        # replace css to css.less; otherwise it will cause error.
        data = (data or '').replace(/\/css("|')\;/g, '\/css.less$1;')
        data += styleTemplate

        less.render data, {paths: [themePath, path.resolve(themePath, 'styles')]}, (error, output)->
          return cb?() if error
          css = output.css.replace(/[^\.]atom-text-editor/g, '.markdown-preview-enhanced pre')
                    .replace(/:host/g, '.markdown-preview-enhanced .host')
                    .replace(/\.syntax\-\-/g, '.mpe-syntax--')

          previewThemeElement.innerHTML = css
          return cb?()
      return

  return cb?() # error theme not found

module.exports = {
  getTextEditorStyles
  getMarkdownPreviewCSS
  getReplacedTextEditorStyles
  loadPreviewTheme
}
