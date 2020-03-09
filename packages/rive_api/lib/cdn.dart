class RiveCDN {
  final String base;
  final String params;

  RiveCDN(Map<String, dynamic> data)
      : base = data["base"]?.toString(),
        params = data["params"]?.toString();
}
