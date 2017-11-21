#!/usr/bin/env coffee

# Usage: 
#
#     $ eul-style [--theme=NAME] [--style=style.css] [--html=output.html] [input.html]`


# TODO
# ------------------------------------------------------------------------------
#
#   - encapsulate variable for different themes
#
#   - theme options?
#
#   - add a "js" field to components: stuff that should be activated at runtime.
#     many question to solve; these components are typically external 
#     coffeescript programs, that have requirements and say that follow node's
#     packaging principles. One could say that exports should be a function
#     that can take an object configuration argument.
#     How to go from here to the runtime? We call browserify on them to
#     begin with? How to deal with the config (some part of the styling 
#     state that should be passed along ... maybe the "component" 
#     (holder of the css, html, etc. stuff) itself? I would include the
#     script generated by browserify then forge a small code snipper that
#     includes a JSONified version of the object and call the function of
#     the browserified stuff (--standalone) with this argument?
#     Q: how shipping files with this module ? and get them ?
#     (as "package data") ... Mmm can't find easy answer here ...
#     Well, I may have to use __dirname ...
#
#   - How to do it: 
#
#       - specify scripts to embed as (coffee or js)scripts or FUNCTIONS 
#         (to be toString'd)? How do we know if the script is cs or js?
#         There are a also quite a couple of catches with the second options, 
#         but well, ... toString would automatically compile this stuff with
#         coffescript, which is nice! Only accept js strings? Call the cs
#         compiler to specify cs scripts? Yeah, that works beautifully.
#         Maybe some option should be used to avoid the protection of
#         symbols (think "bare") but I am not even sure ...
#
#       - now, about DEPENDENCIES: we need to specifiy them somehow.
#         I am talking about npm modules dependencies. Collect them 
#         all, then create a giant bundle from all scripts that are
#         specified at once? Or just a big dependency and include 
#         every script specified individually (with the browserify "-r"
#         option)?
#
#  TODO: replace absurd.js with custom code.


# Requirements
# ------------------------------------------------------------------------------

# Standard Node Library
fs = require "fs"
path = require "path"
process = require "process"
{exec, execSync} = require "child_process"

# Third-Party Libraries
#absurd = do -> # workaround for absurd.js (confused by command-line args).
#  argv = process.argv
#  process.argv = ["coffee"]
#  absurd = require "absurd"
#  process.argv = argv
#  absurd
coffeescript = require("coffee-script")
jquery = require "jquery"
jsdom = require "jsdom"
parseArgs = require "minimist"
_ = require "lodash"

# Javascript Helpers
# ------------------------------------------------------------------------------
type = (item) ->
  Object::toString.call(item)[8...-1].toLowerCase()

String::capitalize = ->
    this.charAt(0).toUpperCase() + this.slice(1)

String::decapitalize = ->
    this.charAt(0).toLowerCase() + this.slice(1)

String::startsWith = (string) ->
    this[...string.length] is string

# CSS
# ------------------------------------------------------------------------------

toDash = (string) ->
  string.replace(/([a-z])([A-Z])/g, "$1-$2").toLowerCase()

splitByComma = (string) ->
  string = string.trim()
  pattern = /('[^']+'|"[^"]+"|[^,]+)/g
  matches = string.match pattern
  match.trim() for match in matches

makeCss = (stylesheet, object=false) ->
  output = {} # keys: selectors, values: property-value object 
  for selector, kvs of stylesheet
    output[selector] = {}
    for k, v of kvs
      if type(v) isnt "object"
        output[selector][toDash(k)] = v
      else
        rule = "#{k}": v
        for selector_, kvs_ of makeCss(rule, true)
          selectors = splitByComma(selector)
          selector_s = splitByComma(selector_)
          combined_selectors = []
          for k1 in selectors
            for k2 in selector_s
              if "&" in k2
                key = k2.replace "&", k1
              else
                key = "#{k1} #{k2}"
              combined_selectors.push key
          output[combined_selectors.join ", "] = kvs_
  if object
    output
  else
    lines = []
    for selector, kvs of output
      lines.push "#{selector} {"
      for k, v of kvs
        lines.push "  #{k}: #{v};"
      lines.push "}"
    lines.join "\n"


# Insert Scripts for Runtime
# ------------------------------------------------------------------------------

insert_script = (options) ->
    # Use DOM API instead of JQuery that adds weird script tags
    # (the Node DOM actually tries to interpret the script AFAICT ...)
    script = window.document.createElement "script"
    script.type = "text/javascript"
    if options.src?
      script.src = options.src
    if options.text? 
      script.text = options.text
    window.document.head.appendChild script


# Classic Theme
# ------------------------------------------------------------------------------

defaults =
  css:
    "*":
      margin: 0
      padding: 0
      border: 0
      boxSizing: "content-box" # "border-box" ? 
      # Study the transition (changes aspect)
      fontSize: "100%"
      font: "inherit"
      verticalAlign: "baseline"
    html:
      lineHeight: 1
    "ol, ul":
      listStyle: "none"
    "blockquote, q":
      "quotes": "none"
      "&:before":
        content: "none"
      "&:after":
        content: "none"
    table:
      borderCollapse: "collapse"
      borderSpacing: 0
  html: ->
    undefined # detect before add
    #$("head").append $("<meta charset='UTF-8'></meta>")

# Colors
color = "black" # TODO: remove global variable

# Typography

typography = do ->
  base = __base = 24
  __lineHeight = 1.5
  lineHeight = __base * __lineHeight # lineHeight in pixels
  ratio = __ratio = Math.sqrt(2)
  # TODO: try calc stuff instead (but rounding is lost? Worse, browser-dependent?)
  small  = Math.round(__base / __ratio) + "px"
  medium = Math.round(__base) + "px"
  large  = Math.round(__base * __ratio) + "px"
  xLarge = Math.round(__base * __ratio * __ratio) + "px"

  html = -> # TODO: check that the link is not already here ?
    family = "Alegreya+Sans:400,100,100italic,300,300italic,400italic,500,500italic,700,700italic,800,800italic,900,900italic|Alegreya+Sans+SC:400,100,300,500,700,800,900,100italic,300italic,400italic,500italic,700italic,800italic,900italic|Alegreya+SC:400,400italic,700,700italic,900,900italic|Alegreya:400,700,900,400italic,700italic,900italic"
    link = $ "<link>",
      href: "https://fonts.googleapis.com/css?family=#{family}"
      rel: "stylesheet"
      type: "text/css"
    $("head").append link

  css = 
    html:
      "--base": __base
      "--lineHeight": __lineHeight
      lineHeight: lineHeight + "px" # use rems instead.
      fontSize: medium
      fontFamily: "Alegreya, serif"
      fontStyle: "normal"
      fontWeight: "normal"
      em:
        fontStyle: "italic"
      strong:
        fontWeight: "bold"
      textRendering: "optimizeLegibility"
      textAlign: "left"
      "p, .p": # TODO: remove margin when p is "boxed" and last.
        marginBottom: lineHeight + "px"
        textAlign: "justify"
        hyphens: "auto"
        MozHyphens: "auto"
      section: # TODO: see above wrt boxed content.s
        marginBottom: lineHeight + "px"

   return {base, lineHeight, ratio, small, medium, large, xLarge, html, css}

      
layout =
  css:
    html:
      "main": # pfff not body (adapt pandoc build to have another top-level component.
            # the easiest thing to do is probably to have a "main" class, it's
            # flexible wrt the actual tag soup ...)

        # Nota: this is probably the only place where we want content-box model,
        #       so define border-box in defaults to everything.

        boxSizing: "content-box" # check this ... check that 32 em applies to
        maxWidth: "32em"         # the text WITHOUT the padding.
        margin: "auto"
        padding: typography.lineHeight + "px" # use rems instead (1.5rem)?

#toc =
#  html: ->
#    $("body").prepend("<nav class='toc'></nav>")
#  
#  css:
#    ".toc":
#      position: "absolute"
#      left: "0"
#      width: "0"
#    "main":
#      marginLeft: "20%"


# TODO: 
#   - solve bugs with duplicated entries in TOC. .......................... DONE
#     That's related to how pandoc generates TOC entries for headings that
#     contain links :(. It generate nested links, which is not kosher.
#     Correct this at the eul-link level ? Hope that the nested anchors are
#     still accessible as such (not already corrected) and "disable" the
#     inner link? Otherwise ... find another plan ... Detect multiple
#     anchors (in childrens of li's) and patch the result.
#
#   - offset a little (downward) the "Section ???" flag.
#
#   - solve space that is too wide at the end of the TOC.
#     adapt by converting the last padding into a margin,
#     that should collapse with the following header margin.
#     Mmmmmm .... will look like shit if I have to change the
#     background color ... add some solid top border instead?
#     Why the fuck is it not already there?
#     Because I am putting it on the top. Add a bottom stuff
#     for the last element too.
#
#   - analyze tagged contents, substitute labels.
#
#   - organize tags ? Group by kind ? Associate proofs with the statement?
#
#   - section / toc for figures (what title ?). Title starts the caption
#     and is bold (whenever it exists)?
#
#   - adjust indents
#
#   - caret / arrow stuff (inactive for now)
#
#   - add SC Light Section + number on top of top-level heading
#
#   - rule between top-level sections
#
#   - control spacing.
#
#   - TODO: align badges properly, try some color schemes ? (grey first)?

sanitize = ($, elt) -> # fix the nested anchor problem in TOCs.
  # (this is illegal, the DOM automatically closes the first anchor when
  # the second one comes.
  # Quick & dirty fix: if the elt starts with two anchors, 
  # remove the first one.
  children = elt.children()
  if children.length >= 2
    first = children[0]
    second = children[1]
    if first.tagName is "A" and second.tagName is "A"
      $(first).remove()

trim_period = (text) -> 
  if text[text.length-1] is "." and text[text.length-2] isnt "."
    text = text[...-1]
  return text

split_types_text = (text) ->
  section_types = "Theorem Lemma Proposition Corollary 
    Definition Remark Example Examples 
    Question Questions Answer Answers".split(" ")
  separators = "–&,"
  pattern = "(" + (s for s in separators).join("|") + ")" 
  sep_regexp = new RegExp(pattern)
  parts = text.split(sep_regexp)
  types = []
  while parts.length
    if parts[0].trim() in section_types
      types.push parts.shift().trim()
      parts.shift() # remove the separator
    else
      break
  text = parts.join("").trim()
  return [types, text]
      
wrapInBadge = (label) ->
  label = label[...3].toLowerCase()
  $("<span class='badge'>#{label}<span>")

toc = 
  html: ->
    toc = $("nav#TOC")
    if toc.length
      toc.find("li").each -> sanitize($, $(this))
      top_lis = toc.children("ul").children("li")
      top_lis.addClass "top-li"

      anchors = toc.find("a")
      for anchor in anchors
          text = $(anchor).text()
          if text.startsWith("Proof")
            $(anchor).remove()
          text = trim_period text
          [types, subtext] = split_types_text text
          #console.warn "*", [types, subtext]
          if types.length
              $(anchor).html(subtext or text)
              #$(anchor).parent().append(wrapInBadge($, t)) for t in types

              # TODO: stack multiple badges (use z-index) ?

              # TMP: keep only the first type tag.
              $(anchor).parent().prepend wrapInBadge(types[0])
              #$(anchor).parent().prepend(wrapInBadge(t)) for t in types.reverse()
              
      #top_lis.prepend($("<i class='fa fa-caret-down'></i>"))
      #top_lis.children("i").after(" ")
      for li, n in top_lis
        $(li).prepend("<p class='section-flag'>section #{n + 1}</p>")
      section = $("<section id='contents' class='level1' ></section>")
      section.append($("<h1><a href='#contents'>Contents</a></h1>"))
      section.append(toc.clone())
      toc.replaceWith(section)

  css:
    "nav#TOC > ul":
      position: "relative"
      fontWeight: "bold"
      "> *":
        marginBottom: typography.lineHeight + "px"
      li:
        listStyleType: "none"
        marginLeft: 0
        paddingLeft: 0
      ul:
        li: 
          marginLeft: typography.lineHeight + "px"
          fontWeight: "normal"
    ".section-flag": # TODO: shift a bit down.
      lineHeight: typography.lineHeight + "px"
      fontSize: typography.small
      fontWeight: "300"
      fontFamily: "Alegreya Sans SC"
      marginBottom: 0
    "nav#TOC > ul > li.top-li":
      marginBottom: 0
      paddingBottom: typography.lineHeight
      borderWidth: "2px 0 0 0"
      borderStyle: "solid"
    "nav#TOC > ul > li.top-li:last-child":
      borderWidth: "2px 0 2px 0"
    "nav#TOC .badge":
      position: "relative"
      bottom: "0.13em"
      fontFamily: "Alegreya Sans SC"
      fontWeight: "300"
      fontSize: typography.small
      display: "inline-block"
      lineHeight: "1.2em"
      height: "1.2em"
      width: "2em"
      textAlign: "center"
      #borderStyle: "solid"
      #borderWidth: "1px"
      borderRadius: "2px"
      backgroundColor: "#f0f0f0"
      verticalAlign: "baseline"
      boxShadow: "0px 1.0px 1.0px #aaa"
      marginRight: "1em"
      #marginLeft: "1em"
#      ":hover":
#        background: "#fff0f0"

#badge = 
#  css:
#    ".badge":
#      whiteSpace: "nowrap"
#      span:
#        textTransform: "lowercase"
#        position: "relative"
#        bottom: "0.13em"
#        fontFamily: "Alegreya Sans SC"
#        fontWeight: "300"
#        fontSize: small
#        display: "inline-block"
#        lineHeight: "1.2em"
#        height: "1.2em"
#        #width: "2em"
#        textAlign: "center"
##        borderStyle: "solid"
##        borderWidth: "1px"
##        color: "#b0b0b0"
#        #borderRadius: "2px"
#        backgroundColor: "#f0f0f0"
#        verticalAlign: "baseline"
#        boxShadow: "0px 1.0px 1.0px #aaa"
##        marginRight: "1em"
#        padding: "0 0.5em 0 0.5em"
#        "&:first-child":
#          borderRadius: "2px 0 0 2px"
#        "&:last-child":
#          borderRadius: "0 2px 2px 0"
#      ".key":
#        backgroundColor: "#707070"
#        color: "white"
#        fontWeight: "normal"
#        boxShadow: "0px 1.0px 1.0px #a0a0a0"
#        #textShadow: "1px 1px 0px #d0d0d0"
      

notes =
  html: ->
    notes = $("section.footnotes")
    notes.attr(id: "notes")
    if notes.length
      notes.prepend $("<h1><a href='#notes'>Notes</a></h1>")
      toc_ = $("nav#TOC")
      if toc_.length
        toc_.children().first().append $("<li><a href='#notes'>Notes</a></li>")

  css: {}

header =
  css:
    main:
      "> header, > .header, > #header": # child of body is probably not appropriate ...
                  # instead, search for "a top-level section" (main, article, 
                  # class="main", etc.) and select the headers that are children
                  # -- not descendants -- of these.
        #borderTop: "3px solid #000000"
        marginTop: 2.0 * typography.lineHeight + "px" # not sure that's the right place.
        marginBottom: 2.0 * typography.lineHeight + "px"
        h1:
          fontSize: typography.xLarge
          lineHeight: 1.5 * typography.lineHeight + "px"
          marginTop: 0.0 * typography.lineHeight + "px" # compensate somewhere else, here
          marginBottom: typography.lineHeight + "px"    # is not the place.
          fontWeight: "bold"
        ".author":
          fontSize: typography.medium
          lineHeight: typography.lineHeight + "px"
  #        paddingTop: "1.5px" # makes the "true" baseline periodic (48 px)
          marginBottom: 0.5 * typography.lineHeight + "px"
          fontWeight: "normal"
        ".date":
          fontFamily: 'Alegreya SC, serif'
          lineHeight: typography.lineHeight + "px"
          fontSize: typography.medium
          fontWeight: "normal"
          marginBottom: 0.5 * typography.lineHeight + "px"
          float: "none" # it's a pain to have to put that here to counteract
                        # the "float: left" used in "normal" h3 ...
                        # OTOH, this date and author stuff probably shouldn't
                        # be separate headings ...

  # TODO: remove the float: left; instead turn the heading inline and insert it
  #       into the next paragraph (if any).

headings =
  css:
    h1:
      fontSize: typography.large
      fontWeight: "bold"
      lineHeight: 1.25 * typography.lineHeight + "px"
      marginTop: 2.0 * typography.lineHeight + "px"
      marginBottom: 0.75 * typography.lineHeight + "px"
    h2:
      fontSize: typography.medium
      fontWeight: "bold"
      lineHeight: typography.lineHeight + "px"
      marginBottom: 0.5 * typography.lineHeight + "px"

    "h3, h4, h5, h6":
      fontSize: typography.medium
      fontWeight: "bold"
      marginRight: "1em"
      display: "inline"
  html: ->
    subsubheadings = $("h3, h4, h5, h6")
    for heading in subsubheadings
      next = $(heading).next()
      if next.is("p")
        next.replaceWith("<div class='p'>" + next.html() + "</span>")
        p = $(heading).next()
        p.prepend(heading)
      if next.is("ul, ol")
          $("<br>").insertAfter($(heading)) 


links =
  css:
    a:
      cursor: "pointer"
      textDecoration: "none"
      outline: 0
      "&:hover":
        textDecoration: "none"
      "&:link":
        color: color
      "&:visited":
        color: color

footnotes =
  css:
    sup:
      verticalAlign: "super"
      lineHeight: 0

lists =
  css:
    li:
        listStyleType: "none"
        listStyleImage: "none"
        listStylePosition: "outside"
        marginLeft: 1 * typography.lineHeight + "px"
        paddingLeft: "0.5em"    
    ul:
      li:
        listStyle: "disc"
    ol:
      li:
        listStyle: "decimal"

quote =
  css:
    blockquote:
      borderLeftWidth: "thick"
      borderLeftStyle: "solid"
      borderLeftColor: "black"
      padding: 1 * typography.lineHeight + "px"
      marginBottom: 1 * typography.lineHeight + "px"
      "p:last-child":
        marginBottom: "0px"

code =
  html: ->
    family = "Inconsolata:400,700"
    link = $ "<link>",
      href: "https://fonts.googleapis.com/css?family=#{family}"
      rel: "stylesheet"
      type: "text/css"
    $("head").append link
  css:
    code:
      fontSize: typography.medium
      fontFamily: "Inconsolata"
    pre:
      overflowX: "auto"
      backgroundColor: "#ebebeb"
      marginBottom: 1 * typography.lineHeight + "px"
      paddingLeft: typography.lineHeight + "px"
      paddingRight: typography.lineHeight + "px"
      paddingTop : 1 * typography.lineHeight + "px"
      paddingBottom : 1 * typography.lineHeight

# Image & Figures
# ------------------------------------------------------------------------------

width_percentage = (image_filename) ->
  latex_width_in = 345.0 / 72.27 # standard LaTeX doc: 345.0 TeX points.
  density = execSync("identify -format '%x' '" + image_filename + "'").toString()
  # TODO: check that the unit is cm
  # NOTA: depending on the version of image magick, we have either the number
  #       and the unit or only the number and the unit in a different field.
  density = density.split(" ")[0]
  ppi = density * 2.54
  width_px = execSync("identify -format '%w' '" + image_filename + "'").toString()
  width_in = width_px / ppi
  return Math.min(100.0 * width_in / latex_width_in, 100.0)
 
image =
  html: ->
    # TODO: consider bitmaps, set the appropriate width wrt 
    #       "print size" (use image magic).
    images = $("img")
    for img in images
      filename = $(img).attr("src")
      if filename[-3..] in ["jpg", "png"]
          $(img).css("width", width_percentage(filename) + "%")
  css:
    img:
      display: "block"
      marginLeft: "auto"
      marginRight: "auto"
      width: "100%"
      height: "auto"

figure =
  css:
    figure:
      marginBottom: typography.lineHeight + "px"
      textAlign: "center"
    figcaption:
      display: "inline-block"
      fontStyle: "italic"
      textAlign: "justify"
      #align: "left"

# ------------------------------------------------------------------------------

table =
  html: ->
    $("table").wrap("<div class='table'></div>");
  css:
    ".table":
      overflowX: "auto"
      overflowY: "hidden"
      width: "100%"
      marginBottom: typography.lineHeight + "px"
    table:
      padding: 0 # transfer in reset/defaults ?
      marginLeft: "auto"
      marginRight: "auto"
      borderSpacing: "1em " + (typography.lineHeight - typography.base) + "px"
      borderCollapse: "collapse"
      borderTop: "medium solid black"
      borderBottom: "medium solid black"
    thead:
      borderBottom: "medium solid black"
    "td, th":
      padding: 0.5*(typography.lineHeight - typography.base) + "px" + " 0.5em"

# TODO: need to implement the overflow without an extra "block" that would
#       get the formula "out" of the current parapgraph and mess up spacing.

math = # if $(".math").length guard ? "force" option?
  css:
    ".MJXc-display":
      overflowX: "auto"
      overflowY: "hidden"
      width: "100%"
  html: ->
    # Mathjax header
    old = $("head script").filter (i, elt) -> 
      src = $(elt).attr("src")
      /mathjax/.test src
    old.remove()
    insert_script
      src: "https://cdnjs.cloudflare.com/ajax/libs/mathjax/2.7.0/MathJax.js?config=TeX-AMS_CHTML" 
      text: "MathJax.Hub.Config({
               jax: ['output/CommonHTML'], 
               CommonHTML: {
                 scale: 100,
                 linebreaks: {automatic: false}, 
                 mtextFontInherit: true}
            });"
      # NOTA: the linebreaking is not responsive actually for inlined equations,
      #       which is what I was searching for (AFAICT)
      # NOTA: using mtextFontInhserit: true is tempting to get Alegreya into
      #       equations when the text is required; the problem is that the
      #       0.9 scaling would be applied to the font ... Otherwise, I may
      #       schedule, when the Mathjax rendering is done as search for all
      #       spans with mjx-text class and unset their font-size style attribute?
      #       --
      # This link <https://groups.google.com/forum/#!topic/mathjax-users/v3W-daBz87k>
      # is interesting: experiments show that Alegreya declares perfectly its x-height,
      # but the Computer Modern fonts seems to underestimate it (and the rounded x
      # make things worse). Nah, forget it, on the paper it's perfect, it's only
      # that the LaTeX font -- for a given x-height -- seems "bigger" ... so it's not
      # a computation issue, it's a purely perceptual issue.
      # WOW, except that it's insane, the proper factor is set in two steps
      # (two nested font-size) whose global effect does the job ... so hacking this
      # would be probably painful and fragile ...
      #
      # did finally go back to the default scale; for most browser this is the
      # correct setting and it's also simpler. As a consequence, mtextFontInherit
      # can also be set to true without issues.


fontAwesome = 
  html: ->
    link = $ "<link>",
      rel: "stylesheet"
      href: "https://maxcdn.bootstrapcdn.com/font-awesome/4.5.0/css/font-awesome.min.css"
    $("head").append link

jQuery =
  html: ->
    insert_script src: "https://code.jquery.com/jquery-3.0.0.min.js"
  
demo =
  js: "js/demo.js"

title_case = (text) ->
  no_cap = "a an the and but or for nor aboard about above across after against
along amid among around as at atop before behind below beneath beside between
beyond by despite down during for from in inside into like near of off on onto
out outside over past regarding round since than through throughout till to
toward under unlike until up upon with within without".split(" ")

  no_cap = no_cap.concat [
    "un", "une", "de", "du", "des", "le", "la", "les", 
    "d", "l",
    "et", "ou", "ni", "mais", "donc", "car",
    "sur", "vers", "entre", "avec", "sans", "par",
  ]

  # Nota: this is improper: "d'ouverture" should become "d'Ouverture".
  #       the detection of "'" should trigger a subsplit and every part
  #       should be examined "as usual".


  parts = text.split(/[\s,;\-:.!?"'’&]+/)
  seps = text.split(/[^\s,;\-:.!?"'’&]+/)
  new_parts = []
  #console.error parts
  #parts = text.split(" ")
  for part in parts
    match = false
    for item in no_cap
      if type(item) is "string"
        pattern = new RegExp("^" + item + "$")
      else
        pattern = item 
      if part.match(pattern)
        match = true
        break
    if not match
      part = part.capitalize()
    new_parts.push part

  output = ""
  if seps[0] is ""
    first = seps
    second = new_parts
  else
    first = new_parts
    second = seps
  while first.length
    output += first.shift()
    if second.length
      output += second.shift()
  output

bibliography =
  html: ({bib}) ->

    find_entry = (id) ->
      for entry in bib
        if entry.id is id
          return entry
      undefined

    short_title = (text) ->
      parts = text.split(".")
      parts[0]

    authors = (entry) ->
      s = ""
      for author, i in entry.author
        if i > 0
          if i < entry.author.length - 1
             s += ", "
          else:
             s += " and "
        if author.literal?
          s += author.literal
        else
          dp = if author["dropping-particle"]? then " " + author["dropping-particle"] else ""
          s += author.given + dp + " " + author.family
      s

    year = (entry) ->
      entry?.issued?["date-parts"]?[0]?[0]

    refs = $("#refs")
    ref_ids = []
    for div in refs.children()
      ref_ids.push div.getAttribute("id")[4..]
    refs.html("<ol></ol>")
    list = refs.find("ol")
    for id in ref_ids
      list.append("<li id='ref-#{id}' style='margin-bottom:0.75em'></li>")
    for li in list.children()
        id = li.getAttribute("id")[4..]
        entry = find_entry(id)
        b64Data = Buffer(JSON.stringify(entry, null, 2)).toString("base64")
        b64Prefix = "data:application/json;charset=utf-8;base64,"
        b64 = b64Prefix + b64Data 
        $(li).append("<em>" + title_case(short_title(entry.title)) + "</em>")
        $(li).append("<br>")
        $(li).append(authors(entry) + ", " + year(entry) + ".")
        $(li).append("<br>")
        $(li).append("JSON: <a href='#{b64}'><i style='font-size:18px;position:relative;bottom:0.05em;' class='fa fa-file-text-o'></i></a>&nbsp;")
        if entry.URL?
          $(li).append(" / URL: <a href='#{entry.URL}'><i style='font-size:18px'class='fa fa-link'></i></a>")
        if entry.DOI?
          $(li).append("  / DOI: <a href='https://doi.org/#{entry.DOI}'><i style='font-size:18px'class='fa fa-link'></i></a>")


# ------------------------------------------------------------------------------
   
containsTombstone = (elt) ->
  if elt[0].outerHTML.indexOf("\\blacksquare") > -1
    return true
  return false 

proofs =
  html: ->
    # find proof sections
    sections = $("section")
    #console.log sections.length, sections
    proofSections = []
    for section in sections
      header = $(section).find("h3, h4, h5, h6").first()
      if header.length
        text = header.text()
        if text[..4] is "Proof"
          proofSections.push($(section))

    # split the section if a tombstone is found 
    # (unless it's the last paragraph).

    for section in proofSections
      split = false
      newSection = $("<section></section>")
      for paragraph in section.children()
        if split
          newSection.append($(paragraph)) 
        else if containsTombstone($(paragraph))
          split = true
      if newSection.children().length > 0
        section.after(newSection)
        
  js: "js/proofs.js"

classic = [
  jQuery, 
  defaults, 
  typography, 
  layout, 
  header, 
  headings, 
  links, 
  footnotes, 
  lists, 
  quote, 
  code, 
  image, 
  figure, 
  table, 
  math, 
  notes, 
  toc, 
  fontAwesome, 
  demo, 
  bibliography, 
  proofs]

# Modern/Slides Theme
# ------------------------------------------------------------------------------

modern = []

modern.push modern.defaults = 
  css:
    "*":
      margin: 0
      padding: 0
      border: 0
      boxSizing: "border-box"
      fontSize: "100%"
      font: "inherit"
      verticalAlign: "baseline"
    html:
      lineHeight: 1
    "ol, ul":
      listStyle: "none"
    "blockquote, q":
      "quotes": "none"
      "&:before":
        content: "none"
      "&:after":
        content: "none"
    table:
      borderCollapse: "collapse"
      borderSpacing: 0

# TODO: "sizes" should be fontSize & lineHeight objects instead
#       (and even maybe bundled with margins ?). Aria-hidden stuff?
#       Use blast or regexp and JQuery to deal with the code.
#       Apperently it's not merely aria-hidden ...
#       Mmmmm -moz-user-select:none works on Firefox.
#       Arf, the selection looks good with Opera, but the copy is
#       borked (even in the surge.sh example)

modern.push modern.typography = do ->
  base = 24 # 18 #24
  lineHeight = base * 1.5
  ratio = 2
  tiny  = Math.round(base / ratio) + "px"
  small  = Math.round(base / ratio) + "px"
  medium = Math.round(base) + "px"
  medium = 
    fontSize: Math.round(base) + "px"
    lineHeight: 1.5 * Math.round(base) + "px"
  large  = 
    fontSize: Math.round(base * ratio) + "px"
    lineHeight: 1.0 * Math.round(base * ratio) + "px"
  huge = 
    fontSize: Math.round(base * ratio * ratio) + "px"
    lineHeight: 1.0 * Math.round(base * ratio * ratio) + "px"

  html = ->
    family = "Source+Sans+Pro:200,200i,300,300i,400,400i,600,600i,700,700i,900,900i"
    link = $ "<link>",
      href: "https://fonts.googleapis.com/css?family=#{family}"
      rel: "stylesheet"
      type: "text/css"
    $("head").append link
    family = "Titillium+Web:200,200i,300,300i,400,400i,600,600i,700,700i,900"
    link = $ "<link>",
      href: "https://fonts.googleapis.com/css?family=#{family}"
      rel: "stylesheet"
      type: "text/css"
    $("head").append link
  css =
    html:
      fontSize: medium.fontSize
      lineHeight: medium.lineHeight
      fontStyle: "normal"
      fontWeight: "normal" # 300 #"normal" # fuck 300 is too thin and normal too fat.
      fontFamily: "Source Sans Pro, sans-serif"
      em:
        fontStyle: "italic"
      strong:
        fontWeight: "bold"
      textRendering: "optimizeLegibility"
      textAlign: "left"
      "p, .p, p.alt":
        fontFamily: "Titillium Web"
        fontSize: 24 + "px"
        color: "black"
        marginBottom: medium.lineHeight
        #textAlign: "justify"
#        hyphens: "auto"
#        MozHyphens: "auto"
        color: "#2f2f2f"
      section:
        marginBottom: medium.lineHeight # ???


  {base, lineHeight, ratio, tiny, small, medium, large, huge, html, css}

modern.push modern.headings = do ->
  mt = modern.typography
  css:
    h1:
      fontSize: mt.huge.fontSize
      fontWeight: 200
      lineHeight: mt.huge.lineHeight #1.25 * mt.lineHeight + "px"
      #marginTop: 2.0 * mt.lineHeight + "px"
      #marginBottom: 0.75 * mt.lineHeight + "px"
    h2:
      fontSize: mt.large.fontSize
      fontWeight: 200
      lineHeight: mt.large.fontSize #mt.lineHeight + "px"
      #marginBottom: 0.5 * mt.lineHeight + "px"
    "h3, h4, h5, h6":
      fontSize: mt.medium.fontSize
      lineHeight: mt.medium.lineHeight
      fontWeight: "bold"
      marginRight: "1em"
      display: "inline"

modern.push modern.layout = do ->
  mt = modern.typography
  css:
    html:
      hyphens: "auto"
      "-moz-hyphens": "auto"
      "-webkit-hyphens": "auto"
      "main, .main": 
        width: "100vw"
        height: "100vh"
        padding: mt.large.lineHeight #mt.huge.fontSize #"5vmax" # or something like 1 em for huge text?
      section:
        maxWidth: "32em"
        margin: "auto"
      header:
        marginBottom: mt.large.lineHeight
      ".textbox":
        padding: "1em"
        margin: "0 auto"
        boxShadow: "0 0 1em rgba(0,0,0,0.25)"
        #boxShadow: "0px 3px 5px 0px #656565" 
   
modern.push modern.math = math

modern.push modern.fontAwesome = fontAwesome

modern.push modern.jQuery = jQuery

# TODO: see how surge.sh is doing: animation, fade out of non-commands,
#       and copy text is only the commands FFS!
#       Mmmm the pre-wrap is NICE but sometimes the text cannot be
#       folded (as if it was a big word) --> need blast to get to the
#       letter level?
modern.push modern.code = do ->
  mt = modern.typography
  html: ->
    family = "Fira+Mono"#"Cousine"
    link = $ "<link>",
      href: "https://fonts.googleapis.com/css?family=#{family}"
      rel: "stylesheet"
      type: "text/css"
    $("head").append link
  css:
    # need to match the x-height differently in a paragraph.
    code:
      fontSize: "22px" #mt.medium.fontSize
      fontFamily: "Fira Mono" #"'Cousine', monospace"
    pre:
      fontSize: "22px" #mt.medium.fontSize
      display: "block"
      #maxWidth: "42em"
      whiteSpace: "pre-wrap"
      overflowX: "auto" # should be required but well ... see "# ========"
      boxShadow: "0 0 1em rgba(0,0,0,0.25)"
      borderRadius: "5px"
      color: "#e8e8e8"
      backgroundColor: "#404040"
      marginBottom: 1 * mt.medium.lineHeight
      paddingLeft: "1.5em"
      paddingRight: "1.5em"
      paddingTop: "1.5em"
      paddingBottom: "1.5em"

      code:
        fontSize: "20px" #mt.medium.fontSize
        lineHeight: "30px"
        display: "inline-block"
        maxWidth: "40em"

#modern.push modern.coffeescript = 
#  html: ->
#    insert_script src: "https://cdnjs.cloudflare.com/ajax/libs/coffee-script/1.12.7/coffee-script.js"

modern.push modern.animation =
  html: ->
    insert_script src: "https://cdnjs.cloudflare.com/ajax/libs/gsap/1.20.2/TweenMax.min.js"

modern.push modern.blast =
  js: "js/blast.js"


# Apply Style Components
# ------------------------------------------------------------------------------

_theme = undefined

cssify = (options) ->
  csss = []
  for elt in _theme
    if elt.css?
      css_ = elt.css
      if type(css_) is "function"
        css_ = css_(options)
      csss.push css_
  rules = _.merge({}, csss...)
  makeCss rules      

domify = (options) ->
  for elt in _theme
    if elt.html?
      elt.html(options)

scriptify = (options) ->
  for elt in _theme
    if elt.js?
      js = elt.js
      if type(js) is "function"
        js = js(options)
      jsPath = path.join(__dirname, elt.js)
      text = fs.readFileSync jsPath, "utf8"
      insert_script text: text

# Commande-Line API
# ------------------------------------------------------------------------------
window = undefined
$ = undefined

main = ->
  argv = process.argv[2..]
  args = parseArgs argv
  HTMLFilename = if args.h then args.h else args.html
  CSSFilename = if args.s then args.s else args.style

  bibliographyFilenames = if args.b then args.b else args.bibliography
  theme = if args.t then args.t else if args.theme then args.theme else "classic"
  inputHTMLFilenames = args._

  # Theme selection
  _theme = eval(theme) # TODO: error handling, theme dict, etc.

  # If present, bibliographyFilename shall be a CSL json file.
  if bibliographyFilenames?
    if type(bibliographyFilenames) is "string"
      bibliographyFilenames = [bibliographyFilenames]
    bib_json = []
    for bibliographyFilename in bibliographyFilenames
      extra_bib_json = JSON.parse fs.readFileSync(bibliographyFilename, "utf8")
      bib_json = bib_json.concat bib_json, extra_bib_json  
  options = {bib: bib_json}

  # Generate the CSS
  aboutCSS = {}
  css_text = cssify options
  if CSSFilename?
    try
      fs.writeFileSync CSSFilename, css_text, "utf-8"
    catch error
      console.log error
      process.exit 1
    aboutCSS.external = CSSFilename 
  else
    aboutCSS.inline = css_text

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
    domify(options) 

    # Include JS scripts required at runtime
    scriptify(options)

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

