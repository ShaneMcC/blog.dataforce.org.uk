function documentReady() {
    littlefoot.littlefoot({
        activateOnHover: true,
        hoverDelay: 0,
        testButtonTemplate: `<button aria-label="Footnote <% number %>" class="littlefoot__button" id="<% reference %>" title="See Footnote <% number %>" /><% number %></button>`,
        buttonTemplate: `<sup id="fnref:1">[<a href="#<% reference %>" class="footnote-ref" role="doc-noteref"><% number %></a>]</sup>`,
    });
}

if (document.readyState === "loading") {
  document.addEventListener("DOMContentLoaded", documentReady);
} else {
  documentReady();
}
