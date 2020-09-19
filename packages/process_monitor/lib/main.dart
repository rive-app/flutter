import 'dart:async';
import 'dart:convert';
import 'dart:io';

Future<void> main(List<String> args) async {
  String executable = args.first;

  print('will monitor: $executable ${args.skip(1).toList()}');
  var process = await Process.start(executable, args.skip(1).toList(),
      mode: ProcessStartMode.normal);

  process.stderr.listen((data) {
    print('monitor error: ${utf8.decode(data)}');
  });
  process.stdout.transform(utf8.decoder).listen((data) {
    print('monitor out: $data');
  });

  var timer = Timer.periodic(const Duration(seconds: 3), (timer) {
    printStats(process.pid);
  });
  var exitCode = await process.exitCode;
  timer.cancel();

  print('process $executable exited with $exitCode');
}

Future<void> printStats(int processId) async {
  var cpuMonitor = await Process.start(
      'process_monitor/stats.sh', [processId.toString()],
      mode: ProcessStartMode.normal);
  cpuMonitor.stdout.transform(utf8.decoder).listen(print);
  await cpuMonitor.exitCode;
}
