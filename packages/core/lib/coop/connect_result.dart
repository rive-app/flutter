class ConnectResult {
  final ConnectState state;
  final String info;

  ConnectResult(this.state, {this.info});
}

enum ConnectState {
  connected,
  networkError,
  notAuthorized,
}
