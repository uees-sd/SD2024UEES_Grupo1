
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
import java.util.*;

public class ServidorTCP {
    private static final int PORT = 8080;
    private static List<Integer> sharedList = Collections.synchronizedList(new ArrayList<>());

    public static void main(String[] args) {
        try (ServerSocket serverSocket = new ServerSocket(PORT)) {
            System.out.println("Servidor escuchando en el puerto " + PORT);

            while (true) {
                Socket clientSocket = serverSocket.accept();
                new ClientHandler(clientSocket).start();
            }
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    private static class ClientHandler extends Thread {
        private Socket clientSocket;

        public ClientHandler(Socket socket) {
            this.clientSocket = socket;
        }

        @Override
        public void run() {
            try (
                    BufferedReader in = new BufferedReader(new InputStreamReader(clientSocket.getInputStream()));
                    PrintWriter out = new PrintWriter(clientSocket.getOutputStream(), true);) {
                out.println("Ingrese un número: "); // Solicita número
                int clientData = Integer.parseInt(in.readLine()); // Lee número

                synchronized (sharedList) {
                    sharedList.add(clientData);
                }

                out.println("Lista actualizada: " + sharedList); // Devuelve lista actualizada
            } catch (IOException e) {
                e.printStackTrace();
            } finally {
                try {
                    clientSocket.close();
                } catch (IOException e) {
                    e.printStackTrace();
                }
            }
        }
    }
}
