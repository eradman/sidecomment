document.write(`
<style>
#comment_menu, #sidecomment_hint {
  position: absolute;
  visibility: hidden;
  z-index: 99;
}

#comment_menu text {
  fill: #fff;
  font: 20px sans-serif;
  font-weight: bold;
  text-anchor: middle;
  user-select: none;
  -webkit-user-select: none;
  cursor: unset;
  margin: 5px;
}

#comment_menu text:hover {
  text-shadow: 0 0 5px #fff;
}

#sidecomment_hint {
  opacity: 0.6;
  color: black;
  background-color: white;
  border-radius: 2px;
}
#sidecomment_hint_border {
  border-left: 4px solid gray;
  float: left;
}
#sidecomment_hint_text {
  margin-top: 0.2em;
  margin-bottom: 0.2em;
  margin-left: 1em;
  margin-right: 0.5em;
}

@keyframes sidecomment_fadeOpacity {
  0% {
    opacity: 0.6
  }
  100% {
    opacity: 0.0;
  }
}
</style>

<svg id="comment_menu" width="40" height="30">
  <polygon points="0,0 40,0, 40,20, 30,20, 20,30 10,20 0,20" style="fill:#4f94d4" />
  <text id="sidecomment_btn_show" x="20" y="18" onclick="sidecomment_showTicket()">+ </text>
</svg>

<div id="sidecomment_hint">
  <div id="sidecomment_hint_border"></div>
  <div id="sidecomment_hint_text"></div>
</div>
`);

/* Globals */
var select_count = 0;
var mouseout_count = 0;
var last_selection = null;
var last_selection_data = {
  "base": null,
  "selection": null,
  "extent": null
};

/* Register hover events) */

function sidecomment_displayHint() {
  if (last_selection == null) {
    let hint = document.getElementById("sidecomment_hint");
    let hint_border = document.getElementById("sidecomment_hint_border");
    let hint_text = document.getElementById("sidecomment_hint_text");
    let element_bound = this.getBoundingClientRect();

    hint_text.innerHTML = sidecomment_hint_text;
    hint.style.top = window.pageYOffset + this.getBoundingClientRect().y + "px";
    hint.style.left = (window.innerWidth - 200) + "px";
    hint.style.visibility = "visible";
    hint_border.style.height = Math.min(element_bound.height, 200) + "px";
    mouseout_count++;
  }
}

function sidecomment_hideHint(count) {
  if (last_selection == null) {
    let hint = document.getElementById("sidecomment_hint");

    if (mouseout_count == count) {
      hint.style.animation = "sidecomment_fadeOpacity ease 0.5s forwards";
    }
  }
}

function sidecomment_registerHints() {
  if (navigator.userAgent.includes("Mobile"))
    return;

  sidecomment_hint_tags.forEach((element) => {
    let tags = document.getElementsByTagName(element);
    let tag_idx = 0;
    let tag_idx_max = 10;

    while (tag_idx < Math.min(tags.length, tag_idx_max)) {
      if (tags[tag_idx].closest('nav') == null) {
        tags[tag_idx].addEventListener("mouseover", sidecomment_displayHint);
        tags[tag_idx].addEventListener("mouseout", () => setTimeout(sidecomment_hideHint, 2000, mouseout_count));
      }
      else { tag_idx_max++; }
      tag_idx++;
    }
  });
}
setTimeout(sidecomment_registerHints, 500);

/* Register selection events */
document.onselectionchange = function() {
  if (navigator.userAgent.includes("Mobile"))
    return;

  last_selection = document.getSelection();
  select_count++;
  setTimeout(finalizeSelection, 500, select_count);
};

/* Set selection if no more events have been received */
function finalizeSelection(this_count) {
  if ((last_selection.rangeCount > 0) && (this_count == select_count)) {
    let comment_menu = document.getElementById("comment_menu");
    let range = last_selection.getRangeAt(0);
    let rect = range.getBoundingClientRect();

    if (last_selection.toString() == "" || last_selection.rangeCount > 1) {
      comment_menu.style.visibility = "hidden";
    }
    else if (rect.width == 0 && rect.height == 0) {
      comment_menu.style.visibility = "hidden";
    }
    else {
      document.getElementById("sidecomment_hint").style.visibility = "hidden";
      comment_menu.style.left = window.pageXOffset + rect.x + "px";
      comment_menu.style.top = Math.max((window.pageYOffset + rect.y - 35), 0) + "px";
      comment_menu.style.visibility = "visible";
      sidecomment_clearTicket();

      /* leading */
      last_selection_data.base = range
        .startContainer
        .textContent
        .substring(0, range.startOffset);

      /* selection */
      last_selection_data.selection = range
        .toString();

      /* trailing */
      last_selection_data.extent = range
        .endContainer
        .textContent
        .substring(range.endOffset, range.endContainer.textContent.length);
    }
  }
}
