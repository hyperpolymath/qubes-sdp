// Qubes SDP Wiki - ReScript

// DOM bindings
@val external document: Dom.document = "document"
@val external window: Dom.window = "window"
@send external addEventListener: (Dom.document, string, unit => unit) => unit = "addEventListener"
@send external querySelector: (Dom.document, string) => Nullable.t<Dom.element> = "querySelector"
@send external querySelectorAll: (Dom.document, string) => array<Dom.element> = "querySelectorAll"
@send external querySelectorEl: (Dom.element, string) => Nullable.t<Dom.element> = "querySelector"
@send external createElement: (Dom.document, string) => Dom.element = "createElement"
@send external appendChild: (Dom.element, Dom.element) => unit = "appendChild"
@send external insertBefore: (Dom.element, Dom.element, Nullable.t<Dom.element>) => unit = "insertBefore"
@send external getAttribute: (Dom.element, string) => Nullable.t<string> = "getAttribute"
@send external setAttribute: (Dom.element, string, string) => unit = "setAttribute"
@send external addEventListenerEl: (Dom.element, string, Dom.event => unit) => unit = "addEventListener"
@send external preventDefault: Dom.event => unit = "preventDefault"
@send external scrollIntoView: (Dom.element, {"behavior": string, "block": string}) => unit = "scrollIntoView"
@get external textContent: Dom.element => string = "textContent"
@set external setTextContent: (Dom.element, string) => unit = "textContent"
@set external setClassName: (Dom.element, string) => unit = "className"
@set external setHref: (Dom.element, string) => unit = "href"
@set external setId: (Dom.element, string) => unit = "id"
@get external id: Dom.element => string = "id"
@get external tagName: Dom.element => string = "tagName"
@get external parentElement: Dom.element => Nullable.t<Dom.element> = "parentElement"
@get external nextSibling: Dom.element => Nullable.t<Dom.element> = "nextSibling"
@get external style: Dom.element => {..} = "style"
@set external setStyleProp: ({..}, string, string) => unit = ""
@get external pathname: Dom.window => string = "location.pathname"
@get external target: Dom.event => Dom.element = "target"
@get external value: Dom.element => string = "value"

// Clipboard API
@val @scope(("navigator", "clipboard")) external writeText: string => promise<unit> = "writeText"

// Console
@val @scope("console") external log: string => unit = "log"

// Timers
@val external setTimeout: (unit => unit, int) => unit = "setTimeout"

// String helpers  
module Str = {
  @send external split: (string, string) => array<string> = "split"
  @send external pop: array<string> => option<string> = "pop"
  @send external toLowerCase: string => string = "toLowerCase"
  @send external replace: (string, Js.Re.t, string) => string = "replace"
  @send external includes: (string, string) => bool = "includes"
}

// Highlight current page in sidebar navigation
let highlightCurrentPage = () => {
  let path = window->pathname
  let parts = path->Str.split("/")
  let currentPage = parts->Str.pop->Option.getOr("index.html")
  
  document->querySelectorAll(".nav-menu a")->Array.forEach(link => {
    link->getAttribute("href")->Nullable.toOption->Option.forEach(href => {
      if href == currentPage {
        let s = link->style
        s->setStyleProp("background", "rgba(255,255,255,0.1)")
        s->setStyleProp("borderLeftColor", "#3874D8")
        s->setStyleProp("color", "white")
      }
    })
  })
}

// Add copy buttons to code blocks
let addCopyButtons = () => {
  document->querySelectorAll("pre code")->Array.forEach(block => {
    let button = document->createElement("button")
    button->setClassName("copy-button")
    button->setTextContent("Copy")
    
    button->addEventListenerEl("click", _ => {
      let code = block->textContent
      writeText(code)->Promise.then(_ => {
        button->setTextContent("Copied!")
        setTimeout(() => button->setTextContent("Copy"), 2000)
        Promise.resolve()
      })->ignore
    })
    
    block->parentElement->Nullable.toOption->Option.forEach(pre => {
      let s = pre->style
      s->setStyleProp("position", "relative")
      pre->appendChild(button)
    })
  })
}

// Add anchor links to headings
let addAnchorLinks = () => {
  document->querySelectorAll("h2, h3, h4")->Array.forEach(heading => {
    let text = heading->textContent
    let id = text
      ->Str.toLowerCase
      ->Str.replace(%re("/[^a-z0-9]+/g"), "-")
      ->Str.replace(%re("/(^-|-$)/g"), "")
    
    heading->setId(id)
    
    let anchor = document->createElement("a")
    anchor->setClassName("anchor-link")
    anchor->setHref("#" ++ id)
    anchor->setTextContent("#")
    
    let s = anchor->style
    s->setStyleProp("marginLeft", "0.5rem")
    s->setStyleProp("color", "#ccc")
    s->setStyleProp("textDecoration", "none")
    s->setStyleProp("display", "none")
    
    heading->appendChild(anchor)
    
    heading->addEventListenerEl("mouseenter", _ => {
      let s = anchor->style
      s->setStyleProp("display", "inline")
    })
    
    heading->addEventListenerEl("mouseleave", _ => {
      let s = anchor->style
      s->setStyleProp("display", "none")
    })
  })
}

// Simple search functionality
let initSearch = () => {
  document->querySelector("#wiki-search")->Nullable.toOption->Option.forEach(searchBox => {
    searchBox->addEventListenerEl("input", e => {
      let query = (e->target)->value->Str.toLowerCase
      document->querySelector(".container")->Nullable.toOption->Option.forEach(content => {
        let text = content->textContent->Str.toLowerCase
        if query != "" && text->Str.includes(query) {
          log("Found: " ++ query)
        }
      })
    })
  })
}

// Smooth scrolling for anchor links
let initSmoothScrolling = () => {
  document->querySelectorAll("a[href^=\"#\"]")->Array.forEach(anchor => {
    anchor->addEventListenerEl("click", e => {
      e->preventDefault
      anchor->getAttribute("href")->Nullable.toOption->Option.forEach(href => {
        document->querySelector(href)->Nullable.toOption->Option.forEach(target => {
          target->scrollIntoView({"behavior": "smooth", "block": "start"})
        })
      })
    })
  })
}

// Generate table of contents for long pages
let generateTableOfContents = () => {
  let headings = document->querySelectorAll("h2, h3")
  if Array.length(headings) >= 3 {
    let toc = document->createElement("div")
    toc->setClassName("table-of-contents")
    
    let h3 = document->createElement("h3")
    h3->setTextContent("Table of Contents")
    toc->appendChild(h3)
    
    let list = document->createElement("ul")
    
    headings->Array.forEach(heading => {
      let li = document->createElement("li")
      let a = document->createElement("a")
      a->setHref("#" ++ heading->id)
      a->setTextContent(heading->textContent->Str.replace(%re("/#/g"), ""))
      
      if heading->tagName == "H3" {
        let s = li->style
        s->setStyleProp("marginLeft", "1rem")
      }
      
      li->appendChild(a)
      list->appendChild(li)
    })
    
    toc->appendChild(list)
    
    document->querySelector("h1")->Nullable.toOption->Option.forEach(firstHeading => {
      firstHeading->parentElement->Nullable.toOption->Option.forEach(parent => {
        parent->insertBefore(toc, firstHeading->nextSibling)
      })
    })
  }
}

// Initialize on DOM ready
let init = () => {
  highlightCurrentPage()
  addCopyButtons()
  addAnchorLinks()
  initSearch()
  initSmoothScrolling()
  generateTableOfContents()
}

document->addEventListener("DOMContentLoaded", init)
