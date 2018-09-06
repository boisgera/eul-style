#!/usr/bin/env coffee

# Usage
# ------------------------------------------------------------------------------
#
#     $ eul-style [--theme=NAME]         # 'classic'
#                 [--style=output.css] 
#                 [--html=output.html] 
#                 [input.html]
#


# Imports
# ------------------------------------------------------------------------------

# Standard Node Library
fs               = require "fs"
path             = require "path"
process          = require "process"
{exec, execSync} = require "child_process"

# Third-Party Libraries
coffeescript = require "coffee-script"
jquery       = require "jquery"
jsdom        = require "jsdom"
parseArgs    = require "minimist"
_            = require "lodash"

# Custom Libraries
cssify = require "@boisgera/cssify"


# Javascript Helpers
# ------------------------------------------------------------------------------
type = (item) ->
  Object::toString.call(item)[8...-1].toLowerCase()

String::capitalize = ->
    this[...1].toUpperCase() + this[1...]

String::decapitalize = ->
    this[...1].toLowerCase() + this[1...]
    this.charAt(0).toLowerCase() + this.slice(1)

String::startsWith = (string) ->
    this[...string.length] is string


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



# CSS Reset
# ------------------------------------------------------------------------------
defaults =
  css:
    "*":
      margin: 0
      padding: 0
      border: 0
      boxSizing: "content-box" # transition to "border-box" ? study the impact.
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
    undefined # detect before add:
    #$("head").append $("<meta charset='UTF-8'></meta>")

# ### Colors # TODO: add greys, find naming scheme (have a look at
#            # the names used in color watches, and variants/qualifiers
#            # (darker, lighter, etc.
#            # TODO: find all places where i use color, reduce the
#            # number of greys.
color = 
  css: 
    html: 
      "--color": "black"

# Typography
# ------------------------------------------------------------------------------

###
NOTA: We use quantities as numbers, without explicit units in javascript
since this is the only sane way to make computations.
OTOH  we have to track/remember what their unit is and
convert it to a string with the appropriate unit for CSS.
In CSS, we can also do some (limited) computations with `calc`
if this is needed.

When we need these values for other components, should we pull
the info from js or from css? If we do from JS, we need to add
the unit back but we have a decent syntax otherwise (namespaced name, etc.); 
from CSS we have to use the weird calc/var and "--" notation combo
but it may change at runtime (*maybe*, if we put ALMOST ALL computations
in CSS, but we don't use this, right? And we don't need this either!)

###

# TODO: rethink the JS vs CSS for variables (get rid of custom properties ?)

typography = do ->
  baseFontSize   = 24 # [px]
  baseLineHeight = 1.5 * baseFontSize # [px]
  scaleRatio     = Math.sqrt(2) # (unitless)

  # Modular scale
  small  = Math.round(baseFontSize / scaleRatio)
  medium = Math.round(baseFontSize)
  large  = Math.round(baseFontSize * scaleRatio)
  xLarge = Math.round(baseFontSize * scaleRatio * scaleRatio)

  # TODO: rethink the "family" name & concept? What happens when
  #       your design mixes several fonts? For example when you
  #       need to deal with code? Add an (optional) positional 
  #       argument ? Which would be the "type"/"role" ?
  #       E.g. it could be "code" ? Dunno ...

  # Family variant selector. Would "variant" be a better name here?
  family = (options) ->
    options ?= {}
    options.serif ?= true
    options.smallCaps ?= false

    name = "Alegreya"
    if not options.serif
      name += " Sans"
    if options.smallCaps
      name += " SC"
    name = "'#{name}'"

    # Shall we do this? At all? And here?
    if options.serif
      name += ", serif"
    else
      name += ", sans-serif"
    name

  {
    baseFontSize, baseLineHeight, scaleRatio, 
    
    small, medium, large, xLarge,

    family,

    html: ->
      family = "Alegreya: 400,700,900,400italic,700italic,900italic" +
        "|Alegreya+SC:400,700,900,400italic,700italic,900italic" +
        "|Alegreya+Sans:100,300,400,500,700,800,900,100italic,300italic,400italic,500italic,700italic,800italic,900italic" +              
        "|Alegreya+Sans+SC:100,300,400,500,700,800,900,100italic,300italic,400italic,500italic,700italic,800italic,900italic"
      link = $ "<link>",
        href: "https://fonts.googleapis.com/css?family=#{family}"
        rel: "stylesheet"
        type: "text/css"
      $("head").append link

    css:
      html:
        "--base-font-size": baseFontSize + "px"
        "--base-line-height": baseLineHeight + "px"
        "--scale-ratio": scaleRatio
        "--small": small + "px"    
        "--medium": medium + "px"
        "--large": large + "px"
        "--x-large": xLarge + "px"

        lineHeight: "var(--base-line-height)"
        fontSize: medium + "px"
        fontFamily: family serif: true
        fontStyle: "normal"
        fontWeight: "normal"
        em:
          fontStyle: "italic"
        strong:
          fontWeight: "bold"
        textRendering: "optimizeLegibility"
        textAlign: "left"
        "p, .p": # TODO: remove margin when p is "boxed" and last.
          marginBottom: "var(--base-line-height)"
          textAlign: "justify"
          hyphens: "auto"
          MozHyphens: "auto"
        section: # TODO: see above wrt boxed content.
          marginBottom: "var(--base-line-height_px)"
  }
      
# TODO: import lineHeight somehow as "unit" in layout?

layout =
  css:
    html:
      "main": # pfff not body (adapt pandoc build to have another top-level component.
              # the easiest thing to do is probably to have a "main" class, 
              # it's flexible wrt the actual tag soup ...)
              # I don't remember exactly but am I using some preprocessing
              # to introduce "main" elt in pandoc output?
        # Nota: this is probably the only place where we want content-box model,
        #       so define border-box in defaults to everything.

        boxSizing: "content-box" # check this ... check that 32 em applies to
        maxWidth: "32em"         # the text WITHOUT the padding.
        margin: "auto"
        padding: "var(--base-line-height)"


# Table of Contents
# ------------------------------------------------------------------------------

sanitize = ($, elt) -> # fix the nested anchor problem in TOCs.
  # (this is illegal, the DOM automatically closes the first anchor 
  # when the second one opens).
  # Quick & dirty fix: if the elt starts with two anchors, 
  # remove the first one.
  children = elt.children()
  if children.length >= 2
    first = children[0]
    second = children[1]
    if first.tagName is "A" and second.tagName is "A"
      $(first).remove()

removeEmptySections = (toc) ->
  for li in toc.find("li")
    if $(li).find("a").text() == ""
      $(li).remove()
  # Need to remove empty uls now (from below to the top?)
    
trim_period = (text) -> 
  if text[text.length-1] is "." and text[text.length-2] isnt "."
    text = text[...-1]
  return text

split_types_text = (text) ->
  section_types = "
    Theorem Lemma Proposition Corollary 
    Definition Remark Example Examples 
    Question Questions Answer Answers".split(" ")
  separators = "–&,"
  pattern = "(" + (s for s in separators).join("|") + ")" 
  sep_regexp = new RegExp(pattern)
  parts = text.split(sep_regexp)
  types = []
  while parts.length > 0
    if parts[0].trim() in section_types
      types.push parts.shift().trim()
      parts.shift() # remove the separator
    else
      break
  text = parts.join("").trim()
  return [types, text]
      
Badge = (label) ->
  label = label[...3].toLowerCase()
  $("<span class='badge'>#{label}<span>")

toc = 
  html: ->
    toc = $("nav#TOC")

    if toc.length
      toc.find("li").each -> sanitize($, $(this))

      removeEmptySections(toc)

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
          if types.length
              $(anchor).html(subtext or text)

              # TODO: stack multiple badges (use z-index) ?
              # tmp: keep only the first type tag.
              $(anchor).parent().prepend Badge(types[0])

      for li, n in top_lis
        $(li).prepend("<p class='section-flag'>section #{n + 1}</p>")
      section = $("<section id='contents' class='level1' ></section>")
      section.append($("<h1><a href='#contents'>Contents</a></h1>"))
      section.append(toc.clone())
      toc.replaceWith(section)

  css:
    "nav#TOC": 
      "> ul":
        position: "relative"
        fontWeight: "bold"
        "> *":
          marginBottom: "var(--base-line-height)"
        li:
          listStyleType: "none"
          marginLeft: 0
          paddingLeft: 0
        ul:
          li: 
            marginLeft: "var(--base-line-height)"
            fontWeight: "normal"
        "> li.top-li":
          marginBottom: 0
          paddingBottom: "var(--base-line-height)"
          borderWidth: "2px 0 0 0"
          borderStyle: "solid"
          "&:last-child":
            borderWidth: "2px 0 2px 0"
     ".badge":
        position: "relative"
        bottom: "0.13em"
        fontFamily: typography.family serif: false, smallCaps: true
        fontWeight: "300"
        fontSize: "var(--small)"
        display: "inline-block"
        lineHeight: "1.2em"
        height: "1.2em"
        width: "2em"
        textAlign: "center"
        borderRadius: "2px"
        backgroundColor: "#f0f0f0"
        verticalAlign: "baseline"
        boxShadow: "0px 1.0px 1.0px #aaa"
        marginRight: "1em"
    ".section-flag": # TODO: shift a bit down.
      lineHeight: "var(--base-line-height)"
      fontSize: "var(--small)"
      fontWeight: "300"
      fontFamily: typography.family serif: false, smallCaps: true
      marginBottom: 0


# Footnotes
# ------------------------------------------------------------------------------
notes =
  html: ->
    notes = $("section.footnotes")
    notes.attr(id: "notes")
    if notes.length
      notes.prepend $("<h1><a href='#notes'>Notes</a></h1>")
      toc_ = $("nav#TOC")
      if toc_.length > 0
        toc_.children().first().append $("<li><a href='#notes'>Notes</a></li>")


# Header
# ------------------------------------------------------------------------------
header =
  css:
    main:
      "> header, > .header, > #header": # child of body is probably not appropriate ...
                  # instead, search for "a top-level section" (main, article, 
                  # class="main", etc.) and select the headers that are children
                  # -- not descendants -- of these.
        #borderTop: "3px solid #000000"
        marginTop: "calc(2 * var(--base-line-height))"
        marginBottom: "calc(2 * var(--base-line-height))"
        h1:
          fontSize: typography.xLarge + "px"
          lineHeight: "calc(1.5 * var(--base-line-height))"
          marginTop: 0.0   # compensate somewhere else, here
          marginBottom: "var(--base-line-height)"    # is not the place.
          fontWeight: "bold"
        ".author":
          fontSize: typography.medium + "px"
          lineHeight: "calc(1 * var(--base-line-height))"
  #        paddingTop: "1.5px" # makes the "true" baseline periodic (48 px)
          marginBottom: "calc(0.5 * var(--base-line-height))"
          fontWeight: "normal"
        ".date":
          fontFamily: typography.family smallCaps: true
          lineHeight: "calc(1 * var(--base-line-height))"
          fontSize: typography.medium + "px"
          fontWeight: "normal"
          marginBottom: "calc(0.5 * var(--base-line-height))"
          float: "none" # it's a pain to have to put that here to counteract
                        # the "float: left" used in "normal" h3 ...
                        # OTOH, this date and author stuff probably shouldn't
                        # be separate headings ...

  # TODO: remove the float: left; instead turn the heading inline and insert it
  #       into the next paragraph (if any).


# Headings
# -----------------------------------------------------------------------------
headings =
  css:
    h1:
      fontSize: typography.large + "px"
      fontWeight: "bold"
      lineHeight: "calc(1.25 * var(--base-line-height))" #1.25 * typography.lineHeight_px
      marginTop: "calc(2.00 * var(--base-line-height))"
      marginBottom: "calc(0.75 * var(--base-line-height))"
    h2:
      fontSize: typography.medium + "px"
      fontWeight: "bold"
      lineHeight: "calc(1 * var(--base-line-height))"
      marginBottom: "calc(0.5 * var(--base-line-height))"

    "h3, h4, h5, h6":
      fontSize: typography.medium + "px"
      fontWeight: "bold"
      marginRight: "1em"
      display: "inline"
  html: ->
    subsubheadings = $("h3, h4, h5, h6")
    for heading in subsubheadings
      # if the heading is empty, squeeze it.
      if $(heading).find("a").first().text() is ""
        $(heading).css marginRight: "0"
      # wrap the heading into the first paragraph in a pseudo-paragraph
      next = $(heading).next()
      if next.is("p")
        next.replaceWith("<div class='p'>" + next.html() + "</span>")
        p = $(heading).next()
        p.prepend(heading)
      if next.is("ul, ol")
          $("<br>").insertAfter($(heading)) 


# Links
# ------------------------------------------------------------------------------
links =
  css:
    a:
      cursor: "pointer"
      textDecoration: "none"
      outline: 0
      "&:hover":
        textDecoration: "none"
      "&:link":
        color: "var(--color)"
      "&:visited":
        color: "var(--color)"


# Footnotes
# ------------------------------------------------------------------------------
footnotes =
  css:
    sup:
      verticalAlign: "super"
      lineHeight: 0


# Lists
# ------------------------------------------------------------------------------
lists =
  css:
    li:
        listStyleType: "none"
        listStyleImage: "none"
        listStylePosition: "outside"
        marginLeft: "var(--base-line-height)"
        paddingLeft: "0.5em"    
    ul:
      li:
        listStyle: "disc"
    ol:
      li:
        listStyle: "decimal"


# Quotes
# ------------------------------------------------------------------------------
quote =
  css:
    blockquote:
      borderLeftWidth: "thick"
      borderLeftStyle: "solid"
      borderLeftColor: "black"
      padding: "var(--base-line-height)"
      marginBottom: "var(--base-line-height)"
      "p:last-child":
        marginBottom: "0px"


# Code & Code Blocks 
# ------------------------------------------------------------------------------
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
      fontSize: typography.medium + "px"
      fontFamily: "Inconsolata"
    pre:
      overflowX: "auto"
      backgroundColor: "#ebebeb"
      marginBottom: "var(--base-line-height)"
      paddingLeft: "var(--base-line-height)"
      paddingRight: "var(--base-line-height)"
      paddingTop : "var(--base-line-height)"
      paddingBottom : "var(--base-line-height)"


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
      marginBottom: "var(--base-line-height)"
      textAlign: "center"
    figcaption:
      display: "inline-block"
      fontStyle: "italic"
      textAlign: "justify"
      #align: "left"


# Tables
# ------------------------------------------------------------------------------
table =
  html: ->
    $("table").wrap("<div class='table'></div>");
  css:
    ".table":
      overflowX: "auto"
      overflowY: "hidden"
      width: "100%"
      marginBottom: "var(--base-line-height)"
    table:
      padding: 0 # transfer in reset/defaults ?
      marginLeft: "auto"
      marginRight: "auto" 
      borderSpacing: "1em " + (typography.baseLineHeight - typography.baseFontSize) + "px" # WTF ?
      borderCollapse: "collapse"
      borderTop: "medium solid black"
      borderBottom: "medium solid black"
    thead:
      borderBottom: "medium solid black"
    "td, th":
      padding: 0.5 * (typography.baseLineHeight - typography.baseFontSize) + "px" + " 0.5em" # WTF ?

# TODO: need to implement the overflow without an extra "block" that would
#       get the formula "out" of the current parapgraph and mess up spacing.


# MathJax
# ------------------------------------------------------------------------------
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


# Font Awesome
# ------------------------------------------------------------------------------
fontAwesome = 
  html: ->
    link = $ "<link>",
      rel: "stylesheet"
      href: "https://maxcdn.bootstrapcdn.com/font-awesome/4.5.0/css/font-awesome.min.css"
    $("head").append link

# JQuery
# ------------------------------------------------------------------------------
jQuery =
  html: ->
    insert_script src: "https://code.jquery.com/jquery-3.0.0.min.js"
 
 
# Bibliography
# ------------------------------------------------------------------------------
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
        b64Prefix = "data:application/json;charset=utf-8;fontSize64,"
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

# Proofs
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


# Previews
# ------------------------------------------------------------------------------
previews = 
  js: "js/preview.js"


# 'Classic' Theme
# ------------------------------------------------------------------------------
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
  bibliography, 
  proofs,
  previews]


# Modern/Slides Theme
# ------------------------------------------------------------------------------

# WARNING: broken ATM due to updates in the classic theme !!!

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
      verticalAlign: "fontSizeline"
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
  fontSize = 24 # 18 #24
  lineHeight = fontSize * 1.5
  ratio = 2
  tiny  = Math.round(fontSize / ratio) + "px"
  small  = Math.round(fontSize / ratio) + "px"
  medium = Math.round(fontSize) + "px"
  medium = 
    fontSize: Math.round(fontSize) + "px"
    lineHeight: 1.5 * Math.round(fontSize) + "px"
  large  = 
    fontSize: Math.round(fontSize * ratio) + "px"
    lineHeight: 1.0 * Math.round(fontSize * ratio) + "px"
  huge = 
    fontSize: Math.round(fontSize * ratio * ratio) + "px"
    lineHeight: 1.0 * Math.round(fontSize * ratio * ratio) + "px"

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


  {fontSize, lineHeight, ratio, tiny, small, medium, large, huge, html, css}

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

ES = 
  cssify: (options) ->
    csss = []
    for elt in _theme
      if elt.css?
        css_ = elt.css
        if type(css_) is "function"
          css_ = css_(options)
        csss.push css_
    rules = _.merge({}, csss...)
    cssify rules      

  domify: (options) ->
    for elt in _theme
      if elt.html?
        elt.html(options)

  scriptify: (options) ->
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
  css_text = ES.cssify options
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
    ES.domify(options) 

    # Include JS scripts required at runtime
    ES.scriptify(options)

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

