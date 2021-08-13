class ServerList {
  String name;
  String ip;
  String password;

  ServerList(this.name, this.ip, this.password);

  factory ServerList.fromJson(Map<String, String> json) => ServerList(
        json['name'],
        json['ip'],
        json['password']
      );

  Map<String, String> toJson() => {
        'name': name,
        'ip': ip,
        'password': password
      };
}
