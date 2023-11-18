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
    <label for="sidecomment_comment_area">Comments</label>
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

sidecomment_ext_link.href = sidecomment_io_service + "/comment?hostname=" + window.location.hostname;

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
  sidecomment_div.style.left = w/2 + "px";
  sidecomment_div.style.width = w/2 + "px";
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

  if (e.keyCode == 27) // ESC
    sidecomment_btn_close.click(e);
};

sidecomment_showTicket = function (e) {
  let commentcode = document.getElementById("sidecomment_commentcode");

  var w = window.innerWidth - 40;
  var sidecomment_blockquote = document.getElementById("sidecomment_blockquote");

  if (last_selection == null) return;
  sidecomment_blockquote.innerHTML = last_selection.toString();
  sidecomment_blockquote.data = Object.assign({}, last_selection_data);

  // initial position
  sidecomment_div.style.top = "30px";
  sidecomment_div.style.left = w/2 + "px";
  sidecomment_div.style.width = w/2 + "px";
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
    var sidecomment_blockquote = document.getElementById("sidecomment_blockquote");

    sidecomment_postData("/ticket",
            {"usercode_id": usercode_id,
             "url": window.location.href,
             "base": sidecomment_blockquote.data.base,
             "selection": sidecomment_blockquote.data.selection,
             "extent": sidecomment_blockquote.data.extent,
             "comment_area": comment_area.value,
             "sitecode_id": sidecomment_sitecode})
    .then(data => {
      if ("error" in data) {
        ticket_error.innerText = data.error;
      }
      else {
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
