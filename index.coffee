#!/usr/bin/env coffee

# Usage: 
#
#     $ coffee style.coffee [--style=style.css] [--html=output.html] [input.html]`

# Standard Node
fs = require "fs"
process = require "process"

# Third-Party 
absurd = do -> # absurd.js fucks up with command-line args.
  argv = process.argv
  process.argv = ["coffee"]
  absurd = require "absurd"
  process.argv = argv
  absurd

jquery = require "jquery"
jsdom = require "jsdom"
parseArgs = require "minimist"



defaults =
  css:
    "*":
      margin: 0
      padding: 0
      border: 0
      boxSizing: "content-box" # "border-box" ? Study the transition (changes aspect)
      fontSize: "100%"
      font: "inherit"
      verticalAlign: "baseline"
    html:
      lineHeight: 1
    "ol, ul":
      listStyle: "none"
    "blockquote, q":
      "quotes": "none"
      ":before":
        content: "none"
      ":after":
        content: "none"
    table:
      borderCollapse: "collapse"
      borderSpacing: 0
  html: ($) ->
    undefined # detect before add
    #$("head").append $("<meta charset='UTF-8'></meta>")

# Colors
color = "black"


# Typography

# TODO: bring code typo here ? That would make sense. Defines font families too.
base = 24
lineHeight = base * 1.5 # prepare for rems instead of px ?
ratio = Math.sqrt(2)
# TODO: use "xx-small, x-small, small, medium, large, x-large, xx-large" ?
#       (they are actually valid *values*) --> get xLarge instead of huge.
small  = Math.round(base / ratio) + "px"
medium = Math.round(base) + "px"
large  = Math.round(base * ratio) + "px"
xLarge = Math.round(base * ratio * ratio) + "px"

typography =
  html: ($) -> # TODO: check that the link is not already here ?
    family = "Alegreya:400,400italic,700,700italic|Alegreya+SC:400,400italic,700,700italic"
    link = $ "<link>",
      href: "https://fonts.googleapis.com/css?family=#{family}"
      rel: "stylesheet"
      type: "text/css"
    $("head").append link
  css:
    html:
      fontSize: medium
      fontStyle: "normal"
      fontWeight: "normal"
      fontFamily: "Alegreya, serif"
      em:
        fontStyle: "italic"
      strong:
        fontWeight: "bold"
      textRendering: "optimizeLegibility"
      lineHeight: lineHeight + "px"
      textAlign: "left"
      p: # migrate to (text) layout ? Pff dunno ... typo would be family,
         # style, lineheight ? But this is dispatched in many places 
         # (header stuff, etc.)
        marginBottom: lineHeight + "px"
        textAlign: "justify"
        hyphens: "auto"
        MozHyphens: "auto"
      
layout = ->
  html:
    body: # pfff not body (adapt pandoc build to have another top-level component.
          # the easiest thing to do is probably to have a "main" class, it's
          # flexible wrt the actual tag soup ...)

      # Nota: this is probably the only place where we want content-box model,
      #       so define border-box in defaults to everything.

      boxSizing: "content-box" # check this ... check that 32 em applies to
      maxWidth: "32em"         # the text WITHOUT the padding.
      margin: "auto"
      padding: lineHeight + "px" # use rems instead (1.5rem)?

header = ->
  body:
    "> header, > .header, > #header": # child of body is probably not appropriate ...
                # instead, search for "a top-level section" (main, article, 
                # class="main", etc.) and select the headers that are children
                # -- not descendants -- of these.
      #borderTop: "3px solid #000000"
      marginTop: 2.0 * lineHeight + "px" # not sure that's the right place.
      marginBottom: 2.0 * lineHeight + "px"
      h1:
        fontSize: xLarge
        lineHeight: 1.5 * lineHeight + "px"
        marginTop: 0.0 * lineHeight + "px" # compensate somewhere else, here
        marginBottom: lineHeight + "px"    # is not the place.
        fontWeight: "bold"
      ".author":
        fontSize: medium
        lineHeight: lineHeight + "px"
#        paddingTop: "1.5px" # makes the "true" baseline periodic (48 px)
        marginBottom: 0.5 * lineHeight + "px"
        fontWeight: "normal"
      ".date":
        fontFamily: '"Alegreya SC", serif'
        lineHeight: lineHeight + "px"
        fontSize: medium
        fontWeight: "normal"
        marginBottom: 0.5 * lineHeight + "px"
        float: "none" # it's a pain to have to put that here to counteract
                      # the "float: left" used in "normal" h3 ...

headings = ->
  h1:
    fontSize: large
    fontWeight: "bold"
    lineHeight: 1.25 * lineHeight + "px"
    marginTop: 2.0 * lineHeight + "px"
    marginBottom: 0.75 * lineHeight + "px"
  h2:
    fontSize: medium
    fontWeight: "bold"
    lineHeight: lineHeight + "px"
#    marginTop: 1.0 * lineHeight + "px"
    marginBottom: 0.5 * lineHeight + "px"

  "h3, h4, h5, h6":
    fontSize: medium
    fontWeight: "bold"
    float: "left"
    marginRight: "1em"
#    marginTop: "0px"
#    marginBottom: "0px"

links = ->
  a:
    cursor: "pointer"
    textDecoration: "none"
    outline: 0
    ":hover":
      textDecoration: "none"
    ":link":
      color: color
    ":visited":
      color: color

lists = ->
  li:
    listStyle: "disc outside none"
    marginLeft: 1 * lineHeight + "px"
    paddingLeft: "0.5em"

quote = ->
  blockquote:
    marginLeft: 1 * lineHeight + "px"
    marginRight: 1 * lineHeight + "px"

code =
  html: ($) ->
    family = "Inconsolata:400,700"
    link = $ "<link>",
      href: "https://fonts.googleapis.com/css?family=#{family}"
      rel: "stylesheet"
      type: "text/css"
    $("head").append link
  css:
    code:
      fontSize: medium
      fontFamily: "Inconsolata"
    pre:
      overflowX: "auto"
      backgroundColor: "#ebebeb"
      #marginTop: 1 * lineHeight + "px"
      marginBottom: 1 * lineHeight + "px"
      paddingLeft: lineHeight + "px"
      paddingRight: lineHeight + "px"
      paddingTop : 1 * lineHeight + "px"
      paddingBottom : 1 * lineHeight

mathjax = ($) ->
  old = $("head script").filter (i, elt) -> 
    src = $(elt).attr("src")
    /mathjax/.test src
  old.remove()
  # DOM API instead of JQuery that adds weird script tags
  script = window.document.createElement "script"
  script.type = "text/javascript"
  script.src = "https://cdn.mathjax.org/mathjax/latest/MathJax.js?config=TeX-AMS-MML_HTMLorMML.js" 
  script.text = "MathJax.Hub.Config({'jax': ['output/CommonHTML'], 
                                     'CommonHTML': {'scale': 90}});"
  window.document.head.appendChild script 


absurdify = (api) ->
    api.add defaults.css
    api.add typography.css
    api.add layout()
    api.add header()
    api.add headings()
    api.add links()
    api.add lists()
    api.add quote()
    api.add code.css
    api

domify = ($, options) ->
  defaults.html($)
  typography.html($)
  code.html($)
  mathjax($) if $(".math").length

  




#layout()
#  // min-width: 12em // can we do that ? // when does the window does decide 
#  // that the viewport size is too small and adds a slider ? For small widths,
#  // the body gets reduced, but the window/viewport or whatever contains it
#  // stops getting thiner, and a scroll appears. FUCK, THIS IS BULLSHIT.
#  // even the html element states that it's getting thinner, but still,
#  // the scroll bar tells me otherwise.


#  // probably need to transfer this in "main"; some control elements
#  // may not like being padded or constrained in width like that.
#  // make the "toplevel container" configurable ?
#  max-width: 32em
#  margin: auto
#  padding: 1.5em 

#html
#  body
#    // box-sizing: border-box : consider it, but study the impact first
#    layout()
#    typography()

#    > header
#      border-top: 3px solid #000000
#      margin: 33px 0em 33px 0em
#      h1
#        font-size: huge
#//        line-height: 66px
#//        font-weight: bold
#//        padding-top: 7px
#//        margin-bottom: -7px
#        //margin: 0em 0em 0em 0em //margin: 0.25em 0em 0.25em 0em
#      .author
#        line-height: 33px
#        padding-top: 31px
#        margin-bottom: 2px
#        //margin: 0.25em 0em 0.5em 0em
#        font-size: medium
#        //font-weight: bold
#      .date
#        line-height: 33px
#        //margin: 0.25em 0em 0.5em 0em
#        font-family: "Alegreya SC", serif
#        font-size: medium
#        font-weight: normal
#      p
#        font-size: medium
#        font-weight: normal
#    a
#      text-decoration: none
#      outline: 0;
#    a:hover
#      text-decoration: none

#    h1, h2, h3, h4, h5, h6
#      a:hover
#        text-decoration: none;

#    a:link
#      color: black

#    a:visited
#      color: black

#    h1
#      line-height: 1.5em
#      font-size: large
#      font-weight: bold

#    h2
#      font-size: 28px
#      font-weight: bold

#    h3, h4, h5, h6
#      font-size: 22px
#      font-weight: bold
#      float: left
#      margin-right: 1em
#      margin-top: 0px
#      margin-bottom: 0px

#    p
#      margin-top: 0em
#      margin-bottom: 1.5em

#    sup
#      vertical-align: super
#      fontSize: 14px

#    code
#      font-size: 22px//20.5px
#      font-family: Inconsolata

#    pre
#      overflow-x: auto
#      line-height: 33px//1.25
#      background-color: #ebebeb
#      margin-top: 1.5em
#      margin-bottom: 1.5em
#      padding: 0.75em 1.5em 0.75em 1.5em // 0.5em 1em 0.5em 1em

#    blockquote
#      background: #f9f9f9
#      border-left: 5px solid #ccc
#      margin: 1em 2em
#      padding: 0.5em 1em
#      p
#        &:first-child
#          margin-top: 0em;
#        &:last-child
#          margin-bottom: 0em;

#    ul
#      list-style-type: disc
#      li
#        marginLeft: 2em

#    img
#      width: 32em

#    figcaption
#      margin-top: 0.0em
#      text-align: center
#      font-style: italic

#    figure
#      margin: 0px

#    .tombstone
#      float: right

#    span.MathJax_SVG
#      svg
#        color: black;


# Commande-Line API
# ------------------------------------------------------------------------------
window = undefined

main = ->
  argv = process.argv[2..]
  {h: h1, html: h2, s: s1, style: s2, _: inputHTMLFilenames} = parseArgs(argv)
  HTMLFilename = if h1 then h1 else h2
  CSSFilename = if s1 then s1 else s2

  # Generate the CSS
  aboutCSS = {}
  absurd (api) ->
    absurdify api
    api.compile (error, css) ->
      if error?
        console.error error
        process.exit 1
      else
        if CSSFilename?
          try
            fs.writeFileSync CSSFilename, css, "utf-8"
          catch error
            console.log error
            process.exit 1
          aboutCSS.external = CSSFilename 
        else
          aboutCSS.inline = css

  # Transform the HTML (if any)
  if inputHTMLFilenames.length or HTMLFilename?
    jsdom.defaultDocumentFeatures =
      FetchExternalResources: false
      ProcessExternalResources: off
      SkipExternalResources: /.*/
    if inputHTMLFilenames.length
      # Load the original document
      html = fs.readFileSync inputHTMLFilenames[0], "utf-8"
      window = jsdom.jsdom().defaultView
      doc = window.document.open "text/html", "replace"
      doc.write html
      doc.close()
    else
      window = jsdom.jsdom().defaultView

    $ = jquery(window)
    if aboutCSS.external? # Link the stylesheet
      link = $ "<link>",
        href: aboutCSS.external 
        rel: "stylesheet" 
        type: "text/css"
      $("head").append link
    else # Inline the stylesheet
      style = $ "<style></style>",
        type: "text/css"
        text: aboutCSS.inline
      $("head").append style

    # Perform the other DOM transformations
    domify($) 

    # Write the result
    outputString = window.document.documentElement.outerHTML
    if HTMLFilename?
      fs.writeFileSync HTMLFilename, outputString, "utf-8"
    else
      console.log outputString
  else # no HTML in or out, output the stylesheet (if no CSS output file).
    if aboutCSS.inline?
      console.log aboutCSS.inline

main()
# hangs in there for quite a while. Why ? Is it the mathjax stuff. 
# Nah, can't be ... Arf, maybe: even when I get rid of the initial mathjax
# in the doc, that could trigger some long interaction.
#process.exit() # this is nasty: we stop the stuff so that mathjax can't load
               # it's stuff & mutate the DOM ... this is fragile.
               # could we do the opposite and let mathjax perform all the
               # rendering (server-side ?).
# rk: "Domini" apparently doesn't process script tags
# Nota: we are gonna get in trouble with all the scripts that we may add
#       that are going to get processed ... Think of it more.

## Try:
#require("jsdom").defaultDocumentFeatures = {
#    FetchExternalResources: ["script"],
#    ProcessExternalResources: false
#};

# The stuff is adding an extra MathJax-related script tag in head, evenwhen
# I don't have any network on ... But at least it doesn't hang anymore.