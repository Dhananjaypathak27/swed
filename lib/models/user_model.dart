/// role : "user"
/// content : "Hi I am Dhananjay pathak"

class UserModel {
  String? role;
  String? content;

  UserModel({this.role, this.content});

  UserModel.fromJson(Map<String, dynamic> json) {
    role = json['role'];
    content = json['content'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['role'] = role;
    data['content'] = content;
    return data;
  }
}