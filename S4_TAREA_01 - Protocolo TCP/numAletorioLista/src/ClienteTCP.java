
/*
 Centro de Estudios           : UEES
 Materia                      : Sistemas Distribuidos
 Catedrático                  : Ing. Guillermo Pizarro
 Autor                        : Oscar Izurieta Bedón
                                Sebastián Paredes Echeverría
                                Diana Salazar Garcés
                                Ronald Rodríguez Castro
 Fecha                        : 05/07/2024
 Tema                         : PROTOCOLO TCP
 
 Actividad   : 
    • Implementar un servidor que acepte varias conexiones mediante TCP.
    • En el servidor se maneje un recurso compartido entre los nodos clientes que se conecten al servidor.
    • El recurso compartido será una lista, que será llenada con un dato numérico aleatorio proporcionado por el cliente y luego el servidor retornará la lista con el dato proporcionado por el cliente;
      es decir, la lista al menos tendrá el dato del cliente recién conectado o con otros datos numéricos aleatorios proporcionados por otros clientes.
*/
import java.io.*;
import java.net.*;

public class ClienteTCP {
    private static final String SERVER_ADDRESS = "localhost"; // Servidor de conexión
    private static final int PORT = 8080; // Puerto de conexión

    public static void main(String[] args) {
        try (Socket socket = new Socket(SERVER_ADDRESS, PORT);
                BufferedReader in = new BufferedReader(new InputStreamReader(socket.getInputStream()));
                PrintWriter out = new PrintWriter(socket.getOutputStream(), true);
                BufferedReader stdIn = new BufferedReader(new InputStreamReader(System.in));) {
            System.out.println(in.readLine()); // Leer mensaje del servidor
            String userInput = stdIn.readLine(); // Leer entrada del usuario
            out.println(userInput); // Enviar entrada al servidor

            String serverResponse = in.readLine(); // Leer respuesta del servidor
            System.out.println(serverResponse); // Mostrar respuesta del servidor
        } catch (IOException e) {
            e.printStackTrace();
        }
    }
}
