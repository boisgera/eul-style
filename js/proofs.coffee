
hide_proof = (section) ->
  # clone the section, wrap the clone into an invisible div
  clone = section.clone()
  id = section.attr "id"
  clone.attr id: id + "---"
  div = $("<div></div>")
  div.css display: "none"
  div.append clone
  
  # create a new minimized section header with a caret down icon.
  header = section.find("h3, h4, h5, h6").first().clone()
  new_paragraph = $("<div 
    class='p' 
    style='margin-bottom:0;'>
  </div>")
  new_paragraph.append(header) 
  new_paragraph.append $("
    <i 
      class='fa fa-caret-down expand' 
      style='float:right;cursor:pointer';>
   </i>")

  # replace the content of the section by the mini-header 
  # (and hidden clone).
  section.empty()
  section.append(new_paragraph)
  section.append(div)

  section.find("i.expand").on "click", -> show_proof(section)

show_proof = (section) ->
  # get rid of the minimized proof, restore the section contents.
  section.children().first().remove()
  div = section.children().first()
  _section = div.children().first()
  section.html(_section.html())

  tombstone = section.find(".tombstone")
  tombstone.css cursor: "pointer"
  tombstone.on "click", -> hide_proof(section)

box = (section) ->
  # The section does take care of bottom spacing now, not its content.
  section.css
    margin: "-0.75rem -0.75rem 0.75rem -0.75rem"
    padding: "0.75rem"
    backgroundColor: "#f9f9f9"
  section.children().last().css marginBottom: "0"  

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

  # "Box" them
  for section in proof_sections
    box(section)

  # Hide them
  for section in proof_sections
    hide_proof(section)


$ main
