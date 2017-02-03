
hide_proof = (section) ->
  clone = section.clone()
  id = section.attr "id"
  clone.attr id: id + "---"
  div = $("<div></div>")
  div.css display: "none"
  div.append clone
  
  header = section.find("h3, h4, h5, h6").first().clone()
  new_paragraph = $("<div class='p'></div>").append(header) 
  new_paragraph.append("<i class='fa fa-caret-down expand' style='float:right;cursor:pointer;'></i>")

  section.empty()
  section.append(new_paragraph)
  section.append(div)

  section.find("i.expand").on "click", do (section) -> (-> show_proof(section)) 

show_proof = (section) ->
  section.children().first().remove()
  section.html(section.children().first().html())

  tombstone = section.find(".tombstone")
  tombstone.css cursor: "pointer"
  tombstone.on "click", do (section) -> (-> hide_proof(section))

main = ->
  # find proof sections
  sections = $("section")
  proof_sections = []
  for section in sections
    header = $(section).find("h3, h4, h5, h6").first()
    if header.length
      text = header.text()
      if text[..4] is "Proof"
        proof_sections.push($(section))

  for section in proof_sections
    hide_proof(section)


$ main
