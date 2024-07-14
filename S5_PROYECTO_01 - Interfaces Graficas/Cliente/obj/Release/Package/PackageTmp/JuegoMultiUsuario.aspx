<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="JuegoMultiUsuario.aspx.cs" Inherits="Cliente.JuegoMultiUsuario" %>

<!DOCTYPE html>

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title></title>
     <link href="Content/bootstrap.min.css" type="text/css" rel="stylesheet" />
    <script src="scripts/jquery-3.6.1.min.js" type="text/javascript"></script>
    <script src="scripts/bootstrap.js"></script>
</head>
<body>
    <div class="card">
        <div class="card-header">
            <h2>Juego-En línea</h2>
        </div>
        <div class="card-body">
            <input id="Text1" disabled="disabled"  style="font-family: 'Arial Black'; font-size: large; width: 120px;" type="text" /> X
        <input id="Text2" disabled="disabled"  style="font-family: 'Arial Black'; font-size: large; width: 120px;" type="text" /> =
        <input id="Text3" style="font-family: 'Arial Black'; font-size: large; width: 120px;" type="text" />&nbsp;&nbsp;
        <input id="boton" class="btn btn-primary" type="button" value="Enviar" />
            <p>
                &nbsp;<div id="salida"></div>
                <input id="Button2" class="btn btn-primary" type="button" value="Salir" />
            </p>
        </div>
    </div>
     <div class="modal fade" id="myModal" role="dialog">
    <div class="modal-dialog">
    
      <!-- Modal content-->
      <div class="modal-content">
        <div class="modal-header">
          
          <h4 class="modal-title">Resultados</h4>
        </div>
        <div class="modal-body">
           <img alt="" src="images/Correcto.png" class="rounded mx-auto d-block"/>
          
        </div>
        <div class="modal-footer">
          <button type="button" id="btnCerrar" class="btn btn-default" data-dismiss="modal">Close</button>
        </div>
      </div>
      
    </div>
  </div>

     <div class="modal fade" id="myModal1" role="dialog">
    <div class="modal-dialog">
    
      <!-- Modal content-->
      <div class="modal-content">
        <div class="modal-header">
          
          <h4 class="modal-title">Resultados</h4>
        </div>
        <div class="modal-body">
           <img alt="" src="images/Error.png" class="rounded mx-auto d-block"/>
          
        </div>
        <div class="modal-footer">
          <button type="button" id="btnCerrar1" class="btn btn-default" data-dismiss="modal">Close</button>
        </div>
      </div>
      
    </div>
  </div>

     <div class="modal fade" id="myModal2" role="dialog">
    <div class="modal-dialog">
    
      <!-- Modal content-->
      <div class="modal-content">
        <div class="modal-header">
          
          <h4 class="modal-title">Resultados</h4>
        </div>
        <div class="modal-body">
          <h5>Persite, respode mas rápido</h5>
          <div id ="Mensaje"></div>
        </div>
        <div class="modal-footer">
          <button type="button" id="btnCerrar2" class="btn btn-default" data-dismiss="modal">Close</button>
        </div>
      </div>
      
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
            var number = 1 + Math.floor(Math.random() * 66);
            var number1 = 1 + Math.floor(Math.random() * 55);
            var cliente="";
            $("#Text1").val(number);
            $("#Text2").val(number1);

            $(document).on("click", "#boton", onClickButton);
            $(document).on("click", "#Button2", onClickButton1);
            $(document).on("click", "#btnCerrar", onClickCerrar);
            $(document).on("click", "#btnCerrar1", onClickCerrar1);
            $(document).on("click", "#btnCerrar2", onClickCerrar2);

            websocket.onopen = (e) => {
                writeToScreen("CONNECTED");
               doSend("Registro/0");
            };

            websocket.onclose = (e) => {
                writeToScreen("DISCONNECTED");
            };

            websocket.onmessage = (e) => {
                if (e.data.indexOf("Ganaste") >= 0) {
                    $("#myModal").modal('show');
                }
                if (e.data.indexOf("Perdiste") >= 0) {
                    $("#myModal1").modal('show');
                }
                if (e.data.indexOf("Gano") >= 0) {
                    $("#myModal2").modal('show');
                    $("#Mensaje").append("<p>" + e.data + "</p>");
                   
                    
                }
                if (e.data.indexOf("Usuario") >= 0)
                {
                    if (e.data.indexOf("Gano") >= 0) {

                    } else {
                        cliente = e.data;
                        writeToScreen("<span>" + e.data + "</span>");
                    }
                    
                }
               
            };

            websocket.onerror = (e) => {
                writeToScreen(`<span class="error">ERROR:</span> ${e.data}`);
            };

            function doSend(message) {
                //writeToScreen(`SENT: ${message}`);
                websocket.send(message);
            }

            function writeToScreen(message) {
                $("#salida").append("<p>" + message + "</p>");
            }

            function onClickButton() {
                var text =cliente + '/' + $("#Text1").val() + '*' + $("#Text2").val() + '=' + $("#Text3").val();
                text && doSend(text);
                //$("#Text1").val("");
                //$("#Text1").focus();
            }
            function onClickButton1() {
                websocket.close();
                $(location).attr('href', "Inicio.aspx");
            }
            function onClickCerrar() {
                $("#myModal").modal('hide');
                var number = 1 + Math.floor(Math.random() * 80);
                var number1 = 1 + Math.floor(Math.random() * 92);
                $("#Text1").val(number);
                $("#Text2").val(number1);
                $("#Text3").val("");
            }
            function onClickCerrar1() {
                $("#myModal1").modal('hide');
                var number = 1 + Math.floor(Math.random() * 26);
                var number1 = 1 + Math.floor(Math.random() * 38);
                $("#Text1").val(number);
                $("#Text2").val(number1);
                $("#Text3").val("");
            }
            function onClickCerrar2() {
                $("#myModal2").modal('hide');
                var number = 1 + Math.floor(Math.random() * 40);
                var number1 = 1 + Math.floor(Math.random() * 87);
                $("#Text1").val(number);
                $("#Text2").val(number1);
                $("#Text3").val("");
            }
            
        });
        
    </script>
</body>

</html>

