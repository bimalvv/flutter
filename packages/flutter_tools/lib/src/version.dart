// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'base/process.dart';
import 'cache.dart';

final Set<String> kKnownBranchNames = new Set<String>.from(<String>[
  'master',
  'alpha',
  'hackathon',
  'codelab',
  'beta'
]);

class FlutterVersion {
  FlutterVersion(this.flutterRoot) {
    _channel = _runGit('git rev-parse --abbrev-ref --symbolic @{u}');

    int slash = _channel.indexOf('/');
    if (slash != -1) {
      String remote = _channel.substring(0, slash);
      _repositoryUrl = _runGit('git ls-remote --get-url $remote');
      _channel = _channel.substring(slash + 1);
    } else if (_channel.isEmpty) {
      _channel = 'unknown';
    }

    _frameworkRevision = _runGit('git log -n 1 --pretty=format:%H');
    _frameworkAge = _runGit('git log -n 1 --pretty=format:%ar');
  }

  final String flutterRoot;

  String _repositoryUrl;
  String get repositoryUrl => _repositoryUrl;

  String _channel;
  /// `master`, `alpha`, `hackathon`, ...
  String get channel => _channel;

  String _frameworkRevision;
  String get frameworkRevision => _frameworkRevision;
  String get frameworkRevisionShort => _shortGitRevision(frameworkRevision);

  String _frameworkAge;
  String get frameworkAge => _frameworkAge;

  String get dartSdkVersion => Cache.dartSdkVersion.split(' ')[0];

  String get engineRevision => Cache.engineRevision;
  String get engineRevisionShort => _shortGitRevision(engineRevision);

  String _runGit(String command) => runSync(command.split(' '), workingDirectory: flutterRoot);

  @override
  String toString() {
    String from = 'Flutter on channel $channel (from ${repositoryUrl == null ? 'unknown source' : repositoryUrl})';
    String flutterText = 'Framework revision $frameworkRevisionShort ($frameworkAge); engine revision $engineRevisionShort';
    String dartSdkText = 'Flutter tools using Dart version $dartSdkVersion';
    String frameworkCommit = 'Last commit on framework: $frameworkCommitDate';

    return '$from\n$flutterText\n$frameworkCommit\n$dartSdkText';
  }

  /// A date String describing the last framework commit.
  static String get frameworkCommitDate {
    return _runSync('git', <String>['log', '-n', '1', '--pretty=format:%ad', '--date=format:%Y-%m-%d %H:%M:%S'], Cache.flutterRoot);
  }

  static FlutterVersion getVersion([String flutterRoot]) {
    return new FlutterVersion(flutterRoot != null ? flutterRoot : Cache.flutterRoot);
  }

  /// Return a short string for the version (`alpha/a76bc8e22b`).
  static String getVersionString({ bool whitelistBranchName: false }) {
    final String cwd = Cache.flutterRoot;

    String commit = _shortGitRevision(_runSync('git', <String>['rev-parse', 'HEAD'], cwd));
    commit = commit.isEmpty ? 'unknown' : commit;

    String branch = _runSync('git', <String>['rev-parse', '--abbrev-ref', 'HEAD'], cwd);
    branch = branch == 'HEAD' ? 'master' : branch;

    if (whitelistBranchName || branch.isEmpty) {
      // Only return the branch names we know about; arbitrary branch names might contain PII.
      if (!kKnownBranchNames.contains(branch))
        branch = 'dev';
    }

    return '$branch/$commit';
  }
}

String _runSync(String executable, List<String> arguments, String cwd) {
  ProcessResult results = Process.runSync(executable, arguments, workingDirectory: cwd);
  return results.exitCode == 0 ? results.stdout.trim() : '';
}

String _shortGitRevision(String revision) {
  return revision.length > 10 ? revision.substring(0, 10) : revision;
}
