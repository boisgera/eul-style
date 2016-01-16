
defaults = ->
  "*":
    margin: 0
    padding: 0
    border: 0
    boxSizing: "content-box" # "border-box" 
    fontSize: "100%"
    font: "inherit"
    verticalAlign: "baseline"
  body:
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

# Colors
color = "black"

# Typography
base = 24
lineHeight = base * 1.5
ratio = Math.sqrt(2)
small  = Math.round(base / ratio) + "px"
medium = Math.round(base) + "px"
large  = Math.round(base * ratio) + "px"
huge   = Math.round(base * ratio * ratio) + "px"

# TODO: document the use of Alegreya, Al. SC, Inconsolata.

typography = ->
  html:
    body:
      fontFamily: "Alegreya, serif"
      fontSize: medium
      fontStyle: "normal"
      fontWeight: "normal"
      em:
        fontStyle: "italic"
      strong:
        fontWeight: "bold"
      textRendering: "optimizeLegibility"
      lineHeight: lineHeight + "px"
      textAlign: "left"
      p:
        marginBottom: lineHeight + "px"
        textAlign: "justify"
        hyphens: "auto"
        MozHyphens: "auto"
      
layout = ->
  html:
    body:
      maxWidth: "32em"
      margin: "auto"
      padding: lineHeight + "px" 

header = ->
  body:
    "> header":
      #borderTop: "3px solid #000000"
      marginTop: 2.0 * lineHeight + "px" # not sure that's the right place.
      marginBottom: lineHeight + "px"
      h1:
        fontSize: huge
        lineHeight: 1.5 * lineHeight + "px"
        marginTop: 0.0 * lineHeight + "px" # compensate somewhere else, here
        marginBottom: lineHeight + "px"    # is not the place.
        fontWeight: "bold"
      ".author":
        fontSize: medium
        lineHeight: lineHeight + "px"
#        paddingTop: "1.5px" # makes the "true" baseline periodic (48 px)
#        marginBottom: "-1.5px"
        fontWeight: "bold"
      ".date":
        fontFamily: '"Alegreya SC", serif'
        lineHeight: lineHeight + "px"
        fontSize: medium
        fontWeight: "normal"

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

code = ->
  code:
    fontFamily: "Inconsolata"
  pre:
    overflowX: "auto"
    backgroundColor: "#ebebeb"
    marginTop: 1 * lineHeight + "px"
    marginBottom: 1 * lineHeight + "px"
    paddingLeft: lineHeight + "px"
    paddingRight: lineHeight + "px"
    paddingTop : 1 * lineHeight + "px"
    paddingBottom : 1 * lineHeight + "px"

module.exports = (absurd) -> 
  absurd.add defaults()
  absurd.add typography()
  absurd.add layout()
  absurd.add header()
  absurd.add headings()
  absurd.add links()
  absurd.add code()








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


