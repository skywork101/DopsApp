package com.example.TCPsocket;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.Bean;
import org.springframework.integration.annotation.IntegrationComponentScan;
import org.springframework.integration.annotation.MessagingGateway;
import org.springframework.integration.channel.DirectChannel;
import org.springframework.messaging.MessageChannel;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.PrintWriter;
import java.net.ServerSocket;
import java.net.Socket;

@SpringBootApplication
@IntegrationComponentScan
public class TcPsocketApplication {

    public static void main(String[] args) {
        SpringApplication.run(TcPsocketApplication.class, args);
		MyServer myServer = new MyServer();
        myServer.start();
    }

    @Bean
    public MyServer myServer() {
        return new MyServer();
    }

    @MessagingGateway(defaultRequestChannel = "inputChannel")
    public interface MyGateway {
        void process(String message);
    }

    @Bean
    public MessageChannel inputChannel() {
        return new DirectChannel();
    }

    public static class MyServer {
    private ServerSocket serverSocket;

    public void start() {
        try {
            serverSocket = new ServerSocket(13313);
            System.out.println("Server started. Listening for connections...");

            while (true) {
                Socket clientSocket = serverSocket.accept();
                System.out.println("Client connected: " + clientSocket.getInetAddress().getHostAddress());

                Thread clientThread = new Thread(new ClientHandler(clientSocket));
                clientThread.start();
            }
        } catch (IOException e) {
            System.out.println("Server error: " + e.getMessage());
        } finally {
            stop();
        }
    }

    public void stop() {
        try {
            if (serverSocket != null) {
                serverSocket.close();
            }
            System.out.println("Server stopped.");
        } catch (IOException e) {
            System.out.println("Error while stopping server: " + e.getMessage());
        }
    }

    private static class ClientHandler implements Runnable {
        private Socket clientSocket;

        public ClientHandler(Socket clientSocket) {
            this.clientSocket = clientSocket;
        }

        @Override
        public void run() {
            PrintWriter out = null;
            BufferedReader in = null;

            try {
                out = new PrintWriter(clientSocket.getOutputStream(), true);
                in = new BufferedReader(new InputStreamReader(clientSocket.getInputStream()));

                String inputLine;
                while ((inputLine = in.readLine()) != null) {
                    System.out.println("Received message: " + inputLine);

					// Process the received message
					String response = processMessage(inputLine);

					// Send response back to the client
					out.println(response);
                }
            } catch (IOException e) {
                System.out.println("Error handling client: " + e.getMessage());
            } finally {
                try {
                    if (in != null) {
                        in.close();
                    }
                    if (out != null) {
                        out.close();
                    }
                    clientSocket.close();
                } catch (IOException e) {
                    System.out.println("Error closing client connection: " + e.getMessage());
                }
            }
        }
		private String processMessage(String message) {
			// Process the message and generate a response
			String response = "Processed: " + message;
			return response;
		}
    }
}
}






