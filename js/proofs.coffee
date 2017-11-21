
# TODO: need some "init" phase such that hide at start is not necessary.

# TODO: need to preserve the event handlers from the section contents.

hide_proof = (sectionWrapper) ->
  sectionWrapper.find(".expand").css
    visibility: "visible"
  sectionWrapper.find(".header-wrapper").css 
    visibility: "visible"
    height: ""
  sectionWrapper.find("section").first().css 
    visibility: "hidden"
    height: "0px"

#  # clone the section, wrap the clone into an invisible div
#  clone = section.clone(true)
#  id = section.attr "id"
#  clone.attr id: id + "---"
#  div = $("<div></div>")
#  div.css visibility: "hidden", height: "0"
#  div.append clone
#  
#  # create a new minimized section header with a caret down icon.
#  header = section.find("h3, h4, h5, h6").first().clone()
#  new_paragraph = $("<div 
#    class='p' 
#    style='margin-bottom:0.75rem;'>
#  </div>")
#  new_paragraph.append(header) 
#  new_paragraph.append $("
#    <i 
#      class='fa fa-caret-down expand' 
#      style='cursor:pointer;position:absolute;top:0.75rem;right:0.75rem;'>
#   </i>")

#  # replace the content of the section by the mini-header 
#  # (and hidden clone).
#  section.empty()
#  section.append(new_paragraph)
#  section.append(div)

#  section.find("i.expand").on "click", -> show_proof(section)

show_proof = (sectionWrapper) ->
  sectionWrapper.find(".expand").css
    visibility: "hidden"
  sectionWrapper.find(".header-wrapper").css 
    visibility: "hidden"
    height: "0"
  sectionWrapper.find("section").first().css 
    visibility: "visible"
    height: ""

#  # get rid of the minimized proof, restore the section contents.
#  section.children().first().remove()
#  div = section.children().first()
#  _section = div.children().first()
#  section.html(_section.html())

#  tombstone = section.find(".tombstone")
#  tombstone.css 
#    cursor: "pointer"
#    position: "absolute"
#    bottom: "0.75rem"
#    right: "0.75rem"
#  tombstone.on "click", -> hide_proof(section)

box = (section) ->
  # The section wrapper will take care of bottom spacing now.
  clone = section.clone(true)
  clone.css marginBottom: "0"  
  clone.children().last().css marginBottom: "0"

  tombstone = clone.find(".tombstone")
  tombstone.css 
    cursor: "pointer"
    position: "absolute"
    bottom: "0.75rem"
    right: "0.75rem"

  wrapper = $("<div></div>")
  wrapper.css
    position: "relative"
    margin: "-0.75rem -0.75rem 0.75rem -0.75rem"
    padding: "0.75rem"
    backgroundColor: "#f9f9f9"

  header = clone.find("h3, h4, h5, h6").first().clone()
  headerWrapper = $("<div 
    class='p header-wrapper' 
    style='margin-bottom:0;
           visibility:hidden; overflow:hidden; height:0;'>
  </div>")
  headerWrapper.append(header)
  expand = $("
    <i 
      class='fa fa-caret-down expand' 
      style='visibility:hidden;
             cursor:pointer;
             position:absolute;
             top:0.75rem;
             right:0.75rem;'>
   </i>")
  wrapper.append(headerWrapper)
  wrapper.append(expand)
  wrapper.append(clone)

  expand.on "click", -> show_proof(wrapper)
  tombstone.on "click", -> hide_proof(wrapper)

  section.replaceWith wrapper
  return wrapper

main = ->
  # Find proof sections
  sections = $("section")
  proof_sections = []
  for section in sections
    header = $(section).find("h1, h2, h3, h4, h5, h6").first()
    if header.length and header.prop("tagName") in ["H3", "H4", "H5", "H6"]
      text = header.text()
      if text[..4] is "Proof"
        proof_sections.push($(section))

  # "Box" them and (optionally) hide them
  for section in proof_sections
    wrapper = box(section)
    hide_proof(wrapper)

$ main
