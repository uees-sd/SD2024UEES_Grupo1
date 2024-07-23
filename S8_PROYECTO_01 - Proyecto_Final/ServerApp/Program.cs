using System;
using System.Collections.Generic;
using System.Net;
using System.Net.Sockets;
using System.Text;
using System.Text.RegularExpressions;
using System.Threading;
using System.Linq;
using DataAcces;
using System.Configuration;

namespace ServerApp
{
    class Program
    {
        private static List<Socket> clients = new List<Socket>();
        private static TcpListener tcpListener = new TcpListener(
            IPAddress.Parse("10.53.12.141"),
            8080
        );
        private static int contador = 1;
        static void Main(string[] args)
        {
            tcpListener.Start();
            while (true)
            {
                Socket client = tcpListener.AcceptSocket();
                if (client.Connected)
                {
                    clients.Add(client);
                    Thread nuevoHilo = new Thread(() => Listeners(client));
                    nuevoHilo.Start();
                }
            }

        }
        private static void Listeners(Socket client)
        {
            Console.WriteLine("Client:" + client.RemoteEndPoint + " now connected to server.");
            NetworkStream stream = new NetworkStream(client);
            
            while (true)
            {
                while (!stream.DataAvailable) ;
                while (client.Available < 3) ; // match against "get"

                byte[] bytes = new byte[client.Available];
                stream.Read(bytes, 0, bytes.Length);
                string s = Encoding.UTF8.GetString(bytes);

                if (Regex.IsMatch(s, "^GET", RegexOptions.IgnoreCase))
                {
                    validaUsuario(client.RemoteEndPoint.ToString().Remove(client.RemoteEndPoint.ToString().IndexOf(":")),"");
                    Console.WriteLine("=====Handshaking from client=====\n{0}", s);
                    
                    // 1. Obtain the value of the "Sec-WebSocket-Key" request header without any leading or trailing whitespace
                    // 2. Concatenate it with "258EAFA5-E914-47DA-95CA-C5AB0DC85B11" (a special GUID specified by RFC 6455)
                    // 3. Compute SHA-1 and Base64 hash of the new value
                    // 4. Write the hash back as the value of "Sec-WebSocket-Accept" response header in an HTTP response
                    string swk = Regex.Match(s, "Sec-WebSocket-Key: (.*)").Groups[1].Value.Trim();
                    string swka = swk + "258EAFA5-E914-47DA-95CA-C5AB0DC85B11";
                    byte[] swkaSha1 = System.Security.Cryptography.SHA1.Create().ComputeHash(Encoding.UTF8.GetBytes(swka));
                    string swkaSha1Base64 = Convert.ToBase64String(swkaSha1);

                    // HTTP/1.1 defines the sequence CR LF as the end-of-line marker
                    byte[] response = Encoding.UTF8.GetBytes(
                        "HTTP/1.1 101 Switching Protocols\r\n" +
                        "Connection: Upgrade\r\n" +
                        "Upgrade: websocket\r\n" +
                        "Sec-WebSocket-Accept: " + swkaSha1Base64 + "\r\n\r\n");
                   
                    stream.Write(response, 0, response.Length);
                }
                else
                {
                    ///client.Send. Esta instrucción se utiliza para enviar mensajes al cliente, el mensaje siempre debe ir encriptado
                    /////Para encriptar utilizamos la instrucción EncodeMessageToSend
                    /// Para desencriptar el mensaje que envió el cliente utilizamos la instrucción DecodeMessage 
                    try
                    {
                        var text = DecodeMessage(bytes);
                        if (text.Contains("Reiniciar"))
                        {
                            ReiniciaJuego(client.RemoteEndPoint.ToString().Remove(client.RemoteEndPoint.ToString().IndexOf(":")));
                            
                            return;
                        }

                        //Para el registro del cliente, para registrar el alias del cliente
                        if (text.Contains("Registro"))
                        {
                            string[] words = text.Split('/');
                            string sendMessage3 = validaUsuario(client.RemoteEndPoint.ToString().Remove(client.RemoteEndPoint.ToString().IndexOf(":")), words[1]);
                            //Envio el mensaje al cliente, en este caso se retorna el alias que ya se guardo en la BDD
                            client.Send(EncodeMessageToSend(sendMessage3));
                        }
                        //Para los juegos local y multijugador
                        else
                        {
                            //Para el juego local
                            if (text.Contains("Local"))
                            {
                                //Separo la palabra clave local con la respuesta enviada por el usuario
                                //Por ejemplo, en el texto el cliente me envia "Local/2*2=4"
                                string[] words = text.Split('/');
                                MSScriptControl.ScriptControl SC = new MSScriptControl.ScriptControl();
                                SC.Language = "vbscript";
                                //Evaluo la respuesta enviada por el cliente
                                //Eval(2*2=4) esto puede ser true o false
                                var result = SC.Eval(words[1]);
                                //Si la respuesta es correcta
                                if (result == true)
                                {
                                    client.Send(EncodeMessageToSend(guardaPregunta(client.RemoteEndPoint.ToString().Remove(client.RemoteEndPoint.ToString().IndexOf(":")))));
                                    contador = contador + 1;
                                }
                                //Si la respuesta es incorrecta
                                else
                                {
                                    //Envio al cliente un mensaje de error
                                    client.Send(EncodeMessageToSend("Error: Perdiste"));
                                }

                            }
                            ///Para juego con varios clientes
                            ///El juego es multiplicar dos numeros
                            else
                            {
                                string[] words = text.Split('/');
                                MSScriptControl.ScriptControl SC = new MSScriptControl.ScriptControl();
                                SC.Language = "vbscript";
                                //Evaluo la respuesta enviada por el cliente que estoy evaluando
                                //Eval(2*2=4) esto puede ser true o false
                                var result = SC.Eval(words[1]);
                                //Console.WriteLine("{0}", text);
                                ///Verifico cuantos clientes estan registrados diferentes al cliente que estoy evaluano y los guardo
                                var otherClients = clients.Where(
                                        c => c.RemoteEndPoint.ToString().Remove(c.RemoteEndPoint.ToString().IndexOf(":")) != client.RemoteEndPoint.ToString().Remove(client.RemoteEndPoint.ToString().IndexOf(":"))
                                    ).ToList();

                                //var otherClients = clients.Where(
                                //       c => c.RemoteEndPoint != client.RemoteEndPoint
                                //   ).ToList();
                                ///Obtengo el endpoint del cliente que estoy evaluando
                                var myClient = clients.Where(
                                       c => c.RemoteEndPoint == client.RemoteEndPoint
                                   ).First();
                                ///Si solo esta el cliente que estoy evaluando no puede iniciar el juego
                                if (otherClients.Count == 0)
                                {
                                    var sendMessage3 = EncodeMessageToSend("Espera , no hay mas jugadores");
                                    myClient.Send(sendMessage3);
                                }
                                /// Si ya existe un cliente conectado diferente al cliente que estoy evaluando
                                /// puede iniciar el juego
                                else
                                {
                                    if (otherClients.Count > 0)
                                    {
                                        ///Recorro el arreglo de todos los clientes conectados
                                        foreach (var cli in otherClients)
                                        {
                                            ///Si la respuesta enviada por el cliente que estoy evaluando es correcta
                                            ///Envío un mensaje a todos los clientes que no sean el que estoy evaluando
                                            ///Envio el endpoint del cliente que gano, es decir el cliente que estoy evaluando
                                            if (result == true)
                                            {
                                                var sendMessage1 = EncodeMessageToSend("-Gano -" + words[0]);
                                                cli.Send(sendMessage1);
                                            }
                                            //else { 
                                            //  var sendMessage2 = EncodeMessageToSend(text);
                                            //  cli.Send(sendMessage2);
                                            //}
                                        }
                                    }
                                    ///Si la respuesta es correcta
                                    ///Envío un mensaje solo al cliente que estoy evaluand
                                    if (result == true)
                                    {
                                        var sendMessage3 = EncodeMessageToSend("Ganaste");
                                        myClient.Send(sendMessage3);
                                    }
                                    ///Si la respuesta es incorrecta
                                    ///Envío un mensaje solo al cliente que estoy evaluand
                                    else
                                    {
                                        var sendMessage3 = EncodeMessageToSend("Perdiste");
                                        myClient.Send(sendMessage3);
                                    }
                                }
                            }
                            
                        }
                        
                       // Console.WriteLine();

                    }
                    catch (Exception e)
                    {

                      //  Console.WriteLine(e.ToString()); ;
                    }                  
                    
                }
            }
        }

        private static string DecodeMessage(byte[] bytes)
        {
            var secondByte = bytes[1];
            var dataLength = secondByte & 127;
            var indexFirstMask = 2;
            if (dataLength == 126)
                indexFirstMask = 4;
            else if (dataLength == 127)
                indexFirstMask = 10;

            var keys = bytes.Skip(indexFirstMask).Take(4);
            var indexFirstDataByte = indexFirstMask + 4;

            var decoded = new byte[bytes.Length - indexFirstDataByte];
            for (int i = indexFirstDataByte, j = 0; i < bytes.Length; i++, j++)
            {
                decoded[j] = (byte)(bytes[i] ^ keys.ElementAt(j % 4));
            }

            return Encoding.UTF8.GetString(decoded, 0, decoded.Length);
        }

        private static byte[] EncodeMessageToSend(string message)
        {
            byte[] response;
            byte[] bytesRaw = Encoding.UTF8.GetBytes(message);
            byte[] frame = new byte[10];

            var indexStartRawData = -1;
            var length = bytesRaw.Length;

            frame[0] = (byte)129;
            if (length <= 125)
            {
                frame[1] = (byte)length;
                indexStartRawData = 2;
            }
            else if (length >= 126 && length <= 65535)
            {
                frame[1] = (byte)126;
                frame[2] = (byte)((length >> 8) & 255);
                frame[3] = (byte)(length & 255);
                indexStartRawData = 4;
            }
            else
            {
                frame[1] = (byte)127;
                frame[2] = (byte)((length >> 56) & 255);
                frame[3] = (byte)((length >> 48) & 255);
                frame[4] = (byte)((length >> 40) & 255);
                frame[5] = (byte)((length >> 32) & 255);
                frame[6] = (byte)((length >> 24) & 255);
                frame[7] = (byte)((length >> 16) & 255);
                frame[8] = (byte)((length >> 8) & 255);
                frame[9] = (byte)(length & 255);

                indexStartRawData = 10;
            }

            response = new byte[indexStartRawData + length];

            int i, reponseIdx = 0;

            //Add the frame bytes to the reponse
            for (i = 0; i < indexStartRawData; i++)
            {
                response[reponseIdx] = frame[i];
                reponseIdx++;
            }

            //Add the data bytes to the response
            for (i = 0; i < length; i++)
            {
                response[reponseIdx] = bytesRaw[i];
                reponseIdx++;
            }

            return response;
        }

        private static string validaUsuario(string dirIp, string alias) {
            string retorno = "";
            try
            {
               //String de conexion a la BDD 
                var conexion = "Data Source=DESKTOP-Q1U4FGB;Initial Catalog=Juego;User ID=sa;Password=sa.1";
                DBManager.inicializa(conexion);
                //Verifico si existe registrada la IP del cliente en la tabla TMP_Usuario
                var sql = string.Format("select id from TMP_Usuario where ip = '{0}'", dirIp);  
                var a =  DBManager.ejecutaEscalar(sql,DBManager.tiposRetornoEscalar.texto);
                //Si no existe el cliente, guardo la ip del cliente 
                if (a.ToString() == "")
                {
                    // guardo ip en la bdd
                    sql = string.Format("insert into dbo.TMP_Usuario values ('{0}','{1}')", dirIp, "");
                    DBManager.ejecuta(sql);
                }
                //Si ya existe el cliente (Se registro su ip en la tabla TMP_Usuario )
                else
                { 
                    //Valido si el cliente tiene un Alias registrado
                    sql = string.Format("select nombre from TMP_Usuario where ip = '{0}'", dirIp);
                    var b = DBManager.ejecutaEscalar(sql, DBManager.tiposRetornoEscalar.texto);
                    //Si el cliente no tiene un alias registrado y no estoy haciendo una consulta (alias =0)
                    // Actualizo el alias con el valor enviado por el cliente
                    if (b.ToString() == "" && alias != "0")
                    {
                        sql = string.Format("update dbo.TMP_Usuario set nombre = '{0}' where ip = '{1}'", alias, dirIp);
                        DBManager.ejecuta(sql);
                    }
                    //Si el cliente ya tiene un alias registrado
                    else
                    {
                        //Para el Juego local,cargo la ultima pregunta que el cliente ya respondio en el juego local
                        if (alias == "1")
                        {
                            retorno = cargaPregunta(dirIp);
                        }
                        //Retorno el alias del cliente
                        else
                        {
                            retorno = "Cliente " + b.ToString();
                        }
                        
                    }
                    
                }
            }
            catch (Exception ex)
            {

                DBManager.closeConnection();
            }
            ///Cierra la conexión a la BDD
            DBManager.closeConnection();
            return retorno;
        }

        private static string cargaPregunta(string usuario)
        {
            string retorno = "";
            try
            {
                ///String de conexión a la BDD
                var conexion = "Data Source=DESKTOP-Q1U4FGB;Initial Catalog=Juego;User ID=sa;Password=sa.1";
                DBManager.inicializa(conexion);
                ///Cargo la ultima pregunta contestada por el cliente
                var sql = string.Format("select max(idpregunta) from PreguntasXUsuarios where idusuario = '{0}'", usuario);
                var a = DBManager.ejecutaEscalar(sql, DBManager.tiposRetornoEscalar.texto);
                ///Si no existe ninguna pregunta contestada
                ///Cargo la primera pregunta de la lista de preguntas (Tabla Preguntas)
                if (a.ToString() == "")
                {
                    sql = string.Format("select pregunta from Preguntas where id = {0}", 1);
                    a = DBManager.ejecutaEscalar(sql, DBManager.tiposRetornoEscalar.texto);
                    
                }
                ///Si ya conteste al menos una pregunta
                /// Cargo la pregunta siguinte de la lista de preguntas
                else
                {
                    int nueva = Convert.ToInt32(a.ToString());
                    nueva = nueva + 1;
                    sql = string.Format("select pregunta from Preguntas where id = {0}", nueva);
                    a = DBManager.ejecutaEscalar(sql, DBManager.tiposRetornoEscalar.texto);
                }
                retorno = a.ToString();
                
            }
            catch (Exception)
            {

                DBManager.closeConnection();
            }

            ///Cierra la conexión a la BDD
            DBManager.closeConnection();
            return retorno;
        }

        private static string guardaPregunta(string usuario)
        {
            string retorno = "";
            try
            {
                var conexion = "Data Source=DESKTOP-Q1U4FGB;Initial Catalog=Juego;User ID=sa;Password=sa.1";
                DBManager.inicializa(conexion);
                ///Selecciono la ultima pregunta contestada por el cliente
                var sql = string.Format("select max(idpregunta) from PreguntasXUsuarios where idusuario = '{0}'", usuario);
                var a = DBManager.ejecutaEscalar(sql, DBManager.tiposRetornoEscalar.texto);
                /// Cuando el cliente no a contestado ninguna pregunta
                ///Si no contesto ninguna pregunta y hay que recordar que a esta función ingresa el sistema cuando se evaluo correctamnete
                ///la pregunta. Guardo la primetra pregunta en la tabla PreguntasXUsuarios
                ///y retorno la segunda pregunta
                if (a.ToString() == "")
                {
                    sql = string.Format("insert into PreguntasXUsuarios values ({0},'{1}')", 1, usuario);
                    DBManager.ejecuta(sql);
                    sql = string.Format("select pregunta from Preguntas where id = {0}", 2);
                    a = DBManager.ejecutaEscalar(sql, DBManager.tiposRetornoEscalar.texto);
                }
                ///Para cuando ya existe al menos una pregunta contestada
                else
                {
                    ///Ultima pregunta contestada por el cliente
                    int nueva = Convert.ToInt32(a.ToString());
                    ///La que estoy evaluando por defecto va hacer la ultima pregunta que el cliente contesto bien +1
                    nueva = nueva + 1;
                    /// Guardo como contestada la pregunta que estoy evaluando
                    sql = string.Format("insert into PreguntasXUsuarios values ({0},'{1}')", nueva, usuario);
                    DBManager.ejecuta(sql);
                    ///Retorno la proxima pregunta
                    nueva = nueva + 1;
                    sql = string.Format("select pregunta from Preguntas where id = {0}", nueva);
                    a = DBManager.ejecutaEscalar(sql, DBManager.tiposRetornoEscalar.texto);
                }
                retorno = a.ToString();

            }
            catch (Exception)
            {

                DBManager.closeConnection();
            }
            ///Cierra la conexión a la BDD
            DBManager.closeConnection();
            return retorno;
        }

        private static void ReiniciaJuego(string usuario)
        {
            try
            {
                var conexion = "Data Source=DESKTOP-Q1U4FGB;Initial Catalog=Juego;User ID=sa;Password=sa.1";
                DBManager.inicializa(conexion);
                ///Selecciono la ultima pregunta contestada por el cliente
                var sql = string.Format("delete from PreguntasXUsuarios where idusuario = '{0}'", usuario);
                DBManager.ejecuta(sql);
            }
            catch (Exception)
            {

                DBManager.closeConnection();
            }
            DBManager.closeConnection();
        }
    }
    }


