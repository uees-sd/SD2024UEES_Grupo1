<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="Inicio.aspx.cs" Inherits="Cliente.Inicio" %>

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
            <h2>Juego- Inicio</h2>
        </div>
        <div class="card-body">
         Alias:&nbsp;&nbsp; <input id="Text1" type="text" />&nbsp;&nbsp; &nbsp;&nbsp;
        <input id="boton" class="btn btn-primary" type="button" value="Iniciar" /><br />
&nbsp;<p>
                <input id="boton1" class="btn btn-primary" type="button" value="En Línea" />&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; <input id="boton2" class="btn btn-primary" type="button" value="Local" />
                
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
            const wsUri = "ws://10.53.12.141:8080/";
            const websocket = new WebSocket(wsUri);
           
            $("#boton1").hide()
            $(document).on("click", "#boton", onClickButton);
            $(document).on("click", "#boton1", onClickButton1);
            $(document).on("click", "#boton2", onClickButton2);

            websocket.onopen = (e) => {
                writeToScreen("CONNECTED");
                doSend("Registro/0");
            };

            websocket.onclose = (e) => {
                writeToScreen("DISCONNECTED");
            };

            websocket.onmessage = (e) => {
                writeToScreen("<span>" + e.data + "</span>");
                if (e.data != "")
                {
                    $("#Text1").val(e.data);
                    /*$("#Text1").prop('disabled', true);*/
                    $("#boton").hide();
                    $("#boton1").show();
                }
            };

            websocket.onerror = (e) => {
                // writeToScreen(`<span class="error">ERROR:</span> ${e.data}`);
                writeToScreen("<span class='error'>ERROR: No existe conección con el servidor</span>");
            };

            function doSend(message) {
                //writeToScreen(`SENT: ${message}`);
                websocket.send(message);
            }

            function writeToScreen(message) {
                $("#salida").append("<p>" + message + "</p>");
            }

            function onClickButton() {
                var text = "Registro/" + $("#Text1").val();
                text && doSend(text);
                $(location).attr('href', "inicio.aspx");
                //$("#Text1").val("");
                //$("#Text1").focus();
            }

            function onClickButton1() {
                websocket.close();
                $(location).attr('href', "JuegoMultiUsuario.aspx");
                
            }
            function onClickButton2() {
                websocket.close();
                $(location).attr('href', "local.aspx");

            }
            
        });
        
    </script>
</body>

</html>