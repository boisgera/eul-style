
# TODO:
#
#   - url localization ... (or neutralization) 
#     at least for images if not for links (that can't be clicked).
# 
#   - alternative placements? We wouldn't like the hovercard to
#     cover the link. We should probably adjust the location and size
#     of the card wrt the bounding-box of the link.
#
#   - see if there are some interferences with proofs, 
#     that are hidden at start time (probabl not).
#  
# BUG: 
#
#   - I'd like the transition to visible to be complete, 
#     even if we don't stay in the hover state (occultation)
#     Well, MAYBE, think of it.

make_preview = (elt) ->
  [url, id] = elt.attr("href").split("#")

  card = $("""
    <div class='card'>
      <div class='holder'>
        <p>Placeholder</p>
      </div>
    </div>"""
  )
  card.css
    width: "35vw"
    padding: "1.5rem"
    position: "fixed"
    top: "1.5rem"
    right: "1.5rem"
    boxSizing: "border-box"
    maxHeight: "calc(100vh - 3rem)"
    overflow: "hidden"
    boxShadow: "0 0 1rem #e6e6e6"
    backgroundColor: "white"
  visible_css = 
    visibility: "visible"
    opacity: 1
    transform: "translateX(0em)"
    transition: "all 0.3s linear"
  hidden_css = 
    visibility: "hidden"
    opacity: 0
    transform: "translateX(1em)"
    transition: "all 0.3s linear 0.5s"
  card.css hidden_css

  elt.css
    #textShadow: "1px 1px 0px #f9f9f9, 2px 2px 0px #c0c0c0"
    textDecoration: "underline solid #0a0a0a"
    textDecorationSkip: "ink"
    transition: "background-color 0.3s linear"

  show_preview = () -> 
    #console.log "show preview"
    elt.css backgroundColor: "#d3d3d3"
    card.css visible_css

  hide_preview = () -> 
    #console.log "hide preview"
    elt.css backgroundColor: "#d3d3d300"
    card.css hidden_css

  card.find(".holder").load url + " [id='#{id}']", 
    (response, status, jxXHR) ->
      console.log "XHR status:", status, url, id
      if status in ["success", "notmodified"]
        # this shit never gets called in Opera?
        console.log "success!"
        console.log "elt:", $(elt)
        #$(elt).css borderBottom: "2px solid #c0c0c0" 
        #$(elt).css backgroundColor: "#ff940077"
        #console.log "outer HTML:", $(elt)[0].outerHTML

        $("body").append card
        card.find("p, .p").css textAlign: "left"
        card.find("section").css marginBottom: "0"
        card.find("section").children().last().css marginBottom: "0"
        MathJax.Hub.Queue ["Typeset", MathJax.Hub, card[0]]
        elt.on "mouseenter", show_preview
        elt.on "mouseleave", hide_preview

mathjaxDebug = ->
#  MathJax.Hub.Startup.signal.Interest (message) -> console.log "*", message
  MathJax.Hub.signal.Interest (message) -> console.log "*", message
  MathJax.Hub.Register.StartupHook "End Process", ->
    console.log "list of jaxes:"
    for jax in MathJax.Hub.getAllJax()
      console.log "jax:", jax      

$ ->
  # mathjaxDebug()
  #console.log "preview:"
  for elt in $("a.preview")
     #console.log $(elt)
     make_preview $(elt)

