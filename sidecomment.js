/* Copyright (c) 2021 Ratical Software */

if (sidecomment_io_service == undefined)
  var sidecomment_io_service = location.protocol + "//sidecomment.io";
if (sidecomment_hint_tags == undefined)
  var sidecomment_hint_tags = ["p", "pre", "blockquote", "ol", "ul", "table"];
if (sidecomment_hint_text == undefined)
  var sidecomment_hint_text = `
    Select text to comment &#10564;
    `;

/* REST API */

async function sidecomment_postData(url, data = {}) {
  const response = await fetch(sidecomment_io_service + url, {
    method: "POST",
    headers: {
      "Content-Type": "application/json"
    },
    mode: "cors",
    body: JSON.stringify(data)
  });
  if (response.body) return response.json();
  else return { error: "empty reply in cross-origin request" };
}

/* Selection UI */

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
  base: null,
  selection: null,
  extent: null
};

/* Register hover events */

function sidecomment_displayHint() {
  if (last_selection == null) {
    let hint = document.getElementById("sidecomment_hint");
    let hint_border = document.getElementById("sidecomment_hint_border");
    let hint_text = document.getElementById("sidecomment_hint_text");
    let element_bound = this.getBoundingClientRect();

    hint_text.innerHTML = sidecomment_hint_text;
    hint.style.top = window.pageYOffset + this.getBoundingClientRect().y + "px";
    hint.style.left = window.innerWidth - 200 + "px";
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
  if (navigator.userAgent.includes("Mobile")) return;

  sidecomment_hint_tags.forEach((element) => {
    let tags = document.getElementsByTagName(element);
    let tag_idx = 0;
    let tag_idx_max = 10;

    while (tag_idx < Math.min(tags.length, tag_idx_max)) {
      if (tags[tag_idx].closest("nav") == null) {
        tags[tag_idx].addEventListener("mouseover", sidecomment_displayHint);
        tags[tag_idx].addEventListener("mouseout", () =>
          setTimeout(sidecomment_hideHint, 2000, mouseout_count)
        );
      } else {
        tag_idx_max++;
      }
      tag_idx++;
    }
  });
}
setTimeout(sidecomment_registerHints, 500);

/* Register selection events */
document.onselectionchange = function () {
  if (navigator.userAgent.includes("Mobile")) return;

  last_selection = document.getSelection();
  select_count++;
  setTimeout(finalizeSelection, 500, select_count);
};

/* Set selection if no more events have been received */
function finalizeSelection(this_count) {
  if (last_selection.rangeCount > 0 && this_count == select_count) {
    let comment_menu = document.getElementById("comment_menu");
    let range = last_selection.getRangeAt(0);
    let rect = range.getBoundingClientRect();

    if (last_selection.toString() == "" || last_selection.rangeCount > 1) {
      comment_menu.style.visibility = "hidden";
    } else if (rect.width == 0 && rect.height == 0) {
      comment_menu.style.visibility = "hidden";
    } else {
      document.getElementById("sidecomment_hint").style.visibility = "hidden";
      comment_menu.style.left = window.pageXOffset + rect.x + "px";
      comment_menu.style.top =
        Math.max(window.pageYOffset + rect.y - 35, 0) + "px";
      comment_menu.style.visibility = "visible";
      sidecomment_clearTicket();

      /* leading */
      last_selection_data.base = range.startContainer.textContent.substring(
        0,
        range.startOffset
      );

      /* selection */
      last_selection_data.selection = range.toString();

      /* trailing */
      last_selection_data.extent = range.endContainer.textContent.substring(
        range.endOffset,
        range.endContainer.textContent.length
      );
    }
  }
}

/* Comment UI */

document.write(`
<style>
#sidecomment_div {
  position: fixed;
  z-index: 100;
  display: none;
  border-radius: 4px;
  padding: 8px;
  border: 2px solid #4f94d4;
  background-color: #fff;
  color: initial;
}

#sidecomment_div_bar {
  width: 100%;
  position: relative;
  top: 0;
  cursor: move;
  padding-bottom: 6px;
  border-bottom: 1px solid #ddd;
}

#sidecomment_btn_close {
  cursor: pointer;
}

#sidecomment_div button {
  cursor: pointer;
  background-color: #fff;
  color: black;
  padding: 6px;
  border: 2px solid #ddd;
  border-radius: 4px;
}

#sidecomment_div input {
  border-radius: 4px;
  margin: 4px;
  border: 2px solid #ddd;
  background-color: #fff;
  color: black;
  pointer-events: unset;
}

#sidecomment_div input:invalid {
  border-color: #f30000;
}

#sidecomment_div textarea {
  width: 96%;
  padding: 10px;
  border-radius: 4px;
  margin: 4px;
  border: 2px solid #ddd;
  background-color: #fff;
  color: black;
}

#sidecomment_div form {
  margin: 10px;
}
</style>

<div id="sidecomment_div">
  <div id="sidecomment_div_bar">
    <span id="sidecomment_btn_close" title="Close (ESC)">&#x2715;</span>
    <span style="float: right">
      <a id="sidecomment_ext_link" href="#" target="_blank">get usercode</a> &#x2197;
    </span>
  </div>
  <form>
    <label for="sidecomment_commentcode">Usercode:</label>
    <input id="sidecomment_commentcode" required type="text" size="11"
           pattern="[_0-9a-zA-Z]{11}" title="Paste usercode here"/>
    <br>
    <label for="sidecomment_blockquote">Selected Text</label>
    <textarea id="sidecomment_blockquote" disabled rows="3">
    </textarea>
    <br>
    <label for="sidecomment_comment_area">Proposed Revision:</label>
    <textarea id="sidecomment_comment_area" rows="20" required>
    </textarea>
    <br>
    <button id="sidecomment_button_submit" type="button"
            onclick="return sidecomment_submitTicket()">Submit</button>
    <a id="sidecomment_ticket_status" href="#"></a>
    <span style="color:#f30000" id="sidecomment_ticket_error"></span>
  </form>
</div>
`);

var sidecomment_div = document.getElementById("sidecomment_div");
var sidecomment_ext_link = document.getElementById("sidecomment_ext_link");

sidecomment_ext_link.href =
  sidecomment_io_service + "/comment?hostname=" + window.location.hostname;

window.addEventListener("load", (event) => {
  let btn_close = document.getElementById("sidecomment_btn_close");
  let div_bar = document.getElementById("sidecomment_div_bar");

  div_bar.addEventListener("mousedown", sidecomment_mouseDown, false);
  btn_close.onclick = function (e) {
    sidecomment_div.style.display = "none";
  };
  window.addEventListener("mouseup", sidecomment_mouseUp, false);
});

window.addEventListener("resize", (event) => {
  var w = window.innerWidth - 40;
  sidecomment_div.style.left = w / 2 + "px";
  sidecomment_div.style.width = w / 2 + "px";
});

var offset = { x: 0, y: 0 };

function sidecomment_mouseDown(e) {
  offset.x = e.clientX - sidecomment_div.offsetLeft;
  offset.y = e.clientY - sidecomment_div.offsetTop;
  window.addEventListener("mousemove", sidecomment_mouseMove, true);
}

function sidecomment_mouseMove(e) {
  let x = Math.max(0, e.clientY - offset.y);
  let y = Math.max(0, e.clientX - offset.x);
  sidecomment_div.style.top = x + "px";
  sidecomment_div.style.left = y + "px";
}

function sidecomment_mouseUp(e) {
  window.removeEventListener("mousemove", sidecomment_mouseMove, true);
}

window.onkeydown = function (e) {
  let btn_close = document.getElementById("sidecomment_btn_close");

  if (e.keyCode == 27)
    // ESC
    sidecomment_btn_close.click(e);
};

sidecomment_showTicket = function (e) {
  let commentcode = document.getElementById("sidecomment_commentcode");

  var w = window.innerWidth - 40;
  var sidecomment_blockquote = document.getElementById(
    "sidecomment_blockquote"
  );

  if (last_selection == null) return;
  sidecomment_blockquote.innerHTML = last_selection.toString();
  sidecomment_blockquote.data = Object.assign({}, last_selection_data);

  // initial position
  sidecomment_div.style.top = "30px";
  sidecomment_div.style.left = w / 2 + "px";
  sidecomment_div.style.width = w / 2 + "px";
  sidecomment_div.style.display = "block";
};

function sidecomment_submitTicket() {
  let comment_area = document.getElementById("sidecomment_comment_area");
  let ticket_status = document.getElementById("sidecomment_ticket_status");
  let ticket_error = document.getElementById("sidecomment_ticket_error");
  let button_submit = document.getElementById("sidecomment_button_submit");
  let commentcode = document.getElementById("sidecomment_commentcode");

  usercode_id = commentcode.value;
  if (usercode_id.length == 11) {
    var sidecomment_blockquote = document.getElementById(
      "sidecomment_blockquote"
    );

    sidecomment_postData("/ticket", {
      usercode_id: usercode_id,
      url: window.location.href,
      base: sidecomment_blockquote.data.base,
      selection: sidecomment_blockquote.data.selection,
      extent: sidecomment_blockquote.data.extent,
      comment_area: comment_area.value,
      sitecode_id: sidecomment_sitecode
    }).then((data) => {
      if ("error" in data) {
        ticket_error.innerText = data.error;
      } else {
        ticket_error.innerText = "";
        var url = sidecomment_io_service + "/tickets/" + data.usercode_id;
        ticket_status.href = url;
        ticket_status.innerText = "check status";
        sidecomment_button_submit.disabled = true;
      }
    });
  }
}

function sidecomment_clearTicket() {
  let comment_area = document.getElementById("sidecomment_comment_area");
  let ticket_status = document.getElementById("sidecomment_ticket_status");
  let button_submit = document.getElementById("sidecomment_button_submit");

  comment_area.value = "";
  ticket_status.url = "";
  ticket_status.innerText = "";
  button_submit.disabled = false;
}
