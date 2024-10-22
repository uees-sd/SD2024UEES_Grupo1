﻿<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="ClienteExample.aspx.cs" Inherits="Cliente.ClienteExample" %>

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
            <input id="Text1" type="text" /> X
        <input id="Text2" type="text" /> =
        <input id="Text3" type="text" />&nbsp;&nbsp;
        <input id="boton" type="button" value="Enviar" />
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
            var number = 1 + Math.floor(Math.random() * 6);
            var number1 = 1 + Math.floor(Math.random() * 50);
            $("#Text1").val(number);
            $("#Text2").val(number1);


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
                var text = $("#Text1").val() + '*' + $("#Text2").val() + '=' + $("#Text3").val();
                text && doSend(text);
                //$("#Text1").val("");
                //$("#Text1").focus();
            }
        });
    </script>
</body>

</html>
