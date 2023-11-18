/* REST API */
async function sidecomment_postData(url, data={}) {
  const response = await fetch(sidecomment_io_service+url, {
    method: "POST",
    headers: {
      "Content-Type": "application/json"
    },
    mode: "cors",
    body: JSON.stringify(data)
  });
  if (response.body) return response.json();
  else return {"error": "empty reply in cross-origin request"};
}
