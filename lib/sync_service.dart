import 'api_client.dart';
import 'db_helper.dart';

class SyncService {
  static const _keyLastSync = 'last_sync_at';

  static Future<int> getLastSyncAt() async {
    final v = await DbHelper.getSyncInfo(_keyLastSync);
    return int.tryParse(v ?? '') ?? 0;
  }

  /// 执行一次同步：先推后拉。since 使用服务端时间，避免客户端时钟偏差。
  static Future<SyncResult> sync() async {
    int pushed = 0;
    int pulled = 0;

    try {
      final lastSync = await getLastSyncAt();
      int serverTime = 0;

      // 1. 推送本地变更，获取服务端时间
      final localChanges = await DbHelper.getWordsSince(lastSync);
      if (localChanges.isNotEmpty) {
        serverTime = await ApiClient.pushWords(localChanges);
        pushed = localChanges.length;
      }

      // 2. 拉取远端变更（用服务端时间作 since）
      final (remoteWords, pullTime) = await ApiClient.pullWords(lastSync);
      if (pullTime > 0) serverTime = pullTime;
      for (final rw in remoteWords) {
        final local = await DbHelper.getWordById(rw.id);
        if (local == null || rw.updatedAt > local.updatedAt) {
          await DbHelper.insertWord(rw);
          pulled++;
        }
      }

      // 3. 用服务端时间记录本次同步
      if (serverTime > 0) {
        await DbHelper.setSyncInfo(_keyLastSync, serverTime.toString());
      }

      return SyncResult(pushed: pushed, pulled: pulled);
    } catch (e) {
      return SyncResult(pushed: 0, pulled: 0, error: e.toString());
    }
  }
}

class SyncResult {
  final int pushed;
  final int pulled;
  final String? error;

  SyncResult({required this.pushed, required this.pulled, this.error});

  bool get ok => error == null;
}
