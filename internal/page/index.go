package page

import (
	"github.com/stackdump/on-chain-summer-2024/internal/service"
	"net/http"
	"text/template"
)

const (
	indexTpl = `<!DOCTYPE html>
<html>
<head>
	<title>Jetsam</title>
    <style>
		body {
			font-family: sans-serif;	
		}
		#snapshot {
			margin: 20px;
			padding: 20px;
			border: 1px solid #ccc;
			background-color: #f9f9f9;
		}
	</style>
    <script>
        model = {{.snapshot}};
        function onLoad() {
			var snapshot = document.getElementById("snapshot");
            console.log("onLoad");

			function showSource() {
				if (snapshot.style.display === "none") {
					snapshot.style.display = "block";
				} else {
					snapshot.style.display = "none";
				}
			}
            showSource(); // initially hide 
			document.getElementById("viewSource").addEventListener("click", showSource);
        }
	</script>
</head>
<body onLoad=onLoad()>
	<h1>Hello, {{.name}}</h1>
	<div>
		<Button id="viewSource">View Source</Button>
		<div id="snapshot"><pre>{{.snapshot}}</pre></div>
	</div>
<script>
</script>
</body>
</html>`
)

var indexTemplate = template.Must(template.New("index").Parse(indexTpl))

func IndexHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "text/html")

	indexTemplate.Execute(w, map[string]any{
		"name":     "Anon",
		"snapshot": string(service.NewSnapshot().ToJson()),
	})
}
