// src/std/net.cl
// CARTAN Standard Library: Networking & Socket Abstractions Module

extern fn cartan_socket_create() -> float;
extern fn cartan_socket_connect(sock: float, host: string, port: float) -> float;
extern fn cartan_socket_send(sock: float, data: string) -> float;
extern fn cartan_socket_recv(sock: float) -> string;
extern fn cartan_socket_close(sock: float) -> float;

fn net_socket() -> float {
    return cartan_socket_create();
}

fn net_connect(sock: float, host: string, port: float) -> float {
    return cartan_socket_connect(sock, host, port);
}

fn net_send(sock: float, data: string) -> float {
    return cartan_socket_send(sock, data);
}

fn net_recv(sock: float) -> string {
    return cartan_socket_recv(sock);
}

fn net_close(sock: float) -> float {
    return cartan_socket_close(sock);
}
