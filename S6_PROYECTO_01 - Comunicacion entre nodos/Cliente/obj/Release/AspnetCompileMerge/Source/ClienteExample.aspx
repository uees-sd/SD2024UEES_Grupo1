<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="ClienteExample.aspx.cs" Inherits="Cliente.ClienteExample" %>

<!DOCTYPE html>

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title></title>
     <link href="Content/bootstrap.min.css" type="text/css" rel="stylesheet" />
    <script src="scripts/jquery-3.6.1.min.js" type="text/javascript"></script>
</head>
<body>
    <div class="card">
        <div class="card-header">
            <h2>Prueba multi cliente con WebSocket</h2>
        </div>
        <div class="card-body">
            <p>
                <textarea cols="60" rows="6" id="cajadetexto"></textarea>
            </p>
            <p>
                <button id="boton" class="btn btn-primary">Enviar</button>
            </p>
            <p>
                <div id="salida"></div>
            </p>
        </div>
    </div>

    <style type="text/css">
        textarea {
            vertical-align: bottom;
        }

        #salida {
            overflow: auto;
        }

        #salida > p {
            overflow-wrap: break-word;
        }

        #salida span {
            color: blue;
        }

        #salida span.error {
            color: red;
        }
    </style>

    <script type="text/javascript">
        $(document).ready(function () {
            const wsUri = "ws://127.0.0.1:8080/";
            const websocket = new WebSocket(wsUri);

            $(document).on("click", "#boton", onClickButton);

            websocket.onopen = (e) => {
                writeToScreen("CONNECTED");
            };

            websocket.onclose = (e) => {
                writeToScreen("DISCONNECTED");
            };

            websocket.onmessage = (e) => {
                writeToScreen("<span>RESPONSE: " + e.data + "</span>");
            };

            websocket.onerror = (e) => {
                writeToScreen(`<span class="error">ERROR:</span> ${e.data}`);
            };

            function doSend(message) {
                writeToScreen(`SENT: ${message}`);
                websocket.send(message);
            }

            function writeToScreen(message) {
                $("#salida").append("<p>" + message + "</p>");
            }

            function onClickButton() {
                var text = $("#cajadetexto").val();
                text && doSend(text);
                $("#cajadetexto").val("");
                $("#cajadetexto").focus();
            }
        });
    </script>
</body>

</html>
