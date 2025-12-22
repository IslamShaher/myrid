
import socket
import threading
import sys

def handle_client(client_socket, remote_host, remote_port):
    try:
        print(f"Connecting to remote {remote_host}:{remote_port}...")
        remote_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        remote_socket.settimeout(5.0)
        remote_socket.connect((remote_host, remote_port))
        remote_socket.settimeout(None) # Remove timeout for data transfer
        print(f"Connected to remote {remote_host}:{remote_port}")
    except Exception as e:
        print(f"Failed to connect to remote {remote_host}:{remote_port}: {e}")
        client_socket.close()
        return

    def forward(source, destination, name):
        try:
            while True:
                data = source.recv(4096)
                if len(data) == 0:
                    print(f"Connection {name} closed by source")
                    break
                print(f"Forwarding {len(data)} bytes via {name}")
                destination.send(data)
        except Exception as e:
            print(f"Forwarding error in {name}: {e}")
        finally:
            source.close()
            destination.close()

    threading.Thread(target=forward, args=(client_socket, remote_socket, "client->remote")).start()
    threading.Thread(target=forward, args=(remote_socket, client_socket, "remote->client")).start()

def main():
    if len(sys.argv) != 4:
        print("Usage: python forward.py <local_port> <remote_host> <remote_port>")
        sys.exit(1)

    local_port = int(sys.argv[1])
    remote_host = sys.argv[2]
    remote_port = int(sys.argv[3])

    server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server.bind(('0.0.0.0', local_port))
    server.listen(5)

    print(f"Listening on 0.0.0.0:{local_port} and forwarding to {remote_host}:{remote_port}")

    while True:
        client, addr = server.accept()
        print(f"Accepted connection from {addr}")
        threading.Thread(target=handle_client, args=(client, remote_host, remote_port)).start()

if __name__ == '__main__':
    main()
