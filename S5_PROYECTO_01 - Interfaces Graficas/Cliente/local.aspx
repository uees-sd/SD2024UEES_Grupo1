<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="local.aspx.cs" Inherits="Cliente.local" %>

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
            <h2>Juego- Local</h2>
        </div>
        <div class="card-body">
            &nbsp;&nbsp; &nbsp;&nbsp;&nbsp;
            <p  >
                <input id="Text1"  disabled="disabled" style="font-family: 'Arial Black'; font-size: large; width: 120px;"  type="text"/> = <input id="Text3" style="font-family: 'Arial Black'; font-size: large; width: 120px;" type="text" />&nbsp;&nbsp;&nbsp; <input id="Button1" class="btn btn-primary" type="button" value="Enviar" />
                <div id="salida"></div>
            <input id="Button2" class="btn btn-primary" type="button" value="Salir" />
                 <input id="Button3" class="btn btn-primary" type="button" value="Reiniciar" />
            </p>
        </div>
    </div>
    <div class="modal fade" id="myModal" role="dialog">
    <div class="modal-dialog">
    
      <!-- Modal content-->
      <div class="modal-content">
        <div class="modal-header">
          
          <h4 class="modal-title">Tablas de Multiplicar</h4>
        </div>
        <div class="modal-body">
          <h5>Reglas</h5>
          <p>1. Responde correctamente las preguntas</p>
          <p>2. Si la respuesta es incorrecta no puedes avanzar a la siguiente pregunta</p>
          <p>3. El juego guarda automaticamente tu avance</p>
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
          
          <h4 class="modal-title">Tablas de Multiplicar</h4>
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
            $("#myModal").modal('show');
            $(document).on("click", "#Button1", onClickButton);
            $(document).on("click", "#Button2", onClickButton1);
            $(document).on("click", "#Button3", onClickButton2);
            $(document).on("click", "#btnCerrar", onClickCerrar);
            $(document).on("click", "#btnCerrar1", onClickCerrar1);
            
            websocket.onopen = (e) => {
                writeToScreen("CONNECTED");
                doSend("Registro/1");
            };

            websocket.onclose = (e) => {
                writeToScreen("DISCONNECTED");
            };

            websocket.onmessage = (e) => {
                if (e.data != "")
                {
                    if (e.data.indexOf("Error") >= 0) {
                        writeToScreen("<span>" + e.data + "</span>");
                        $("#myModal1").modal('show');

                    }
                    else {
                        $("#Text1").val(e.data);
                        $("#salida").find("span").remove();
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
                var text = "Local/" + $("#Text1").val() + '=' + $("#Text3").val();
                text && doSend(text);
                $("#Text3").val("");
                //$("#Text1").val("");
                //$("#Text1").focus();
            }
            function onClickButton1() {
                websocket.close();
                $(location).attr('href', "Inicio.aspx");
            }
            function onClickCerrar() {
                $("#myModal").modal('hide');
            }
            function onClickCerrar1() {
                $("#myModal1").modal('hide');
            }
            function onClickButton2() {
                var text = "Reiniciar";
                text && doSend(text);
                $(location).attr('href', "local.aspx");
            }
            
            
            
        });
        
    </script>
    
</body>

</html>
